%% TP 3.3.b - Comparacao RN: dataset original vs normalizado
% Este script compara o desempenho das 3 melhores configuracoes de RN
% usando:
%   - dataset original tratado
%   - dataset normalizado
%
% Depende de:
%   - tp_3_1_tratamento_do_dataset.m
%   - tp_3_3_a_RN_implementacao.m

clc;
close all;

fprintf("\n======================================================\n");
fprintf(" TP 3.3.b - RN: ORIGINAL VS NORMALIZADO\n");
fprintf("======================================================\n\n");

%% CONFIGURACAO

num_best_cases = 3;       % numero de melhores redes a comparar
num_reps_compare = 10;     % para entrega final, mudar para 10

output_folder = "OUTPUT_3.3.b_RN_ORIG_VS_NORM";

mostrar_janelas_treino = false;
gerar_figuras_treino = false;

type_data_compare = ["ORIG", "NORM"];

fprintf("[INFO] Numero de melhores configuracoes: %d\n", num_best_cases);
fprintf("[INFO] Repeticoes por configuracao: %d\n", num_reps_compare);
fprintf("[INFO] Comparacao: ORIG vs NORM\n\n");

%% PREPARAR PROJETO

fprintf("[1/5] A preparar funcoes auxiliares...\n");

project_dir = fileparts(mfilename('fullpath'));
if project_dir == ""
    project_dir = pwd;
end

cd(project_dir);

addpath("functions");

get_file         = @tp_func_get_xlfile;
normalize_values = @tp_func_rescale;
categ2cols       = @tp_func_categ2cols;
nn_ff            = @tp_func_feedforwardNN;

fprintf("      Funcoes carregadas.\n");

%% LER RESULTADOS DO ESTUDO PARAMETRICO

fprintf("\n[2/5] A ler resultados do estudo parametrico 3.3.a...\n");

results_file = get_file("OUTPUT_3.3.a_RN_IMPL/Common/Resultados_Estudo_Parametrico.xlsx");

fprintf("      Ficheiro encontrado:\n");
fprintf("      %s\n", results_file);

tab_param = readtable(results_file);

% Ordenar por melhor accuracy de teste
tab_param = sortrows(tab_param, {'avg_acc_test', 'avg_err_test'}, {'descend', 'ascend'});

% Escolher as 3 melhores
num_best_cases = min(num_best_cases, height(tab_param));
tab_best = tab_param(1:num_best_cases, :);

fprintf("      Melhores configuracoes selecionadas:\n");

for i = 1:height(tab_best)
    fprintf("      %d) %s | acc teste = %.2f%%\n", ...
        i, string(tab_best.case_name(i)), tab_best.avg_acc_test(i));
end

%% PREPARAR OUTPUT

fprintf("\n[3/5] A preparar pasta de output...\n");

% Ler um dataset qualquer apenas para o setup identificar colunas
base_file = get_file("OUTPUT_3.1_TRATAMENTO/Median/*_IMPUTED_ORIG_Median.xlsx");
tabCaseLib = readtable(base_file);

tp_3_0_setup_common;

if ~exist(output_folder_path + "Common/", 'dir')
    mkdir(output_folder_path + "Common/");
end

fprintf("      Pasta de output: %s\n", output_folder_path);

%% COMPARAR ORIG VS NORM

fprintf("\n[4/5] A testar as melhores redes com ORIG e NORM...\n");

res_col_names = {
    'rank_original', ...
    'case_name_original', ...
    'case_name_novo', ...
    'type_imp', ...
    'type_data', ...
    'topology', ...
    'training_fun', ...
    'transf_fun_hid', ...
    'transf_fun_out', ...
    'data_split', ...
    'epochs_max_fail', ...
    'num_reps', ...
    'avg_err_global', ...
    'avg_err_test', ...
    'avg_acc_global', ...
    'avg_acc_test', ...
    'avg_num_epochs', ...
    'avg_best_epoch', ...
    'avg_tr_time'
};

num_results = height(tab_best) * numel(type_data_compare);
results_lst = cell(num_results, numel(res_col_names));
res_idx = 0;

