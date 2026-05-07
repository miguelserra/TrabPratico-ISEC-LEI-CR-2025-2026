%% TP 3.3.a - Estudo parametrico das Redes Neuronais
% Este script testa varias configuracoes de redes neuronais feedforward.
%
% Objetivo:
%   - Usar os datasets tratados no TP 3.1
%   - Converter o target class_cat para colunas binarias
%   - Treinar varias redes neuronais
%   - Repetir cada configuracao varias vezes
%   - Guardar medias de erro, acerto, epocas e tempo
%
% Dependencias:
%   - MATLAB
%   - Deep Learning Toolbox
%   - Datasets gerados pelo tp_3_1_tratamento_do_dataset.m

clc;
close all;

fprintf("\n======================================================\n");
fprintf(" TP 3.3.a - ESTUDO PARAMETRICO DAS REDES NEURONAIS\n");
fprintf("======================================================\n\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURACAO GERAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MODO RAPIDO:
% true  -> poucas configuracoes, bom para testar se o script funciona
% false -> estudo mais completo, adequado para resultados finais
modo_rapido = false;

% Pasta de output
output_folder = "OUTPUT_3.3.a_RN_IMPL";

% Controla se as janelas de treino aparecem
mostrar_janelas_treino = false;

% Controla se gera figuras em cada treino
% Para estudo parametrico, normalmente fica false para nao gerar centenas de figuras.
gerar_figuras_treino = false;

% Seed aleatoria
rng('shuffle', 'twister');

fprintf("[INFO] Modo rapido: %d\n", modo_rapido);
fprintf("[INFO] Pasta de output: %s\n", output_folder);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARACAO DO PROJETO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[1/6] A preparar projeto e funcoes auxiliares...\n");

project_dir = fileparts(mfilename('fullpath'));
if project_dir == ""
    project_dir = pwd;
end

cd(project_dir);

if ~isfolder("functions")
    error("A pasta 'functions' nao foi encontrada. Verifica se estas na raiz do projeto.");
end

addpath("functions");

% Funcoes auxiliares
normalize_values = @tp_func_rescale;
nn_ff            = @tp_func_feedforwardNN;
categ2cols       = @tp_func_categ2cols;

fprintf("      Pasta do projeto: %s\n", project_dir);
fprintf("      Funcoes auxiliares carregadas.\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURACOES DO ESTUDO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[2/6] A definir configuracoes do estudo...\n");

if modo_rapido
    % Configuracao reduzida para testar rapidamente
    type_imput = ["Median", "MICE"];
    type_data  = ["NORM"];

    topology = {
        10;
        [5 5]
    };

    training_fun   = ["trainlm", "trainscg"];
    transf_fun_hid = ["tansig"];
    transf_fun_out = ["logsig", "softmax"];

    data_split_proportions = {
        [0.7 0.15 0.15]
    };

    epochs_max_fail = [6];

    % Para teste rapido, 3 repeticoes chegam.
    % O enunciado pede 10 para a versao final.
    num_reps_nn = 3;
else
    % Configuracao mais completa para resultados finais
    type_imput = ["Median", "MICE"];
    type_data  = ["NORM"];

    topology = {
        10      %-> uma camada escondida com 10 neurónios
        [5 5]   %-> duas camadas escondidas com 5 neurónios cada
        6       %-> uma camada escondida com 6 neurónios
        [3 3]   %-> duas camadas escondidas com 3 neurónios cada
        14;     %-> uma camada escondida com 6 neurónios
        [7 7]   %-> duas camadas escondidas com 7 neurónios cada
    };

    training_fun   = ["trainlm", "traingd", "trainbr", "trainscg"];
    transf_fun_hid = ["tansig"];
    transf_fun_out = ["purelin", "tansig", "logsig", "softmax"];

    data_split_proportions = {
[0.7 0.15 0.15]  %-> 70% treino, 15% validação, 15% teste
[0.6 0.2 0.2]    %-> 60% treino, 20% validação, 20% teste
[0.9 0.05 0.05]  %-> 90% treino, 5% validação, 5% teste
    };

    epochs_max_fail = [2, 6, 20];

    % O enunciado pede 10 repeticoes por configuracao
    num_reps_nn = 10;
end

num_cases_total = numel(type_imput) * ...
                  numel(type_data) * ...
                  numel(topology) * ...
                  numel(training_fun) * ...
                  numel(transf_fun_hid) * ...
                  numel(transf_fun_out) * ...
                  numel(data_split_proportions) * ...
                  numel(epochs_max_fail);

fprintf("      Imputacoes: %s\n", strjoin(type_imput, ", "));
fprintf("      Tipo de dados: %s\n", strjoin(type_data, ", "));
fprintf("      Topologias: %d\n", numel(topology));
fprintf("      Funcoes de treino: %s\n", strjoin(training_fun, ", "));
fprintf("      Funcoes de saida: %s\n", strjoin(transf_fun_out, ", "));
fprintf("      Divisoes treino/validacao/teste: %d\n", numel(data_split_proportions));
fprintf("      Valores max_fail: %s\n", mat2str(epochs_max_fail));
fprintf("      Total de configuracoes: %d\n", num_cases_total);
fprintf("      Repeticoes por configuracao: %d\n", num_reps_nn);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAR OUTPUT E COLUNAS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[3/6] A preparar output e nomes das colunas...\n");

% Para o setup_common precisamos de ler um dataset qualquer tratado
first_dataset = find_latest_file(fullfile(project_dir, "OUT_TRATAM", "Median", "*_IMPUTED_ORIG_Median.xlsx"));

if first_dataset == ""
    first_dataset = find_latest_file(fullfile(project_dir, "*TRATAM*", "Median", "*_IMPUTED_ORIG_Median.xlsx"));
end

if first_dataset == ""
    error("Nao foi encontrado dataset tratado. Corre primeiro o tp_3_1_tratamento_do_dataset.m");
end

tabCaseLib = readtable(first_dataset);

tp_3_0_setup_common;

ensure_folder(output_folder_path + "Common/");
ensure_folder(output_folder_path + "Median/");
ensure_folder(output_folder_path + "MICE/");

fprintf("      Dataset base encontrado: %s\n", first_dataset);
fprintf("      Atributos de entrada: %d\n", numel(att_cols));
fprintf("      Target: %s\n", target_col);
fprintf("      Output: %s\n", output_folder_path);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXECUCAO DO ESTUDO PARAMETRICO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[4/6] A executar estudo parametrico...\n");

res_col_names = {
    'case_name', ...
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

results_lst = cell(num_cases_total, numel(res_col_names));
idx = 0;

for t_imput = type_imput

    fprintf("\n------------------------------------------------------\n");
    fprintf(" IMPUTACAO: %s\n", t_imput);
    fprintf("------------------------------------------------------\n");

    % Dataset tratado original
    ds_train_path = find_latest_file(fullfile(project_dir, "OUT_TRATAM", char(t_imput), "*_IMPUTED_ORIG_" + char(t_imput) + ".xlsx"));

    if ds_train_path == ""
        ds_train_path = find_latest_file(fullfile(project_dir, "*TRATAM*", char(t_imput), "*_IMPUTED_ORIG_" + char(t_imput) + ".xlsx"));
    end

    if ds_train_path == ""
        error("Dataset tratado nao encontrado para imputacao %s. Corre primeiro o script 3.1.", t_imput);
    end

    fprintf("      Dataset: %s\n", ds_train_path);

    tabCaseLib_base = readtable(ds_train_path);

    % Parametros de normalizacao
    params_file_path = find_latest_file(fullfile(project_dir, "OUT_TRATAM", char(t_imput), "*_NORM_PARAMS_" + char(t_imput) + ".mat"));

    if params_file_path == ""
        params_file_path = find_latest_file(fullfile(project_dir, "*TRATAM*", char(t_imput), "*_NORM_PARAMS_" + char(t_imput) + ".mat"));
    end

    if params_file_path == ""
        error("Parametros de normalizacao nao encontrados para imputacao %s.", t_imput);
    end

    fprintf("      Parametros normalizacao: %s\n", params_file_path);

    load(params_file_path, 'dict_att_min', 'dict_att_max');

    % Converter target para colunas binarias
    [tabCaseLib_nn_base, target_outputs] = categ2cols(tabCaseLib_base, target_col);

    fprintf("      Colunas target binarias: %s\n", strjoin(target_outputs, ", "));

    for t_data = type_data

        fprintf("\n      Tipo de dados: %s\n", t_data);

        tabCaseLib_nn = tabCaseLib_nn_base;

        if t_data == "NORM"
            fprintf("      A normalizar atributos de entrada...\n");

            cols_min = dict_att_min(att_cols);
            cols_max = dict_att_max(att_cols);

            tabCaseLib_nn{:, att_cols} = normalize_values( ...
                tabCaseLib_nn{:, att_cols}, ...
                cols_min, ...
                cols_max ...
            );
        else
            fprintf("      Dados originais selecionados. Sem normalizacao.\n");
        end

        % Matriz de entrada e matriz de saida
        input_layer  = tabCaseLib_nn{:, att_cols};
        output_layer = tabCaseLib_nn{:, target_outputs};

        fprintf("      Dimensao inputs: %d casos x %d atributos\n", size(input_layer, 1), size(input_layer, 2));
        fprintf("      Dimensao targets: %d casos x %d classes\n", size(output_layer, 1), size(output_layer, 2));

        for topo_idx = 1:numel(topology)

            topo = topology{topo_idx};

            for trainf = training_fun

                for transffHid = transf_fun_hid

                    for transffOut = transf_fun_out

                        for split_idx = 1:numel(data_split_proportions)

                            split_prop = data_split_proportions{split_idx};

                            for num_e = epochs_max_fail

                                idx = idx + 1;

                                nn_case = struct();

                                nn_case.type_imp        = t_imput;
                                nn_case.type_data       = t_data;
                                nn_case.topology        = topo;
                                nn_case.training_fun    = trainf;
                                nn_case.transf_fun_hid  = transffHid;
                                nn_case.transf_fun_out  = transffOut;
                                nn_case.data_split      = split_prop;
                                nn_case.epochs_max_fail = num_e;
                                nn_case.input_layer     = input_layer;
                                nn_case.output_layer    = output_layer;
                                nn_case.case_name       = gen_case_name(nn_case);

                                fprintf("\n[%d/%d] Configuracao: %s\n", idx, num_cases_total, nn_case.case_name);

                                sum_acc_glob   = 0;
                                sum_acc_test   = 0;
                                sum_err_glob   = 0;
                                sum_err_test   = 0;
                                sum_num_epochs = 0;
                                sum_best_epoch = 0;
                                sum_tr_time    = 0;

                                valid_reps = 0;

                                for n = 1:num_reps_nn

                                    fprintf("      Repeticao %d/%d... ", n, num_reps_nn);

                                    nn_case.rep_num = n;

                                    try
                                        nn_ff_out = nn_ff(nn_case, ~mostrar_janelas_treino, gerar_figuras_treino);

                                        sum_acc_glob   = sum_acc_glob   + nn_ff_out.acc_glob;
                                        sum_acc_test   = sum_acc_test   + nn_ff_out.acc_test;
                                        sum_err_glob   = sum_err_glob   + nn_ff_out.err_glob;
                                        sum_err_test   = sum_err_test   + nn_ff_out.err_test;
                                        sum_num_epochs = sum_num_epochs + nn_ff_out.num_epochs;
                                        sum_best_epoch = sum_best_epoch + nn_ff_out.best_epoch;
                                        sum_tr_time    = sum_tr_time    + nn_ff_out.tr_time;

                                        valid_reps = valid_reps + 1;

                                        fprintf("acc teste = %.2f%%\n", nn_ff_out.acc_test);

                                    catch ME
                                        fprintf("ERRO: %s\n", ME.message);
                                    end
                                end

                                if valid_reps == 0
                                    avg_acc_glob   = NaN;
                                    avg_acc_test   = NaN;
                                    avg_err_glob   = NaN;
                                    avg_err_test   = NaN;
                                    avg_num_epochs = NaN;
                                    avg_best_epoch = NaN;
                                    avg_tr_time    = NaN;
                                else
                                    avg_acc_glob   = sum_acc_glob   / valid_reps;
                                    avg_acc_test   = sum_acc_test   / valid_reps;
                                    avg_err_glob   = sum_err_glob   / valid_reps;
                                    avg_err_test   = sum_err_test   / valid_reps;
                                    avg_num_epochs = sum_num_epochs / valid_reps;
                                    avg_best_epoch = sum_best_epoch / valid_reps;
                                    avg_tr_time    = sum_tr_time    / valid_reps;
                                end

                                fprintf("      Media acc global: %.2f%%\n", avg_acc_glob);
                                fprintf("      Media acc teste : %.2f%%\n", avg_acc_test);
                                fprintf("      Media erro teste: %.4f\n", avg_err_test);

                                results_lst(idx, :) = {
                                    nn_case.case_name, ...
                                    string(nn_case.type_imp), ...
                                    string(nn_case.type_data), ...
                                    mat2str(nn_case.topology), ...
                                    string(nn_case.training_fun), ...
                                    string(nn_case.transf_fun_hid), ...
                                    string(nn_case.transf_fun_out), ...
                                    mat2str(nn_case.data_split), ...
                                    nn_case.epochs_max_fail, ...
                                    valid_reps, ...
                                    avg_err_glob, ...
                                    avg_err_test, ...
                                    avg_acc_glob, ...
                                    avg_acc_test, ...
                                    avg_num_epochs, ...
                                    avg_best_epoch, ...
                                    avg_tr_time
                                };

                                % Guarda progresso parcial a cada configuracao.
                                tab_partial = cell2table(results_lst(1:idx, :), 'VariableNames', res_col_names);
                                partial_path = output_folder_path + "Common/Resultados_Estudo_Parametrico_PARCIAL.xlsx";
                                writetable(tab_partial, partial_path);
                            end
                        end
                    end
                end
            end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUARDAR RESULTADOS FINAIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[5/6] A guardar resultados finais...\n");

tab_results = cell2table(results_lst(1:idx, :), 'VariableNames', res_col_names);

% Ordena primeiro por maior accuracy de teste, depois por menor erro de teste
tab_results = sortrows(tab_results, {'avg_acc_test', 'avg_err_test'}, {'descend', 'ascend'});

% Adiciona ranking
rank = (1:height(tab_results))';
tab_results = addvars(tab_results, rank, 'Before', 1);

file_out = output_folder_path + "Common/Resultados_Estudo_Parametrico.xlsx";
writetable(tab_results, file_out);

fprintf("      Resultados guardados em:\n");
fprintf("      %s\n", file_out);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GERAR GRAFICO RESUMO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[6/6] A gerar grafico resumo...\n");

num_plot = min(10, height(tab_results));

fig = figure('Visible', 'off', 'Position', [100, 100, 1200, 600]);

bar(tab_results.avg_acc_test(1:num_plot));

xticks(1:num_plot);
xticklabels(tab_results.case_name(1:num_plot));
xtickangle(45);

ylabel('Accuracy de teste [%]', 'FontWeight', 'bold');
ylim([0 100]);

title('Top configuracoes - Redes Neuronais');
grid on;
grid minor;

plot_path = output_folder_path + "Common/plot_Top_RN_Accuracy_Teste.png";
exportgraphics(fig, plot_path, 'Resolution', 300);
close(fig);

fprintf("      Grafico guardado em:\n");
fprintf("      %s\n", plot_path);

fprintf("\n======================================================\n");
fprintf(" TP 3.3.a concluido.\n");
fprintf("======================================================\n\n");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCOES LOCAIS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function name = gen_case_name(nn)
%GEN_CASE_NAME Cria um nome identificador para cada configuracao de RN.

    name = "RN_" + string(nn.type_imp) + "_" + string(nn.type_data) + "_Topo";

    topo = nn.topology;

    for i = 1:numel(topo)
        name = name + "-" + string(topo(i));
    end

    name = name + "_" + string(nn.training_fun);
    name = name + "_" + string(nn.transf_fun_out);
    name = name + "_MF" + string(nn.epochs_max_fail);
    name = name + "_Div";

    for i = 1:numel(nn.data_split)
        name = name + "-" + string(nn.data_split(i));
    end
end


function file_path = find_latest_file(pattern)
%FIND_LATEST_FILE Procura o ficheiro mais recente que cumpre um padrao.

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


function ensure_folder(folder_path)
%ENSURE_FOLDER Cria uma pasta se ela ainda nao existir.

    if isstring(folder_path)
        folder_path = char(folder_path);
    end

    if ~exist(folder_path, 'dir')
        mkdir(folder_path);
    end
end