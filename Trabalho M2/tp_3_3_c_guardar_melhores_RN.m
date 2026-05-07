%% TP 3.3.c - Guardar as 3 melhores Redes Neuronais
% Este script lê os resultados do estudo parametrico das RN,
% seleciona as 3 melhores configuracoes e guarda uma rede treinada
% para cada uma delas.
%
% Depende de:
%   - tp_3_1_tratamento_do_dataset.m
%   - tp_3_3_a_RN_implementacao.m

clc;
close all;

fprintf("\n======================================================\n");
fprintf(" TP 3.3.c - GUARDAR AS 3 MELHORES REDES NEURONAIS\n");
fprintf("======================================================\n\n");

%% CONFIGURACAO

num_best_networks = 3;
num_reps_save = 10;     % para entrega final mudar para 10

output_folder = "OUTPUT_3.3.c_MELHORES_RN";

mostrar_janelas_treino = false;
gerar_figuras_treino = false;

fprintf("[INFO] Numero de redes a guardar: %d\n", num_best_networks);
fprintf("[INFO] Repeticoes por configuracao: %d\n", num_reps_save);

%% PREPARAR PROJETO

fprintf("\n[1/5] A preparar funcoes auxiliares...\n");

project_dir = fileparts(mfilename('fullpath'));

if project_dir == ""
    project_dir = pwd;
end

cd(project_dir);

addpath("functions");

get_file          = @tp_func_get_xlfile;
normalize_values = @tp_func_rescale;
categ2cols        = @tp_func_categ2cols;
nn_ff             = @tp_func_feedforwardNN;

fprintf("      Funcoes carregadas.\n");

%% LER RESULTADOS DO ESTUDO PARAMETRICO

fprintf("\n[2/5] A ler resultados do estudo parametrico...\n");

results_file = get_file("OUTPUT_3.3.a_RN_IMPL/Common/Resultados_Estudo_Parametrico.xlsx");

fprintf("      Ficheiro encontrado:\n");
fprintf("      %s\n", results_file);

tab_param = readtable(results_file);

% Ordenar por maior accuracy de teste e menor erro de teste
tab_param = sortrows(tab_param, {'avg_acc_test', 'avg_err_test'}, {'descend', 'ascend'});

num_best_networks = min(num_best_networks, height(tab_param));
tab_best = tab_param(1:num_best_networks, :);

fprintf("      Top %d configuracoes selecionadas:\n", num_best_networks);

for i = 1:height(tab_best)
    fprintf("      %d) %s | acc teste = %.2f%%\n", ...
        i, string(tab_best.case_name(i)), tab_best.avg_acc_test(i));
end

%% PREPARAR OUTPUT

fprintf("\n[3/5] A preparar pasta de output...\n");

% Ler dataset apenas para o setup_common identificar colunas
base_file = get_file("OUTPUT_3.1_TRATAMENTO/Median/*_IMPUTED_ORIG_Median.xlsx");
tabCaseLib = readtable(base_file);

tp_3_0_setup_common;

if ~exist(output_folder_path + "Common/", 'dir')
    mkdir(output_folder_path + "Common/");
end

if ~exist(output_folder_path + "Redes/", 'dir')
    mkdir(output_folder_path + "Redes/");
end

fprintf("      Pasta de output: %s\n", output_folder_path);

%% TREINAR E GUARDAR AS MELHORES REDES

fprintf("\n[4/5] A treinar e guardar redes...\n");

res_col_names = {
    'rank_guardado', ...
    'case_name_original', ...
    'ficheiro_rede', ...
    'type_imp', ...
    'type_data', ...
    'topology', ...
    'training_fun', ...
    'transf_fun_hid', ...
    'transf_fun_out', ...
    'data_split', ...
    'epochs_max_fail', ...
    'best_rep', ...
    'acc_test', ...
    'err_test', ...
    'acc_global', ...
    'err_global'
};

results_lst = cell(num_best_networks, numel(res_col_names));

