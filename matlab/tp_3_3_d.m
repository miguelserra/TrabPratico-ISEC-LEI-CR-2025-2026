%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP RN-3BEST DATASET TESTES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% numero de testes por rede
num_reps_nn = 30;

% nome da pasta de output
output_folder = "OUTPUT_3.3.d_RN_3best_DSteste";


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath('functions')
get_file         = @tp_func_get_xlfile         ;
normalize_values = @tp_func_rescale_2          ;
denorm_values    = @tp_func_rescale_reverse_2  ;
nn_ff            = @tp_func_feedforwardNN      ;
categ2cols       = @tp_func_categ2cols         ;


%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%
 
% le o ficheiro das redes neuronais (formato tabela {'case_name', 'net'})
wildcard = "OUTPUT_3.3.b*/RN_3melhores.mat";
results_top3_path = get_file(wildcard);
load(results_top3_path); % results_top3


% le o dataset de teste para uma tabela/dataframe
wildcard = "*_TRATAM*/Common/*_test_num.xlsx";
ds_file_path = get_file(wildcard);
tabCaseLib_T = readtable(ds_file_path);

% se for o normalizado, temos de importar o ficheiro de max e min
wildcard = "*_TRATAM*/*" + t_imput + "/*_PARAMS_*.mat";
params_file_path = get_file(wildcard);
load(params_file_path); % load de dict_att_min e dict_att_max

% prepara as pastas e nomes comuns via script aux
tp_3_0_setup_common;
% neste script ficam definidas as variaveis: 
%       all_vars
%       att_cols
%       target_col
%       num_att_cols
%       categorical_att_cols
%       output_folder_path
%       time



%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%
clc;

% Transforma a coluna do target em 3 colunas binarias (num de outputs)
[tabCaseLib_T, target_outputs] = categ2cols(tabCaseLib_T, target_col);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%$%
% VALIDAÇAO RN-3BEST VS DATSET DE TESTE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

