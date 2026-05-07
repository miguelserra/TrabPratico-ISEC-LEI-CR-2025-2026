%% TP 3.2.a - Implementacao do ciclo CBR
% Este script demonstra o ciclo CBR completo:
%   1) Retrieve - procurar casos semelhantes
%   2) Reuse    - reutilizar a informacao dos casos encontrados
%   3) Revise   - rever/validar a solucao proposta
%   4) Retain   - guardar o novo caso na base de casos
%
% Este script depende dos ficheiros gerados pelo:
%   tp_3_1_tratamento_do_dataset.m

clc;
close all;

fprintf("\n======================================================\n");
fprintf(" TP 3.2.a - IMPLEMENTACAO DO CICLO CBR\n");
fprintf("======================================================\n\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURACAO DO NOVO CASO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("[1/7] A definir o novo caso...\n");

% Este e o novo caso que queremos comparar com a base de casos.
% A classe class_cat ainda nao e conhecida.
clear struct_new_case;

struct_new_case.temperature        = 68.16126505;
struct_new_case.vibration          = 2.8537325;
struct_new_case.rotation_speed     = 1527.084843;
struct_new_case.voltage            = 230.198028;
struct_new_case.current            = 11.45129021;
struct_new_case.pressure           = 5.838895141;
struct_new_case.noise_level        = 83.15363686;
struct_new_case.efficiency         = 0.777862081;
struct_new_case.load_val           = 62.05525774;
struct_new_case.torque             = 151.566407;
struct_new_case.maintenance_level  = 'Low';
struct_new_case.operating_mode     = 'Overload';
struct_new_case.cooling_type       = 'Air';
struct_new_case.sensor_status      = 'OK';

fprintf("      Novo caso definido.\n");
fprintf("      Temperatura inicial: %.3f\n", struct_new_case.temperature);
fprintf("      Manutencao: %s\n", struct_new_case.maintenance_level);
fprintf("      Modo operacao: %s\n", struct_new_case.operating_mode);
fprintf("      Refrigeracao: %s\n", struct_new_case.cooling_type);
fprintf("      Sensor: %s\n", struct_new_case.sensor_status);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURACAO DO CBR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[2/7] A configurar o CBR...\n");

% Configuracoes principais
type_imput        = "MICE";   % opcoes: "Median" ou "MICE"
type_data         = "NORM";   % opcoes: "ORIG" ou "NORM"
weighting_factors = "w";      % opcoes: "w", "w2", "1s", "soCat"

% Threshold de similaridade.
% 0.90 significa que so devolve casos com similaridade >= 90%.
similarity_threshold = 0.90;

% Pasta de output deste script
output_folder = "OUTPUT_3.2.a_CBR_IMPL";

fprintf("      Imputacao usada: %s\n", type_imput);
fprintf("      Tipo de dados: %s\n", type_data);
fprintf("      Pesos usados: %s\n", weighting_factors);
fprintf("      Threshold de similaridade: %.2f%%\n", similarity_threshold * 100);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARACAO DO PROJETO E FUNCOES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[3/7] A preparar paths e funcoes auxiliares...\n");

project_dir = fileparts(mfilename('fullpath'));
if project_dir == ""
    project_dir = pwd;
end
cd(project_dir);

if ~isfolder("functions")
    error("A pasta 'functions' nao foi encontrada. Verifica se estas na raiz do projeto.");
end

addpath("functions");

retrieve         = @tp_func_retrieve;
reuse            = @tp_func_reuse;
revise           = @tp_func_revise;
retain           = @tp_func_retain;
get_file         = @tp_func_get_xlfile;
normalize_values = @tp_func_rescale;
denorm_values    = @tp_func_rescale_reverse;

fprintf("      Funcoes auxiliares carregadas.\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CARREGAR DATASET TRATADO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[4/7] A carregar dataset tratado da fase 3.1...\n");

% Procura dataset tratado original.
% Este ficheiro deve ter sido criado pelo tp_3_1_tratamento_do_dataset.m
wildcard = "*_TRATAM*/" + type_imput + "/*_IMPUTED_ORIG_" + type_imput + ".xlsx";
ds_file_path = get_file(wildcard);

fprintf("      Dataset encontrado:\n");
fprintf("      %s\n", ds_file_path);

tabCaseLib = readtable(ds_file_path);

% Guarda uma copia nao normalizada para o Retain.
tabCaseLib_orig = tabCaseLib;

% O setup_common define:
% all_vars, att_cols, target_col, num_att_cols, categorical_att_cols,
% output_folder_path
tp_3_0_setup_common;

% Cria pasta de output, caso ainda nao exista.
if output_folder_path ~= "" && ~exist(output_folder_path, 'dir')
    mkdir(output_folder_path);
end

fprintf("      Casos na base de casos: %d\n", height(tabCaseLib));
fprintf("      Numero de atributos: %d\n", numel(att_cols));
fprintf("      Target: %s\n", target_col);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CARREGAR PARAMETROS DE NORMALIZACAO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[5/7] A carregar parametros de normalizacao...\n");

wildcard = "*_TRATAM*/" + type_imput + "/*_NORM_PARAMS_" + type_imput + ".mat";
params_file_path = get_file(wildcard);

fprintf("      Parametros encontrados:\n");
fprintf("      %s\n", params_file_path);

load(params_file_path); 
% carrega:
%   dict_att_min
%   dict_att_max

fprintf("      Parametros carregados.\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINICAO DOS PESOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[6/7] A definir pesos do CBR...\n");

dict_wf = dictionary( ...
    ["w", "w2", "1s", "soCat"], ...
    { ...
        [5,5,4,2,4,1,3,3,3,3,3,2,2,3], ...
        [25,25,16,4,16,1,9,9,9,9,9,4,4,9], ...
        [1,1,1,1,1,1,1,1,1,1,1,1,1,1], ...
        [0,0,0,0,0,0,0,0,0,0,1,1,1,1] ...
    } ...
);

wf = dict_wf{weighting_factors};

fprintf("      Pesos aplicados aos atributos:\n");

for i = 1:numel(att_cols)
    fprintf("        %-20s -> %.2f\n", att_cols(i), wf(i));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONVERSAO DO NOVO CASO PARA FORMATO NUMERICO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n[7/7] A converter e preparar o novo caso...\n");

% Converte categorias para os mesmos codigos usados no tratamento.
struct_new_case.maintenance_level = double(categorical( ...
    string(struct_new_case.maintenance_level), ["Low", "Medium", "High"]));

struct_new_case.operating_mode = double(categorical( ...
    string(struct_new_case.operating_mode), ["Idle", "Normal", "Overload"]));

struct_new_case.cooling_type = double(categorical( ...
    string(struct_new_case.cooling_type), ["Air", "Oil"]));

struct_new_case.sensor_status = double(categorical( ...
    string(struct_new_case.sensor_status), ["OK", "Warning"]));

% O retrieve espera que exista a coluna target.
% Como o novo caso ainda nao tem classe, colocamos vazio.
struct_new_case.class_cat = "";

tabNewCase = struct2table(struct_new_case, 'AsArray', true);

fprintf("      Novo caso convertido para tabela.\n");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NORMALIZACAO, SE NECESSARIO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if type_data == "NORM"

    fprintf("\n[NORMALIZACAO] A normalizar atributos numericos...\n");

    cols_min = dict_att_min(num_att_cols);
    cols_max = dict_att_max(num_att_cols);

    tabCaseLib{:, num_att_cols} = normalize_values( ...
        tabCaseLib{:, num_att_cols}, cols_min, cols_max);

    tabNewCase{:, num_att_cols} = normalize_values( ...
        tabNewCase{:, num_att_cols}, cols_min, cols_max);

    fprintf("[NORMALIZACAO] Concluida.\n");
else
    fprintf("\n[NORMALIZACAO] Dados originais selecionados. Nao foi aplicada normalizacao.\n");
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1) RETRIEVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n======================================================\n");
fprintf(" 1) RETRIEVE - Procurar casos semelhantes\n");
fprintf("======================================================\n");

