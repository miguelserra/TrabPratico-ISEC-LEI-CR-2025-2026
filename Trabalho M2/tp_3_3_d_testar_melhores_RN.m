%% TP 3.3.d - Testar as melhores RN no dataset de teste
% Este script carrega as 3 melhores redes neuronais guardadas no ponto 3.3.c
% e testa-as no dataset de teste.
%
% Depende de:
%   - tp_3_1_tratamento_do_dataset.m
%   - tp_3_3_c_guardar_melhores_RN.m

clc;
close all;

fprintf("\n======================================================\n");
fprintf(" TP 3.3.d - TESTAR MELHORES REDES NO DATASET DE TESTE\n");
fprintf("======================================================\n\n");

%% CONFIGURACAO

output_folder = "OUTPUT_3.3.d_TESTE_MELHORES_RN";

fprintf("[INFO] Pasta de output: %s\n", output_folder);

%% PREPARAR PROJETO

fprintf("\n[1/5] A preparar funcoes auxiliares...\n");

project_dir = fileparts(mfilename('fullpath'));

if project_dir == ""
    project_dir = pwd;
end

cd(project_dir);

addpath("functions");

normalize_values = @tp_func_rescale;
categ2cols       = @tp_func_categ2cols;

fprintf("      Funcoes carregadas.\n");

%% LOCALIZAR REDES GUARDADAS

fprintf("\n[2/5] A localizar redes guardadas no ponto 3.3.c...\n");

net_files = dir("OUTPUT_3.3.c_MELHORES_RN/Redes/best_RN_*.mat");

if isempty(net_files)
    error("Nao foram encontradas redes em OUTPUT_3.3.c_MELHORES_RN/Redes/. Corre primeiro o tp_3_3_c_guardar_melhores_RN.m");
end

fprintf("      Redes encontradas: %d\n", numel(net_files));

for i = 1:numel(net_files)
    fprintf("      %d) %s\n", i, net_files(i).name);
end

%% CARREGAR DATASET DE TESTE TRATADO

fprintf("\n[3/5] A carregar dataset de teste tratado...\n");

% O script 3.1 deve ter guardado uma versão numerica do dataset de teste
test_file = find_latest_file("OUTPUT_3.1_TRATAMENTO/Common/*_test_num.xlsx");

if test_file == ""
    error("Nao foi encontrado o dataset de teste numerico em OUTPUT_3.1_TRATAMENTO/Common/. Corre primeiro o tp_3_1_tratamento_do_dataset.m");
end

fprintf("      Dataset de teste encontrado:\n");
fprintf("      %s\n", test_file);

tabTest_base = readtable(test_file);

fprintf("      Casos de teste: %d\n", height(tabTest_base));

%% PREPARAR OUTPUT

fprintf("\n[4/5] A preparar pasta de output...\n");

% Para o setup_common identificar as colunas
tabCaseLib = tabTest_base;

tp_3_0_setup_common;

if ~exist(output_folder_path + "Common/", 'dir')
    mkdir(output_folder_path + "Common/");
end

if ~exist(output_folder_path + "Confusion/", 'dir')
    mkdir(output_folder_path + "Confusion/");
end

fprintf("      Pasta de output: %s\n", output_folder_path);

%% TESTAR CADA REDE

fprintf("\n[5/5] A testar redes...\n");

res_col_names = {
    'rede', ...
    'ficheiro_rede', ...
    'type_imp', ...
    'type_data', ...
    'topology', ...
    'training_fun', ...
    'transf_fun_out', ...
    'accuracy_global', ...
    'num_casos_teste', ...
    'num_casos_corretos'
};

results_lst = cell(numel(net_files), numel(res_col_names));