for i = 1:height(tab_best)

    best_case = tab_best(i, :);

    fprintf("\n------------------------------------------------------\n");
    fprintf(" Configuracao %d/%d\n", i, height(tab_best));
    fprintf(" Caso original: %s\n", string(best_case.case_name));
    fprintf("------------------------------------------------------\n");

    % Ler configuracao original
    t_imput = string(best_case.type_imp);

    topology        = parse_numeric_vector(best_case.topology);
    data_split      = parse_numeric_vector(best_case.data_split);
    training_fun    = string(best_case.training_fun);
    transf_fun_hid  = string(best_case.transf_fun_hid);
    transf_fun_out  = string(best_case.transf_fun_out);
    epochs_max_fail = double(best_case.epochs_max_fail);

    % Carregar dataset tratado desta imputacao
    dataset_file = get_file("OUTPUT_3.1_TRATAMENTO/" + t_imput + "/*_IMPUTED_ORIG_" + t_imput + ".xlsx");
    tabCaseLib_base = readtable(dataset_file);

    % Carregar parametros de normalizacao
    params_file = get_file("OUTPUT_3.1_TRATAMENTO/" + t_imput + "/*_NORM_PARAMS_" + t_imput + ".mat");
    load(params_file, "dict_att_min", "dict_att_max");

    % Converter classe para colunas binarias
    [tabCaseLib_nn_base, target_outputs] = categ2cols(tabCaseLib_base, target_col);

    for t_data = type_data_compare

        res_idx = res_idx + 1;

        fprintf("\n      A testar com dados: %s\n", t_data);

        tabCaseLib_nn = tabCaseLib_nn_base;

        if t_data == "NORM"
            fprintf("      A normalizar atributos...\n");

            % Tenta normalizar todos os atributos.
            % Se os parametros existirem apenas para os numericos,
            % normaliza apenas os numericos.
            try
                cols_min = dict_att_min(att_cols);
                cols_max = dict_att_max(att_cols);
                norm_cols = att_cols;
            catch
                cols_min = dict_att_min(num_att_cols);
                cols_max = dict_att_max(num_att_cols);
                norm_cols = num_att_cols;
            end

            tabCaseLib_nn{:, norm_cols} = normalize_values( ...
                tabCaseLib_nn{:, norm_cols}, cols_min, cols_max);
        else
            fprintf("      Dados originais tratados. Sem normalizacao.\n");
        end

        input_layer  = tabCaseLib_nn{:, att_cols};
        output_layer = tabCaseLib_nn{:, target_outputs};

        % Criar estrutura para a funcao da rede neuronal
        nn_case = struct();

        nn_case.type_imp        = t_imput;
        nn_case.type_data       = t_data;
        nn_case.topology        = topology;
        nn_case.training_fun    = training_fun;
        nn_case.transf_fun_hid  = transf_fun_hid;
        nn_case.transf_fun_out  = transf_fun_out;
        nn_case.data_split      = data_split;
        nn_case.epochs_max_fail = epochs_max_fail;
        nn_case.input_layer     = input_layer;
        nn_case.output_layer    = output_layer;
        nn_case.case_name       = criar_nome_caso(nn_case);

        fprintf("      Nova configuracao: %s\n", nn_case.case_name);

        % Acumuladores
        sum_err_global = 0;
        sum_err_test   = 0;
        sum_acc_global = 0;
        sum_acc_test   = 0;
        sum_epochs     = 0;
        sum_best_epoch = 0;
        sum_time       = 0;

        valid_reps = 0;

        for rep = 1:num_reps_compare

            fprintf("        Repeticao %d/%d... ", rep, num_reps_compare);

            nn_case.rep_num = rep;

            try
                nn_out = nn_ff(nn_case, ~mostrar_janelas_treino, gerar_figuras_treino);

                sum_err_global = sum_err_global + nn_out.err_glob;
                sum_err_test   = sum_err_test   + nn_out.err_test;
                sum_acc_global = sum_acc_global + nn_out.acc_glob;
                sum_acc_test   = sum_acc_test   + nn_out.acc_test;
                sum_epochs     = sum_epochs     + nn_out.num_epochs;
                sum_best_epoch = sum_best_epoch + nn_out.best_epoch;
                sum_time       = sum_time       + nn_out.tr_time;

                valid_reps = valid_reps + 1;

                fprintf("acc teste = %.2f%%\n", nn_out.acc_test);

            catch ME
                fprintf("ERRO: %s\n", ME.message);
            end
        end

        if valid_reps == 0
            avg_err_global = NaN;
            avg_err_test   = NaN;
            avg_acc_global = NaN;
            avg_acc_test   = NaN;
            avg_epochs     = NaN;
            avg_best_epoch = NaN;
            avg_time       = NaN;
        else
            avg_err_global = sum_err_global / valid_reps;
            avg_err_test   = sum_err_test   / valid_reps;
            avg_acc_global = sum_acc_global / valid_reps;
            avg_acc_test   = sum_acc_test   / valid_reps;
            avg_epochs     = sum_epochs     / valid_reps;
            avg_best_epoch = sum_best_epoch / valid_reps;
            avg_time       = sum_time       / valid_reps;
        end

        fprintf("      Resultado medio: acc teste = %.2f%% | erro teste = %.4f\n", ...
            avg_acc_test, avg_err_test);

        % Rank original
        if any(strcmp(tab_best.Properties.VariableNames, "rank"))
            rank_original = best_case.rank;
        else
            rank_original = i;
        end

        results_lst(res_idx, :) = {
            rank_original, ...
            string(best_case.case_name), ...
            string(nn_case.case_name), ...
            string(t_imput), ...
            string(t_data), ...
            mat2str(topology), ...
            string(training_fun), ...
            string(transf_fun_hid), ...
            string(transf_fun_out), ...
            mat2str(data_split), ...
            epochs_max_fail, ...
            valid_reps, ...
            avg_err_global, ...
            avg_err_test, ...
            avg_acc_global, ...
            avg_acc_test, ...
            avg_epochs, ...
            avg_best_epoch, ...
            avg_time
        };
    end