[retrieved_indexes, retrieved_simil] = retrieve( ...
    tabCaseLib(:, all_vars), ...
    tabNewCase(:, all_vars), ...
    similarity_threshold, ...
    wf ...
);

% Se o threshold for demasiado alto, baixa automaticamente para nao parar.
if isempty(retrieved_indexes)

    fprintf("Nao foram encontrados casos com %.2f%% de similaridade.\n", similarity_threshold * 100);
    fprintf("A repetir Retrieve com threshold = 0 para obter o caso mais semelhante.\n");

    [retrieved_indexes, retrieved_simil] = retrieve( ...
        tabCaseLib(:, all_vars), ...
        tabNewCase(:, all_vars), ...
        0.0, ...
        wf ...
    );
end

if isempty(retrieved_indexes)
    error("O Retrieve nao devolveu nenhum caso. Verifica os dados ou a funcao tp_func_retrieve.");
end

% Ordena por similaridade decrescente.
[retrieved_simil, order_idx] = sort(retrieved_simil, 'descend');
retrieved_indexes = retrieved_indexes(order_idx);

retrieved_cases = tabCaseLib(retrieved_indexes, :);
retrieved_cases.similarity = retrieved_simil;

% Para mostrar no output, voltamos a escala original se os dados estavam normalizados.
retrieved_cases_orig = retrieved_cases;