for i = 1:numel(net_files)

    fprintf("\n------------------------------------------------------\n");
    fprintf(" Rede %d/%d\n", i, numel(net_files));
    fprintf(" Ficheiro: %s\n", net_files(i).name);
    fprintf("------------------------------------------------------\n");

    net_path = fullfile(net_files(i).folder, net_files(i).name);

    load(net_path, "net", "config", "preprocessing");

    fprintf("      Tipo de imputacao: %s\n", preprocessing.type_imp);
    fprintf("      Tipo de dados: %s\n", preprocessing.type_data);

    % Copia do dataset de teste
    tabTest = tabTest_base;

    % Colunas usadas pela rede
    att_cols       = preprocessing.att_cols;
    target_col     = preprocessing.target_col;
    target_outputs = preprocessing.target_outputs;

    % Converter target para colunas binarias
    [tabTest_nn, target_outputs_test] = categ2cols(tabTest, target_col);

    % Usar as colunas de target que existirem no teste
    % Normalmente sao iguais as guardadas no treino.
    target_outputs = target_outputs_test;

    % Aplicar normalizacao se a rede foi treinada com dados normalizados
    if string(preprocessing.type_data) == "NORM"

        fprintf("      A normalizar atributos do teste...\n");

        dict_att_min = preprocessing.dict_att_min;
        dict_att_max = preprocessing.dict_att_max;

        % Tenta normalizar todos os atributos.
        % Se os parametros existirem apenas para numericos, normaliza apenas esses.
        try
            cols_min = dict_att_min(att_cols);
            cols_max = dict_att_max(att_cols);
            norm_cols = att_cols;
        catch
            cols_min = dict_att_min(preprocessing.num_att_cols);
            cols_max = dict_att_max(preprocessing.num_att_cols);
            norm_cols = preprocessing.num_att_cols;
        end

        tabTest_nn{:, norm_cols} = normalize_values( ...
            tabTest_nn{:, norm_cols}, cols_min, cols_max);
    else
        fprintf("      Rede treinada com dados ORIG. Sem normalizacao.\n");
    end

    % Preparar matrizes
    input_test  = tabTest_nn{:, att_cols};
    target_test = tabTest_nn{:, target_outputs};

    % Simular rede
    output_test = sim(net, input_test');

    % Converter saidas da rede em classes
    [~, pred_idx] = max(output_test, [], 1);
    [~, true_idx] = max(target_test', [], 1);

    correct_mask = pred_idx == true_idx;

    num_correct = sum(correct_mask);
    num_total   = numel(true_idx);

    accuracy_global = num_correct / num_total * 100;

    fprintf("      Accuracy global no teste: %.2f%%\n", accuracy_global);
    fprintf("      Casos corretos: %d/%d\n", num_correct, num_total);

    % Accuracy por classe
    fprintf("\n      Accuracy por classe:\n");

    class_rows = cell(numel(target_outputs), 4);

    for c = 1:numel(target_outputs)

        mask_class = true_idx == c;

        total_class = sum(mask_class);
        correct_class = sum(correct_mask(mask_class));

        if total_class == 0
            acc_class = NaN;
        else
            acc_class = correct_class / total_class * 100;
        end

        class_name = string(target_outputs(c));

        fprintf("        %-25s -> %.2f%% (%d/%d)\n", ...
            class_name, acc_class, correct_class, total_class);

        class_rows(c, :) = {
            string(net_files(i).name), ...
            class_name, ...
            correct_class, ...
            total_class
        };
    end

    tab_class = cell2table(class_rows, ...
        'VariableNames', {'rede', 'classe', 'corretos', 'total'});

    tab_class.accuracy_classe = tab_class.corretos ./ tab_class.total * 100;

    class_file = output_folder_path + "Common/Accuracy_Por_Classe_RN_" + string(i) + ".xlsx";
    writetable(tab_class, class_file);

    fprintf("      Accuracy por classe guardada em:\n");
    fprintf("      %s\n", class_file);

    % Criar matriz one-hot das previsoes para plotconfusion
    pred_matrix = zeros(size(target_test'));

    for k = 1:numel(pred_idx)
        pred_matrix(pred_idx(k), k) = 1;
    end

    % Matriz de confusao
    fig = figure('Visible', 'off');
    plotconfusion(target_test', pred_matrix);

    title("Matriz de confusao - " + string(net_files(i).name), 'Interpreter', 'none');

    conf_file = output_folder_path + "Confusion/confusion_RN_" + string(i) + ".png";
    exportgraphics(fig, conf_file, 'Resolution', 300);
    close(fig);

    fprintf("      Matriz de confusao guardada em:\n");
    fprintf("      %s\n", conf_file);

    % Guardar resultados resumo
    results_lst(i, :) = {
        "RN_" + string(i), ...
        string(net_files(i).name), ...
        string(preprocessing.type_imp), ...
        string(preprocessing.type_data), ...
        mat2str(config.topology), ...
        string(config.training_fun), ...
        string(config.transf_fun_out), ...
        accuracy_global, ...
        num_total, ...
        num_correct
    };
end

%% GUARDAR RESUMO FINAL

tab_results = cell2table(results_lst, 'VariableNames', res_col_names);

out_file = output_folder_path + "Common/Resumo_Teste_Melhores_RN.xlsx";
writetable(tab_results, out_file);

fprintf("\nResumo final guardado em:\n");
fprintf("%s\n", out_file);

fprintf("\n======================================================\n");
fprintf(" TP 3.3.d concluido.\n");
fprintf("======================================================\n\n");

%% FUNCAO LOCAL

function file_path = find_latest_file(pattern)
% Procura o ficheiro mais recente que cumpre um padrao.

    if isstring(pattern)
        pattern = char(pattern);
    end

    files = dir(pattern);
    files = files(~[files.isdir]);

    if isempty(files)
        file_path = "";
        return;
    end

    [~, idx] = max([files.datenum]);

    file_path = string(fullfile(files(idx).folder, files(idx).name));
end