for i = 1:height(tab_best)

    best_case = tab_best(i, :);

    fprintf("\n------------------------------------------------------\n");
    fprintf(" Rede %d/%d\n", i, height(tab_best));
    fprintf(" Configuracao: %s\n", string(best_case.case_name));
    fprintf("------------------------------------------------------\n");

    % Dados da configuracao
    t_imput = string(best_case.type_imp);
    t_data  = string(best_case.type_data);

    topology        = parse_numeric_vector(best_case.topology);
    data_split      = parse_numeric_vector(best_case.data_split);
    training_fun    = string(best_case.training_fun);
    transf_fun_hid  = string(best_case.transf_fun_hid);
    transf_fun_out  = string(best_case.transf_fun_out);
    epochs_max_fail = double(best_case.epochs_max_fail);

    % Carregar dataset tratado
    dataset_file = get_file("OUTPUT_3.1_TRATAMENTO/" + t_imput + "/*_IMPUTED_ORIG_" + t_imput + ".xlsx");
    tabCaseLib_base = readtable(dataset_file);

    % Carregar parametros de normalizacao
    params_file = get_file("OUTPUT_3.1_TRATAMENTO/" + t_imput + "/*_NORM_PARAMS_" + t_imput + ".mat");
    load(params_file, "dict_att_min", "dict_att_max");

    % Converter target em colunas binarias
    [tabCaseLib_nn, target_outputs] = categ2cols(tabCaseLib_base, target_col);

    % Normalizar se a configuracao usar NORM
    if t_data == "NORM"

        fprintf("      A normalizar atributos...\n");

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
    end

    input_layer  = tabCaseLib_nn{:, att_cols};
    output_layer = tabCaseLib_nn{:, target_outputs};

    % Criar estrutura da rede
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
    nn_case.case_name       = "BEST_RN_" + string(i);

    % Treina varias vezes e guarda a melhor repeticao
    best_nn_out = [];
    best_acc_test = -Inf;
    best_rep = 0;

    for rep = 1:num_reps_save

        fprintf("      Repeticao %d/%d... ", rep, num_reps_save);

        nn_case.rep_num = rep;

        try
            nn_out = nn_ff(nn_case, ~mostrar_janelas_treino, gerar_figuras_treino);

            fprintf("acc teste = %.2f%%\n", nn_out.acc_test);

            if nn_out.acc_test > best_acc_test
                best_acc_test = nn_out.acc_test;
                best_nn_out = nn_out;
                best_rep = rep;
            end

        catch ME
            fprintf("ERRO: %s\n", ME.message);
        end
    end

    if isempty(best_nn_out)
        error("Nao foi possivel treinar a rede %d.", i);
    end

    % Dados importantes para usar depois no teste final
    net = best_nn_out.net;
    config = nn_case;
    preprocessing.att_cols = att_cols;
    preprocessing.target_col = target_col;
    preprocessing.target_outputs = target_outputs;
    preprocessing.type_imp = t_imput;
    preprocessing.type_data = t_data;
    preprocessing.dict_att_min = dict_att_min;
    preprocessing.dict_att_max = dict_att_max;
    preprocessing.num_att_cols = num_att_cols;

    file_net = output_folder_path + "Redes/best_RN_" + string(i) + ".mat";

    save(file_net, ...
        "net", ...
        "config", ...
        "preprocessing", ...
        "best_nn_out");

    fprintf("      Rede guardada em:\n");
    fprintf("      %s\n", file_net);

    results_lst(i, :) = {
        i, ...
        string(best_case.case_name), ...
        string(file_net), ...
        t_imput, ...
        t_data, ...
        mat2str(topology), ...
        training_fun, ...
        transf_fun_hid, ...
        transf_fun_out, ...
        mat2str(data_split), ...
        epochs_max_fail, ...
        best_rep, ...
        best_nn_out.acc_test, ...
        best_nn_out.err_test, ...
        best_nn_out.acc_glob, ...
        best_nn_out.err_glob
    };
end

%% GUARDAR RESUMO

fprintf("\n[5/5] A guardar resumo das redes guardadas...\n");

tab_results = cell2table(results_lst, 'VariableNames', res_col_names);

out_file = output_folder_path + "Common/Resumo_Melhores_RN_Guardadas.xlsx";
writetable(tab_results, out_file);

fprintf("      Resumo guardado em:\n");
fprintf("      %s\n", out_file);

fprintf("\n======================================================\n");
fprintf(" TP 3.3.c concluido.\n");
fprintf("======================================================\n\n");

%% FUNCAO LOCAL

function v = parse_numeric_vector(value)
% Converte valores vindos do Excel para vetor numerico.
% Exemplo:
%   "[5 5]" -> [5 5]
%   "[0.7 0.15 0.15]" -> [0.7 0.15 0.15]

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