if type_data == "NORM"
    cols_min = dict_att_min(num_att_cols);
    cols_max = dict_att_max(num_att_cols);

    retrieved_cases_orig{:, num_att_cols} = denorm_values( ...
        retrieved_cases{:, num_att_cols}, cols_min, cols_max);
end

col_idx = table(retrieved_indexes, 'VariableNames', {'IndiceOriginal'});
retrieved_cases_orig = [col_idx, retrieved_cases_orig];

fprintf("\nCasos devolvidos pelo Retrieve:\n");
fprintf("Threshold usado: %.2f%%\n\n", similarity_threshold * 100);

disp(retrieved_cases_orig);

% Guarda resultados do Retrieve.
path_retrieve = output_folder_path + ...
    "out_RETRIEVED_CASES_" + type_imput + "_" + type_data + "_" + weighting_factors + ".xlsx";

writetable(retrieved_cases_orig, path_retrieve);

fprintf("Resultados do Retrieve guardados em:\n");
fprintf("%s\n", path_retrieve);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2) REUSE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n======================================================\n");
fprintf(" 2) REUSE - Reutilizar conhecimento dos casos encontrados\n");
fprintf("======================================================\n");

if type_data ~= "NORM"
    fprintf("AVISO: O Reuse usa uma rede simples pensada para dados normalizados.\n");
    fprintf("Recomenda-se usar type_data = 'NORM'.\n");
end

% A funcao reuse treina uma rede simples com os casos encontrados.
% Ela tenta prever a temperatura do novo caso com base em alguns sensores.
[new_temp_norm, ff_error] = reuse(retrieved_cases, tabNewCase);

if type_data == "NORM"
    tmin = dict_att_min("temperature");
    tmax = dict_att_max("temperature");

    new_temp_orig = denorm_values(new_temp_norm, tmin, tmax);
else
    new_temp_orig = new_temp_norm;
end

fprintf("\nTemperatura prevista para o novo caso: %.3f C\n", new_temp_orig);
fprintf("Erro medio quadratico no Reuse: %.3f%%\n", ff_error);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3) REVISE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n======================================================\n");
fprintf(" 3) REVISE - Rever/validar a solucao proposta\n");
fprintf("======================================================\n");

fprintf("Nesta fase escolhes qual dos casos devolvidos parece mais adequado.\n");
fprintf("Tambem podes aceitar ou rejeitar a temperatura prevista pelo Reuse.\n\n");

[case_idx, struct_new_case] = revise(retrieved_indexes, struct_new_case, new_temp_orig);

% A classe do novo caso passa a ser a classe do caso escolhido.
struct_new_case.class_cat = string(tabCaseLib_orig{case_idx, "class_cat"});

fprintf("\nCaso escolhido no Revise: %d\n", case_idx);
fprintf("Classe atribuida ao novo caso: %s\n", struct_new_case.class_cat);
fprintf("Novo caso depois do Revise:\n");

disp(struct_new_case);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4) RETAIN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\n======================================================\n");
fprintf(" 4) RETAIN - Guardar o novo caso na base de casos\n");
fprintf("======================================================\n");

path_retain = output_folder_path + ...
    "out_" + type_imput + "_" + type_data + "_datasetTP_with_retained.xlsx";

fprintf("Se aceitares guardar, sera criado este ficheiro:\n");
fprintf("%s\n\n", path_retain);

retain(tabCaseLib_orig, struct_new_case, path_retain);

fprintf("\n======================================================\n");
fprintf(" TP 3.2.a concluido.\n");
fprintf("======================================================\n\n");