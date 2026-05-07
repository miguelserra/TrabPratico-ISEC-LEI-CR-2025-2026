%% TP 3.1 - Tratamento do dataset
% Este script prepara os dados para as fases seguintes do trabalho:
% 1) carrega dataset de treino e teste;
% 2) gera graficos exploratorios sem usar Statistics Toolbox;
% 3) converte atributos categoricos para codigos numericos;
% 4) preenche valores em falta nos atributos por Median/Mode e MICE;
% 5) preenche valores em falta no target usando CBR/Retrieve;
% 6) guarda datasets tratados e parametros de normalizacao.

clc;
clear;
close all;

% Mostra mensagens durante a execucao.
verbose = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURACAO INICIAL                                             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Garante que o script corre a partir da pasta onde ele se encontra.
project_dir = fileparts(mfilename('fullpath'));
if project_dir == ""
    project_dir = pwd;
end
cd(project_dir);

addpath(fullfile(project_dir, 'functions'));

fill_nans    = @tp_func_fill_nans;
retrieve     = @tp_func_retrieve;
get_datafile = @tp_func_get_datafile;
encode_cats  = @tp_func_encode_categoricals;

% nome base dos ficheiros em DADOS/
name = "dataset_TP";

% nome da pasta de output
output_folder = "OUTPUT_3.1_TRATAMENTO";

