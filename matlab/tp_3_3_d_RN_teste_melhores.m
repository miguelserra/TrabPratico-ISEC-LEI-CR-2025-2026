%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP RN-3BEST DATASET TESTES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% numero de testes por rede
num_reps_nn = 30;

% nome da pasta de output
output_folder = "OUTPUT_3.3.d_RN_3best_VS_ds_teste";


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
accuracy         = @tp_func_accuracy_NN        ;
confusion_mat    = @tp_func_confusion_matrix   ;

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
tabCaseLib = readtable(ds_file_path); %manter nome por causa do tp_3_0_setup_common

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

% muda nome da tabela por razao de legibilidade -> dataset_TP_tests -> _T
tabCaseLib_T_base = tabCaseLib;


%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%
clc;

% Transforma a coluna do target em 3 colunas binarias (num de outputs)
[tabCaseLib_T_base, target_outputs] = categ2cols(tabCaseLib_T_base, target_col);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%$%
% VALIDAÇAO RN-3BEST VS DATSET DE TESTE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1 : height(results_top3)

    curr_case = results_top3{i,:};
    
    [nn_name, net_setup] = curr_case{:};

    disp(nn_name);

    % copia da tabela base
    tabCaseLib_T = tabCaseLib_T_base;

    if net_setup.type_data == "NORM"

        % se for o normalizado, temos de importar o ficheiro de max e min
        wildcard = "*_TRATAM*/*" + net_setup.type_imp + "/*_PARAMS_*.mat";
        params_file_path = get_file(wildcard);
        load(params_file_path); % load de dict_att_min e dict_att_max

        cols_min = dict_att_min(att_cols);
        cols_max = dict_att_max(att_cols);
        tabCaseLib_T{:, att_cols} = normalize_values(tabCaseLib_T{:, att_cols}, cols_min, cols_max);
    
    end

    

    inp_layer_test = transpose( tabCaseLib_T{:,    att_cols   } );
    out_layer_test = transpose( tabCaseLib_T{:, target_outputs} );
    
    out_predict_test = sim(net_setup.net, inp_layer_test);
    
    
    error_test = perform(net_setup.net, out_predict_test, out_layer_test);
    acc_test   = accuracy(out_predict_test, out_layer_test);
    
    neural_network_setup.err_test         = error_test * 100;
    neural_network_setup.acc_test         = acc_test;
    neural_network_setup.out_layer_test   = out_layer_test;
    neural_network_setup.out_predict_test = out_predict_test;

    fprintf('\nErro na classificaçao (fase de teste) = %f\n', error_test)
    fprintf("Precisao total (fase de teste) = %f\n", acc_test)
    
    conf_mat_path = output_folder_path + "/plot_confusao_" + nn_name + "_VS_datasetTP_test.png" ;
    confusion_mat(out_layer_test, out_predict_test, target_outputs, conf_mat_path)


end
