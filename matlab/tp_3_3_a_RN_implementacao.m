%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETROS ESTUDO PARAM. DE TREINO REDES NEURONAIS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parametros quanto aos dados de entrada
%type_imput = ["Median" , "MICE"]; 
t_imput   = "MICE"              ; % tipo de imputaçao de fill nans
%type_data = [ "ORIG"  , "NORM"]
t_data = "NORM" ; % tipos de dados - originais ou normalizado

% parametros quanto à topologia das redes neuronais
topology = {10; [5 5]; 6; [3 3]; 12; [6 6]; [4 4 4]} ;  

% parametros de treino 
training_fun   = ["trainlm", "trainbfg", "traingd"];
transf_fun_hid = ["poslin" , "logsig"  , "tansig"];
transf_fun_out = ["purelin", "logsig" ];

% proporçoes de treino/validaçao/teste
data_split_proportions = {[0.7 0.15 0.15], [0.7 0.2 0.1], [0.9 0.05 0.05]};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_file         = @tp_func_get_xlfile      ;
normalize_values = @tp_func_rescale         ;
denorm_values    = @tp_func_rescale_reverse ;
nn_ff            = @tp_func_feedforwardNN   ;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%
clc;
fprintf("\n\nTarefa: IMPLEMENTACAO DE REDES NEURONAIS --- A Iniciar..\n\n");

% nome do ficheiro do dataset de teste
name = "dataset_TP";

% nome da pasta de output
output_folder = "OUTPUT_3.3.a_RN_IMPL";


%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
%&&&  ARRANQUE DO ESTUDO PARAMETRICO   &&&
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

% le o ficheiro excel do dataset desejado para dentro de tabCaseLib
wildcard = "*_TRATAM*/*" + t_imput + "/*_ORIG_*.xlsx";
ds_file_path = get_file(wildcard);
tabCaseLib = readtable(ds_file_path);

% se for o normalizado, temos de importar o ficheiro de max e min
wildcard = "*_TRATAM*/*" + t_imput + "/*_PARAMS_*.mat";
params_file_path = get_file(wildcard);
load(params_file_path); % load de dict_att_min e dict_att_max

% prepara as pastas e nomes comuns via script aux
tp_3_0_setup_common;
% neste script ficam definidas as variaveis: 
%       tabCaseLib
%       tabCaseLib_T_base
%       all_vars
%       att_cols
%       target_col
%       num_att_cols
%       categorical_att_cols
%       output_folder_path
%       time

% Transforma a coluna do target em 3 colunas binarias 
unique_outputs = unique(tabCaseLib{:,target_col});
target_outputs = flip(string(unique_outputs));
for col_name = transpose(target_outputs)
    tabCaseLib.(col_name) = double( strcmp( col_name, tabCaseLib.(target_col) ) );
end

% elimina a coluna class_cat/target_col
tabCaseLib.(target_col) = [];


if t_data == "NORM"
    % rescale dos datasets treino e de teste (apenas att numericos)
    % so os attributos numericos senao da' cabo das matrizes sim
    cols_min = dict_att_min(att_cols);
    cols_max = dict_att_max(att_cols);
    tabCaseLib{:,att_cols} = normalize_values(tabCaseLib{:,att_cols}, cols_min, cols_max);
end

nn_case.type_imp = t_imput;
nn_case.type_data = t_data;

nn_case.input_layer  = tabCaseLib{:,att_cols};
nn_case.output_layer = tabCaseLib{:,target_outputs};

results_lst = {};
results_idx = 0; %incrementada antes de ser usada
for topo = transpose(topology)
    nn_case.topology = cell2mat(topo);

    for trainf = training_fun
        nn_case.training_fun = trainf;

        for transffHid = transf_fun_hid
            nn_case.transf_fun_hid = transffHid;

            for transffOut = transf_fun_out
                nn_case.transf_fun_out = transffOut;
                
                for proportions = data_split_proportions
                    nn_case.data_split = cell2mat(proportions);
                    
                    nn_case.case_name = gen_case_name(nn_case);
                    
                    sum_acc_val = 0;
                    sum_acc_test = 0;
                    num_runs = 10;
                    for i = 1 : num_runs
                        nn_case.num_run = i;
                        [~, acc_val, acc_test] = nn_ff(nn_case, true, false);
                        sum_acc_val = sum_acc_val + acc_val;
                        sum_acc_test = sum_acc_test + acc_test;
                    end

                    avg_acc_val = sum_acc_val / num_runs;
                    avg_acc_test = sum_acc_test / num_runs;
                    
                    % escreve numa tabelea os resultados
                    topo_str = mat2str(nn_setup.topology);
                    split_str = mat2str(nn_setup.data_split);

                    results_idx = results_idx + 1;
                    results_lst(results_idx, :) = {   ...
                                                        nn_setup.case_name, ...
                                                        nn_setup.type_imp, ...
                                                        nn_setup.type_data, ...
                                                        topo_str, ...
                                                        nn_setup.training_fun, ...
                                                        nn_setup.transf_fun_hid, ...
                                                        nn_setup.transf_fun_out, ...
                                                        split_str, ...
                                                        avg_acc_val, ...
                                                        avg_acc_test ...
                                                     };
                    
                    
                end
            end
        end
    end

end

res_col_names = {'Case_Name', 'Imputacao', 'Dados', 'Topologia', ...
                 'Treino_Func', 'Transf_Hid', 'Transf_Out', ...
                 'Divisao_Dados', 'Media_Acc_Validacao', 'Media_Acc_Teste'};
            

tab_results = cell2table(results_lst, 'VariableNames', res_col_names);
excel_out = output_folder_path + "Resultados_Estudo_Parametrico.xlsx";
writetable(tab_results, ficheiro_excel_out);

fprintf("\n\nEstudo Parametrico concluido e dados exportados com sucesso.\n\n")


function [name] = gen_case_name(nn)

    name = "RN_" + nn.type_imp + "_" + nn.type_data + "_Topo";

    for n = nn.topology
        name = name + "-" + n;
    end
    
    name = name + "_Train-" + nn.training_fun;

    name = name + "_TransfHid-" + nn.transf_fun_hid;

    name = name + "_TransfOut-" + nn.transf_fun_out + "_Prop";
    
    %proportions
    for n = nn.data_split
        name = name + "-" + n;
    end
end