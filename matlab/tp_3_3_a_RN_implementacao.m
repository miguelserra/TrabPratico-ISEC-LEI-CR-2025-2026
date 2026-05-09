%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETROS ESTUDO PARAM. DE TREINO REDES NEURONAIS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parametros quanto aos dados de entrada
type_imput = ["Median" , "MICE"]; 
%t_imput   = "MICE"              ; % tipo de imputaçao de fill nans
%type_data = [ "ORIG"  , "NORM"]
t_data = "NORM" ; % tipos de dados - originais ou normalizado

% parametros quanto à topologia das redes neuronais
topology = {10; [5 5]; 6; [3 3]; 14; [7 7]} ;  

% parametros de treino 
training_fun   = ["trainlm", "traingd", "trainbr", "trainscg"];
transf_fun_hid = ["tansig"];
transf_fun_out = ["purelin", "tansig", "logsig", "softmax"];

% proporçoes de treino/validaçao/teste
data_split_proportions = {[0.7 0.15 0.15], [0.6 0.2 0.2], [0.9 0.05 0.05]};

% numero de iteraçoes com erro acima da melhor epoca 
epochs_max_fail = [2, 6, 20];

% numero de repetiçoes por caso
num_reps_nn = 30;

% coef de aprendizagem
%learn_rates = [0.01, 0.05, 0.1]; 
% Nao foi adotada a variacao porque so e' valida para gradient descent

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath('functions');
get_file         = @tp_func_get_xlfile      ;
normalize_values = @tp_func_rescale_2         ;
denorm_values    = @tp_func_rescale_reverse_2 ;
nn_ff            = @tp_func_feedforwardNN   ;
categ2cols       = @tp_func_categ2cols      ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%
clc;
rng('shuffle', 'twister'); % força uma randomizaçao eficaz

fprintf("\n\nTarefa: IMPLEMENTACAO DE REDES NEURONAIS --- A Iniciar..\n\n");

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

% Transforma a coluna do target em 3 colunas binarias (num de outputs)
[tabCaseLib, target_outputs] = categ2cols(tabCaseLib, target_col);


if t_data == "NORM"
    % rescale dos datasets treino e de teste (apenas att numericos)
    % so os attributos numericos senao da' cabo das matrizes sim
    cols_min = dict_att_min(att_cols);
    cols_max = dict_att_max(att_cols);
    tabCaseLib{:,att_cols} = normalize_values(tabCaseLib{:,att_cols}, cols_min, cols_max);
end


nn_case.type_data = t_data;

nn_case.input_layer  = tabCaseLib{:,att_cols};
nn_case.output_layer = tabCaseLib{:,target_outputs};

case_list = {};
for t_imput = type_imput
    nn_case.type_imp = t_imput;

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
    
                        for num_e = epochs_max_fail
                            nn_case.epochs_max_fail = num_e;
                            
                            nn_case.case_name = gen_case_name(nn_case);
                            case_list{end+1} = nn_case;   
    
                        end                      
    
                    end
                end
            end
        end
    end
end



num_cases = length(case_list);
fprintf("\nTotal de configs a testar = %d.\nA iniciar a analise! Aguarde por favor, vai demorar um pouco ...", num_cases);



% paralelizaçao dos fors para acelerar / corre sem toolbox 
results_lst = cell(num_cases, 15);
parfor i = 1:num_cases
    
    curr_nn = case_list{i}; 
    
    % corre caso "num_reps_nn" vezes e calcula as medias
    sum_acc_glob   = 0; sum_acc_test   = 0; 
    sum_err_glob   = 0; sum_err_test   = 0;
    sum_num_epochs = 0; sum_best_epoch = 0;
    sum_tr_time    = 0;

    for n = 1 : num_reps_nn

        curr_nn.rep_num = n;
        
        [nn_ff_out]     = nn_ff(curr_nn, true, false);

        sum_acc_glob   = sum_acc_glob   + nn_ff_out.acc_glob;
        sum_acc_test   = sum_acc_test   + nn_ff_out.acc_test;
        sum_err_glob   = sum_err_glob   + nn_ff_out.err_glob;
        sum_err_test   = sum_err_test   + nn_ff_out.err_test;
        sum_num_epochs = sum_num_epochs + nn_ff_out.num_epochs;
        sum_best_epoch = sum_best_epoch + nn_ff_out.best_epoch; 
        sum_tr_time    = sum_tr_time    + nn_ff_out.tr_time;

    end
    
    % calcula as medias
    avg_acc_glob   =  sum_acc_glob   / num_reps_nn;
    avg_acc_test   =  sum_acc_test   / num_reps_nn;
    avg_err_glob   =  sum_err_glob   / num_reps_nn;
    avg_err_test   =  sum_err_test   / num_reps_nn;
    avg_num_epochs =  sum_num_epochs / num_reps_nn; 
    avg_best_epoch =  sum_best_epoch / num_reps_nn;  
    avg_tr_time    =  sum_tr_time    / num_reps_nn; 
    
    topo_str  = mat2str(curr_nn.topology);
    split_str = mat2str(curr_nn.data_split);
    
    results_lst(i, :) = {                           ...
                            curr_nn.case_name,      ...
                            curr_nn.type_imp,       ...
                            topo_str,               ...
                            curr_nn.training_fun,   ...
                            curr_nn.transf_fun_hid, ...
                            curr_nn.transf_fun_out, ...
                            split_str,              ...
                            curr_nn.epochs_max_fail,...
                            avg_err_glob,           ...
                            avg_err_test,           ...
                            avg_acc_glob,           ...
                            avg_acc_test,           ...
                            avg_num_epochs,         ...
                            avg_best_epoch,         ...
                            avg_tr_time             ...
                        };

end


res_col_names = {'case_name', 'type_imp', 'topology', ...
                 'training_fun', 'transf_fun_hid', 'transf_fun_out', ...
                 'data_split', 'epochs_max_fail',' avg_err_global',  ...
                 'avg_err_test', 'avg_acc_global', 'avg_acc_test',  ...
                 'avg_num_epochs', 'avg_best_epoch', 'avg_tr_time'};
            

tab_results = cell2table(results_lst, 'VariableNames', res_col_names);
file_out = output_folder_path + "Resultados_Estudo_Parametrico.xlsx";
writetable(tab_results, file_out);

fprintf("\n\nEstudo Parametrico concluido e dados exportados com sucesso.\n\n")


params = ["topology", "training_fun", "transf_fun_out", "data_split", "epochs_max_fail"];

for param = params
    
    rotation = 0;
    if param == data_split
        rotation = 15;
    end
    fig = tp_func_group_plot(file_out, param, rotation);
    exportgraphics(fig, output_folder_path + "plot_Acc_MSE_" + xlsx_col + ".png", "Resolution", 300);
    close(fig);

end

fprintf("\n\nEstudo Parametrico concluido e dados exportados com sucesso.\n\n")

function [name] = gen_case_name(nn)

    name = "RN_" + nn.type_imp + "_" + "_Topo";

    for n = nn.topology
        name = name + "-" + n;
    end
    
    name = name + "_" + nn.training_fun;
    name = name + "_" + nn.transf_fun_out;
    name = name + "_MF" + nn.epochs_max_fail + "_Div";

    for n = nn.data_split
        name = name + "-" + n;
    end

end