fprintf("\n======================================================\n");
fprintf(" TP 3.1 - TRATAMENTO DO DATASET\n");
fprintf("======================================================\n\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTACAO DE DATASET E SETUP INICIAL %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("[1/6] A ler datasets...\n");

train_file = get_datafile(name + ".csv");
test_file  = get_datafile(name + "_test.csv");

tabCaseLib   = readtable(train_file);
tabCaseLib_T = readtable(test_file);

fprintf("      Treino: %s (%d linhas)\n", train_file, height(tabCaseLib));
fprintf("      Teste : %s (%d linhas)\n", test_file, height(tabCaseLib_T));

% prepara as variaveis comuns:
% all_vars, att_cols, target_col, num_att_cols, categorical_att_cols,
% output_folder_path e time
tp_3_0_setup_common;

print_missing_summary(tabCaseLib, "Dataset treino - valores em falta iniciais");
print_missing_summary(tabCaseLib_T, "Dataset teste - valores em falta iniciais");

fprintf("\n      Colunas numericas usadas: %s\n", strjoin(num_att_cols, ", "));
fprintf("      Colunas categoricas usadas: %s\n", strjoin(categorical_att_cols, ", "));
fprintf("      Coluna target: %s\n", target_col);

ensure_folder(output_folder_path + "Common/");
ensure_folder(output_folder_path + "Median/");
ensure_folder(output_folder_path + "MICE/");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT DE ATRIBUTOS VS TARGET         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[2/6] A gerar graficos Atributos vs Target...\n");

% Para os graficos usa-se apenas linhas completas, para nao misturar
% valores em falta com a analise exploratoria.
tabCaseLib_NoNaNs = rmmissing(tabCaseLib);
target_data = categorical(tabCaseLib_NoNaNs.(target_col));

for col_name = att_cols

    fig = figure('Visible', 'off', 'Position', [100 100 900 650]);
    file_name = output_folder_path + "Common/plot_" + col_name + ".png";

    if ismember(col_name, num_att_cols)
        % Substitui o boxplot, que pode exigir Statistics Toolbox.
        % Mostra a distribuicao dos valores numericos por classe usando scatter.
        plot_numeric_vs_target(tabCaseLib_NoNaNs.(col_name), target_data, col_name, target_col);

    elseif ismember(col_name, categorical_att_cols)
        % Substitui o crosstab, que pode exigir Statistics Toolbox.
        % Calcula a matriz de frequencias manualmente.
        att_data = categorical(tabCaseLib_NoNaNs.(col_name));
        [freq_matrix, labels_att, labels_target] = make_frequency_matrix(att_data, target_data);

        bar(freq_matrix, 'grouped');
        xlabel(strrep(string(col_name), "_", " "), 'FontWeight', 'bold');
        ylabel('Num. ocorrencias', 'FontWeight', 'bold');
        title("Distribuicao de " + strrep(string(col_name), "_", " ") + " por classe");
        xticks(1:numel(labels_att));
        xticklabels(strrep(labels_att, "_", " "));
        legend(strrep(labels_target, "_", " "), 'Location', 'southoutside', 'NumColumns', 3);
        grid on;
    end

    save_figure(fig, file_name);
    close(fig);
    fprintf("      Guardado: %s\n", file_name);
end

fprintf("      Graficos exportados com sucesso.\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONVERSAO DE CATEGORICAS EM INTEGER %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[3/6] A converter variaveis categoricas para codigos numericos...\n");

% Codificacao usada:
% maintenance_level: Low=1, Medium=2, High=3
% operating_mode   : Idle=1, Normal=2, Overload=3
% cooling_type     : Air=1, Oil=2
% sensor_status    : OK=1, Warning=2
% Esta funcao garante que treino e teste usam exatamente a mesma codificacao.
tabCaseLib   = encode_cats(tabCaseLib);
tabCaseLib_T = encode_cats(tabCaseLib_T);

writetable(tabCaseLib,   output_folder_path + "Common/out_" + name + "_num.xlsx");
writetable(tabCaseLib_T, output_folder_path + "Common/out_" + name + "_test_num.xlsx");

fprintf("      Datasets numericos guardados em Common/.\n");
print_missing_summary(tabCaseLib, "Depois da codificacao - treino");
print_missing_summary(tabCaseLib_T, "Depois da codificacao - teste");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREENCHE NaNs NAS COLUNAS DOS ATRIBUTOS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[4/6] A preencher valores em falta nos ATRIBUTOS...\n");

% O target ainda nao e preenchido aqui. Primeiro tratam-se apenas os atributos.
ignore_cols = target_col;

tabCaseLib_dict = fill_nans(tabCaseLib, categorical_att_cols, ignore_cols);

print_missing_summary(tabCaseLib_dict{"Median"}, "Depois de Median/Mode - ainda pode faltar target");
print_missing_summary(tabCaseLib_dict{"MICE"}, "Depois de MICE - ainda pode faltar target");

writetable(tabCaseLib_dict{"Median"}, output_folder_path + "Median/out1_" + name + "_imputedAtt_median.xlsx");
writetable(tabCaseLib_dict{"MICE"},   output_folder_path + "MICE/out1_" + name + "_imputedAtt_mice.xlsx");

% Se a funcao MICE tiver criado a imagem de convergencia na raiz, copia-a para Common.
if isfile("Convergencia MICE.jpg")
    copyfile("Convergencia MICE.jpg", output_folder_path + "Common/Convergencia_MICE.jpg");
end

fprintf("      Atributos preenchidos por Median/Mode e MICE.\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREENCHE NaNs NA COLUNA DO TARGET %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[5/6] A preencher valores em falta no TARGET usando CBR/Retrieve...\n");

% Pesos usados no calculo da similaridade global do CBR.
% Sao pesos heurísticos: variaveis consideradas mais relevantes recebem
% maior importancia no calculo da similaridade.
weighting_factors = [ ...
    5, ... % 1  temperature
    5, ... % 2  vibration
    4, ... % 3  rotation_speed
    2, ... % 4  voltage
    4, ... % 5  current
    1, ... % 6  pressure
    3, ... % 7  noise_level
    3, ... % 8  efficiency
    3, ... % 9  load_val
    3, ... % 10 torque
    3, ... % 11 maintenance_level
    2, ... % 12 operating_mode
    2, ... % 13 cooling_type
    3  ... % 14 sensor_status
];

print_weights(att_cols, weighting_factors);

for tab_name = transpose(keys(tabCaseLib_dict))

    fprintf("\n      Tabela %s\n", tab_name);

    tab_norm = tabCaseLib_dict{tab_name};

    % Para o Retrieve, os atributos numericos sao normalizados temporariamente.
    % Isto evita que variaveis com escalas maiores dominem a distancia.
    max_vals = max(tab_norm{:, num_att_cols});
    min_vals = min(tab_norm{:, num_att_cols});
    ranges   = max_vals - min_vals;
    ranges(ranges == 0) = 1;
    tab_norm{:, num_att_cols} = (tab_norm{:, num_att_cols} - min_vals) ./ ranges;

    % Guarda o indice original para conseguir mapear case_lib -> tabela original.
    tab_norm.original_idx = transpose(1:height(tab_norm));

    mask_target_missing = ismissing(tab_norm.(target_col));
    case_lib = tab_norm(~mask_target_missing, :);

    % Remove coluna auxiliar da tabela do novo caso. A case_lib mantem esta coluna
    % para permitir recuperar o indice original.
    tab_norm.original_idx = [];

    missing_idx = find(mask_target_missing);

    fprintf("         Targets em falta para preencher: %d\n", numel(missing_idx));

    if isempty(missing_idx)
        fprintf("         Nao existem targets em falta.\n");
    end

    for idx = transpose(missing_idx)

        fprintf("         CBR/Retrieve - Caso %d... ", idx);

        [retrieved_idxs, retrieved_simil] = retrieve(case_lib(:, all_vars), tab_norm(idx, all_vars), 0.0, weighting_factors);

        [retrieved_max_simil, retrieved_max_simil_pos] = max(retrieved_simil);
        case_lib_best_idx = retrieved_idxs(retrieved_max_simil_pos);
        original_best_idx = case_lib.original_idx(case_lib_best_idx);

        % Copia o target do caso mais semelhante para o caso com target em falta.
        tabCaseLib_dict{tab_name}.(target_col)(idx) = case_lib.(target_col)(case_lib_best_idx);

        fprintf("similar ao caso %d (sim = %.2f%%)\n", original_best_idx, retrieved_max_simil * 100);
    end

    out_file = output_folder_path + tab_name + "/out2_" + name + "_IMPUTED_ORIG_" + tab_name + ".xlsx";
    writetable(tabCaseLib_dict{tab_name}, out_file);
    fprintf("         Ficheiro guardado: %s\n", out_file);
    print_missing_summary(tabCaseLib_dict{tab_name}, "Depois do preenchimento do target - " + tab_name);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARA E GUARDA NORMALIZACAO       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[6/6] A guardar parametros de normalizacao e datasets normalizados...\n");

for tab_name = transpose(keys(tabCaseLib_dict))

    tab_orig = tabCaseLib_dict{tab_name};

    % Calcula min/max de todos os atributos. As fases de RN podem normalizar
    % todos os atributos; o CBR usa estes parametros apenas para os numericos.
    cols_min = min(tab_orig{:, att_cols});
    cols_max = max(tab_orig{:, att_cols});
    ranges   = cols_max - cols_min;
    ranges(ranges == 0) = 1;

    dictkeys = string(att_cols);
    dict_att_min = dictionary(dictkeys, cols_min);
    dict_att_max = dictionary(dictkeys, cols_max);

    % Guarda parametros de normalizacao para serem reutilizados nos scripts seguintes.
    params_file = output_folder_path + tab_name + "/out4_" + name + "_NORM_PARAMS_" + tab_name + ".mat";
    save(params_file, 'dict_att_min', 'dict_att_max');

    % Tambem guarda uma versao normalizada para consulta/relatorio.
    tab_norm = tab_orig;
    tab_norm{:, att_cols} = (tab_norm{:, att_cols} - cols_min) ./ ranges;

    writetable(tab_norm, output_folder_path + tab_name + "/out3_" + name + "_IMPUTED_NORM_" + tab_name + ".xlsx");

    fprintf("      %s: parametros e dataset normalizado guardados.\n", tab_name);
end

fprintf("\n======================================================\n");
fprintf(" TP 3.1 concluido sem erros.\n");
fprintf(" Output criado em: %s\n", output_folder_path);
fprintf("======================================================\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCOES LOCAIS                                                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ensure_folder(folder_path)
    if ~exist(folder_path, 'dir')
        mkdir(folder_path);
    end
end

function save_figure(fig, file_name)
    try
        exportgraphics(fig, file_name, 'Resolution', 300);
    catch
        saveas(fig, file_name);
    end
end

function plot_numeric_vs_target(values, target_data, col_name, target_col)
    labels_target = categories(target_data);
    hold on;

    for k = 1:numel(labels_target)
        mask = target_data == labels_target{k};
        y = values(mask);
        x = k + (rand(size(y)) - 0.5) * 0.25;

        scatter(x, y, 10, 'filled');

        % Linha da media por classe. Usa omitnan para seguranca.
        if ~isempty(y)
            y_mean = mean(y, 'omitnan');
            plot([k - 0.25, k + 0.25], [y_mean, y_mean], 'LineWidth', 2);
        end
    end

    hold off;
    xlabel(strrep(string(target_col), "_", " "), 'FontWeight', 'bold');
    ylabel(strrep(string(col_name), "_", " "), 'FontWeight', 'bold');
    title("Distribuicao de " + strrep(string(col_name), "_", " ") + " por classe");
    xticks(1:numel(labels_target));
    xticklabels(strrep(labels_target, "_", " "));
    grid on;
end

function [freq_matrix, labels_att, labels_target] = make_frequency_matrix(att_data, target_data)
    labels_att = string(categories(att_data));
    labels_target = string(categories(target_data));

    freq_matrix = zeros(numel(labels_att), numel(labels_target));

    for i = 1:numel(labels_att)
        for j = 1:numel(labels_target)
            freq_matrix(i, j) = sum(att_data == labels_att(i) & target_data == labels_target(j));
        end
    end
end


function print_missing_summary(T, title_msg)
    % Mostra um resumo simples de valores em falta por coluna.
    fprintf("\n      --- %s ---\n", title_msg);

    col_names = string(T.Properties.VariableNames);
    missing_counts = sum(ismissing(T));
    total_missing = sum(missing_counts);

    fprintf("      Dimensao: %d linhas x %d colunas\n", height(T), width(T));
    fprintf("      Total de valores em falta: %d\n", total_missing);

    if total_missing == 0
        fprintf("      Sem valores em falta.\n");
        return;
    end

    for i = 1:numel(col_names)
        if missing_counts(i) > 0
            perc = 100 * missing_counts(i) / height(T);
            fprintf("      %-20s -> %4d em falta (%.2f%%)\n", col_names(i), missing_counts(i), perc);
        end
    end
end

function print_weights(att_cols, weights)
    % Mostra os pesos usados no CBR para facilitar a explicacao.
    fprintf("\n      Pesos usados no CBR/Retrieve:\n");
    for i = 1:numel(att_cols)
        fprintf("      %-20s -> peso %.2f\n", att_cols(i), weights(i));
    end
end