end

%% GUARDAR RESULTADOS

fprintf("\n[5/5] A guardar resultados e grafico...\n");

tab_results = cell2table(results_lst, 'VariableNames', res_col_names);

out_file = output_folder_path + "Common/Resultados_RN_ORIG_vs_NORM.xlsx";
writetable(tab_results, out_file);

fprintf("      Excel guardado em:\n");
fprintf("      %s\n", out_file);

% Grafico simples
fig = figure('Visible', 'off', 'Position', [100 100 1100 550]);

bar(tab_results.avg_acc_test);

xticks(1:height(tab_results));

labels = tab_results.type_imp + "_" + tab_results.type_data + "_R" + string(tab_results.rank_original);
xticklabels(labels);
xtickangle(45);

ylabel("Accuracy de teste [%]", "FontWeight", "bold");
ylim([0 100]);

title("Comparacao RN - Dataset Original vs Normalizado");
grid on;

plot_file = output_folder_path + "Common/plot_RN_ORIG_vs_NORM.png";
exportgraphics(fig, plot_file, 'Resolution', 300);
close(fig);

fprintf("      Grafico guardado em:\n");
fprintf("      %s\n", plot_file);

fprintf("\n======================================================\n");
fprintf(" TP 3.3.b concluido.\n");
fprintf("======================================================\n\n");

%% FUNCOES LOCAIS

function v = parse_numeric_vector(value)
% Converte valores lidos do Excel, como "[5 5]" ou "[0.7 0.15 0.15]",
% para vetor numerico.

    if isnumeric(value)
        v = value;
        return;
    end

    if iscell(value)
        value = value{1};
    end

    value = string(value);

    nums = regexp(value, '[-+]?\d*\.?\d+', 'match');

    if isempty(nums)
        error("Nao foi possivel converter para vetor numerico: %s", value);
    end

    v = str2double(nums);
end


function name = criar_nome_caso(nn)
% Cria um nome simples para identificar a configuracao da rede.

    name = "RN_" + string(nn.type_imp) + "_" + string(nn.type_data);

    name = name + "_Topo";
    for i = 1:numel(nn.topology)
        name = name + "-" + string(nn.topology(i));
    end

    name = name + "_" + string(nn.training_fun);
    name = name + "_" + string(nn.transf_fun_out);
    name = name + "_MF" + string(nn.epochs_max_fail);
end