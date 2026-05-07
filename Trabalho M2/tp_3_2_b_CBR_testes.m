%% TP 3.2.b - Testes do CBR
% Este script testa o metodo CBR com varias configuracoes:
% - imputacao Median vs MICE
% - dados originais vs normalizados
% - diferentes conjuntos de pesos
%
% Entrada:
%   ficheiros gerados pelo tp_3_1_tratamento_do_dataset
%
% Saida:
%   OUTPUT_3.2.b_CBR_TESTS/
%       Common/Resultados_CBR.xlsx
%       Common/plot_Resumo_Testes_CBR.png
%       Median/*.xlsx
%       MICE/*.xlsx

clc;
clear;
close all;

fprintf("\n======================================================\n");
fprintf(" TP 3.2.b - TESTES DO CBR\n");
fprintf("======================================================\n\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURACAO INICIAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

project_dir = fileparts(mfilename('fullpath'));
if project_dir == ""
    project_dir = pwd;
end
cd(project_dir);

addpath(fullfile(project_dir, "functions"));

retrieve         = @tp_func_retrieve;
get_file         = @tp_func_get_xlfile;
normalize_values = @tp_func_rescale;

fig_visibility = 'off';

% pasta de output deste script
output_folder = "OUTPUT_3.2.b_CBR_TESTS";

fprintf("[1/5] A localizar ficheiros gerados no tratamento 3.1...\n");

% Este ficheiro foi criado pelo script 3.1 em Common/
wildcard = "*_TRATAM*/Common/*_test_num.xlsx";
ds_file_path = get_file(wildcard);

fprintf("      Dataset de teste encontrado:\n");
fprintf("      %s\n", ds_file_path);

% Lemos o dataset de teste numerico para obter as colunas e para testar o CBR
tabCaseLib_T_base = readtable(ds_file_path);

% O setup_common precisa de tabCaseLib para identificar colunas
tabCaseLib = tabCaseLib_T_base;

tp_3_0_setup_common;

% Criar subpastas de output
ensure_folder(output_folder_path + "Common/");
ensure_folder(output_folder_path + "Median/");
ensure_folder(output_folder_path + "MICE/");

fprintf("      Pasta de output: %s\n", output_folder_path);
fprintf("      Total de casos de teste: %d\n", height(tabCaseLib_T_base));
fprintf("      Atributos usados: %d\n", numel(att_cols));
fprintf("      Target: %s\n", target_col);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURACOES A TESTAR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[2/5] A preparar configuracoes de teste...\n");

type_imput = ["Median", "MICE"];
type_data  = ["ORIG", "NORM"];

% Nomes dos conjuntos de pesos
wf_names = ["w", "w2", "1s", "soCat"];

% Valores dos pesos:
% w     -> pesos estimados
% w2    -> pesos ao quadrado
% 1s    -> todos os atributos com o mesmo peso
% soCat -> apenas atributos categoricos
wf_values = {
    [5,5,4,2,4,1,3,3,3,3,3,2,2,3], ...
    [25,25,16,4,16,1,9,9,9,9,9,4,4,9], ...
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1], ...
    [0,0,0,0,0,0,0,0,0,0,1,1,1,1]
};

fprintf("      Tipos de imputacao: %s\n", strjoin(type_imput, ", "));
fprintf("      Tipos de dados: %s\n", strjoin(type_data, ", "));
fprintf("      Conjuntos de pesos: %s\n", strjoin(wf_names, ", "));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TESTES CBR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[3/5] A executar testes CBR...\n");

results_lst = struct( ...
    'config', {}, ...
    'type_imput', {}, ...
    'type_data', {}, ...
    'weights', {}, ...
    'taxa_acerto', {}, ...
    'similaridade_media', {}, ...
    'similaridade_min', {}, ...
    'similaridade_max', {}, ...
    'similaridade_std', {} ...
);

inc = 0;

for t_imput = type_imput

    fprintf("\n------------------------------------------------------\n");
    fprintf(" Imputacao: %s\n", t_imput);
    fprintf("------------------------------------------------------\n");

    % Dataset de treino tratado, criado no script 3.1
    wildcard = "*_TRATAM*/" + t_imput + "/*_IMPUTED_ORIG_" + t_imput + ".xlsx";
    ds_train_path = get_file(wildcard);

    fprintf("      Dataset treino: %s\n", ds_train_path);

    tabCaseLib_base = readtable(ds_train_path);

    % Parametros de normalizacao criados no script 3.1
    wildcard = "*_TRATAM*/" + t_imput + "/*_NORM_PARAMS_" + t_imput + ".mat";
    params_file_path = get_file(wildcard);

    fprintf("      Parametros norm.: %s\n", params_file_path);

    load(params_file_path); % carrega dict_att_min e dict_att_max

    for t_data = type_data

        fprintf("\n      Tipo de dados: %s\n", t_data);

        % Copias para nao alterar os datasets base
        tabCaseLib   = tabCaseLib_base;
        tabCaseLib_T = tabCaseLib_T_base;

        if t_data == "NORM"
            fprintf("      A normalizar atributos numericos...\n");

            cols_min = dict_att_min(num_att_cols);
            cols_max = dict_att_max(num_att_cols);

            tabCaseLib{:, num_att_cols}   = normalize_values(tabCaseLib{:, num_att_cols}, cols_min, cols_max);
            tabCaseLib_T{:, num_att_cols} = normalize_values(tabCaseLib_T{:, num_att_cols}, cols_min, cols_max);
        end

        for wf_idx = 1:numel(wf_names)

            t_wf = wf_names(wf_idx);
            wf   = wf_values{wf_idx};

            fprintf("\n      Teste CBR: %s - %s - pesos %s\n", t_imput, t_data, t_wf);

            % Colunas para guardar previsoes
            tabCaseLib_T.class_cat_predict  = strings(height(tabCaseLib_T), 1);
            tabCaseLib_T.predict_idx        = zeros(height(tabCaseLib_T), 1);
            tabCaseLib_T.predict_similarity = zeros(height(tabCaseLib_T), 1);

            for i = 1:height(tabCaseLib_T)

                % Retrieve:
                % procura todos os casos com similaridade >= -Inf
                % na pratica, devolve todos ordenaveis por similaridade
                [retrieved_indexes, retrieved_simil] = retrieve( ...
                    tabCaseLib(:, all_vars), ...
                    tabCaseLib_T(i, all_vars), ...
                    -Inf, ...
                    wf ...
                );

                % Escolhe o caso mais semelhante
                [retrieved_max_simil, pos] = max(retrieved_simil);
                retrieved_max_simil_idx = retrieved_indexes(pos);

                % A classe prevista e a classe do caso mais semelhante
                predict_target = tabCaseLib{retrieved_max_simil_idx, "class_cat"};

                tabCaseLib_T.class_cat_predict(i)  = string(predict_target);
                tabCaseLib_T.predict_idx(i)        = retrieved_max_simil_idx;
                tabCaseLib_T.predict_similarity(i) = retrieved_max_simil;

                % Print leve para nao encher demasiado a consola
                if mod(i, 25) == 0 || i == height(tabCaseLib_T)
                    fprintf("          Casos testados: %d/%d\n", i, height(tabCaseLib_T));
                end
            end

            % Avaliacao
            accuracy_mask = string(tabCaseLib_T.class_cat_predict) == string(tabCaseLib_T.class_cat);

            accuracy_ratio = sum(accuracy_mask) / numel(accuracy_mask) * 100;
            sim_max = max(tabCaseLib_T.predict_similarity) * 100;
            sim_min = min(tabCaseLib_T.predict_similarity) * 100;
            sim_med = mean(tabCaseLib_T.predict_similarity) * 100;
            sim_std = std(tabCaseLib_T.predict_similarity) * 100;

            fprintf("          Taxa de acerto: %.2f%%\n", accuracy_ratio);
            fprintf("          Similaridade maxima: %.2f%%\n", sim_max);
            fprintf("          Similaridade minima: %.2f%%\n", sim_min);
            fprintf("          Similaridade media: %.2f%%\n", sim_med);
            fprintf("          Similaridade desvPad: %.2f%%\n", sim_std);

            % Guarda resultados detalhados deste teste
            out_path = output_folder_path + t_imput + "/out_" + t_imput + "_" + t_data + "_" + t_wf + ".xlsx";
            writetable(tabCaseLib_T, out_path);

            fprintf("          Guardado: %s\n", out_path);

            % Guarda linha resumo
            config_name = t_imput + "-" + t_data + "-" + t_wf;

            inc = inc + 1;
            results_lst(inc).config             = config_name;
            results_lst(inc).type_imput         = t_imput;
            results_lst(inc).type_data          = t_data;
            results_lst(inc).weights            = t_wf;
            results_lst(inc).taxa_acerto        = accuracy_ratio;
            results_lst(inc).similaridade_media = sim_med;
            results_lst(inc).similaridade_min   = sim_min;
            results_lst(inc).similaridade_max   = sim_max;
            results_lst(inc).similaridade_std   = sim_std;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUARDAR RESUMO E GRAFICO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[4/5] A guardar tabela resumo...\n");

tab_res_cbr = struct2table(results_lst);

resumo_path = output_folder_path + "Common/Resultados_CBR.xlsx";
writetable(tab_res_cbr, resumo_path);

fprintf("      Resumo guardado: %s\n", resumo_path);

fprintf("\n[5/5] A gerar grafico resumo...\n");

data_to_plot = [tab_res_cbr.taxa_acerto, tab_res_cbr.similaridade_media];

fig_cbr = figure('Visible', fig_visibility, 'Position', [100, 100, 1200, 600]);

bar(data_to_plot, 'grouped');

xticks(1:height(tab_res_cbr));
xticklabels(tab_res_cbr.config);
xtickangle(45);

ylabel('Percentagem [%]', 'FontWeight', 'bold');
ylim([0 100]);

legend({'Taxa de Acerto', 'Similaridade Media'}, ...
    'Location', 'southoutside', ...
    'NumColumns', 2);

title('Resumo dos testes CBR');
grid on;
grid minor;

plot_path = output_folder_path + "Common/plot_Resumo_Testes_CBR.png";
exportgraphics(fig_cbr, plot_path, 'Resolution', 300);
close(fig_cbr);

fprintf("      Grafico guardado: %s\n", plot_path);

fprintf("\n======================================================\n");
fprintf(" TP 3.2.b concluido sem erros.\n");
fprintf("======================================================\n");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCAO LOCAL AUXILIAR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ensure_folder(folder_path)
    if ~exist(folder_path, 'dir')
        mkdir(folder_path);
    end
end