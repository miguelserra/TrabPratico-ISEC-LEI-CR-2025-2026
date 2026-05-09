%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETROS ESTUDO PARAM. DE TREINO REDES NEURONAIS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parametros quanto aos dados de entrada
%type_imput = ["Median" , "MICE"]; 
t_imput   = "MICE"              ; % tipo de imputaçao de fill nans
type_data = [ "ORIG"  , "NORM"];

num_reps_nn = 30;

% nome da pasta de output
output_folder = "OUTPUT_3.3.b_c_RN_ORIGvsNORM_3best";

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
confusion_mat    = @tp_func_confusion_matrix   ;


%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%
clc;
rng('shuffle', 'twister'); % força uma randomizaçao eficaz
 
% le o ficheiro excel do dataset desejado para dentro de tabCaseLib
wildcard = "*_TRATAM*/*" + t_imput + "/*_ORIG_*.xlsx";
ds_file_path = get_file(wildcard);
tabCaseLib = readtable(ds_file_path);

% se for o normalizado, temos de importar o ficheiro de max e min
wildcard = "*_TRATAM*/*" + t_imput + "/*_PARAMS_*.mat";
params_file_path = get_file(wildcard);
load(params_file_path); % load de dict_att_min e dict_att_max

% le o ficheiro excel dos resultados do estudo parametrico
wildcard = "OUTPUT_3.3.a*/Resultados_Estudo_Parametrico.xlsx";
nn_res_file_path = get_file(wildcard);
tabResultsNN = readtable(nn_res_file_path);

% prepara as pastas e nomes comuns via script aux
tp_3_0_setup_common;

% Transforma a coluna do target em 3 colunas binarias (num de outputs)
[tabCaseLib_base, target_outputs] = categ2cols(tabCaseLib, target_col);

% ordena a lista de resultados do maior para menor precisao e, como
% criterio de desempate, do erro (MSE) menor para o maior obtendo-se assim
% a tabela tab_results_sorted
tab_results_sorted = sortrows(tabResultsNN, {'avg_acc_test', 'avg_err_test'}, {'descend', 'ascend'});

% extrai os 3 melhores e os 3 piores e anota a sua classificaçao
neural_networks_topScorers = tab_results_sorted(1:3, :);
neural_networks_botScorers = tab_results_sorted(end-2:end, :);

% mapeia uma coluna a dizer de é top ou bot scorer
neural_networks_topScorers.rank = repmat("topScorer", 3, 1);
neural_networks_botScorers.rank = repmat("botScorer", 3, 1);

% combina numa tabela unica
neural_networks = [neural_networks_topScorers; neural_networks_botScorers];

% corrige a importaçao do array que em formato string
neural_networks.topology   = cellfun(@str2num, neural_networks.topology, 'UniformOutput', false);
neural_networks.data_split = cellfun(@str2num, neural_networks.data_split, 'UniformOutput', false);


%%%%%%%%%%%%%%%%%%%%%
% INICIO DA ANALISE %
%%%%%%%%%%%%%%%%%%%%%

fprintf("\n\nTarefa: REDES NEURONAIS ORIG vs NORM --- A Iniciar..\n\n");


case_list = {};
for i = 1:height(neural_networks)

    nn_case = table2struct(neural_networks(i, :));

    for t_data = type_data
        nn_case.type_data = t_data;
        case_list{end+1} = nn_case; 
    end

end

num_cases = length(case_list);
results_lst = cell(num_cases, 15);
net_lst = cell(num_cases, 1);

for i = 1 : num_cases
    
    curr_nn = case_list{i}; 

    tabCaseLib = tabCaseLib_base; % trabalha sobre copia do dataset

    if curr_nn.type_data == "NORM"
        cols_min = dict_att_min(att_cols);
        cols_max = dict_att_max(att_cols);
        tabCaseLib{:, att_cols} = normalize_values(tabCaseLib{:, att_cols}, cols_min, cols_max);
    end

    curr_nn.input_layer  = tabCaseLib{:,att_cols};
    curr_nn.output_layer = tabCaseLib{:,target_outputs};

    sum_acc_test   = 0; 
    sum_err_test   = 0;
    sum_num_epochs = 0;
    sum_best_epoch = 0;
    sum_tr_time    = 0;

    best_acc_nn = -Inf;
    best_nn = [];
    for n = 1 : num_reps_nn

        curr_nn.rep_num = n;

        [nn_ff_out] = nn_ff(curr_nn, true, false);
        
        sum_acc_test   = sum_acc_test   + nn_ff_out.acc_test;
        sum_err_test   = sum_err_test   + nn_ff_out.err_test; 
        sum_num_epochs = sum_num_epochs + nn_ff_out.num_epochs;
        sum_best_epoch = sum_best_epoch + nn_ff_out.best_epoch; 
        sum_tr_time    = sum_tr_time    + nn_ff_out.tr_time;

        % guarda a repetiçao da rede com menor erro MSE
        if nn_ff_out.acc_test > best_acc_nn
            best_acc_nn = nn_ff_out.acc_test;
            best_nn = nn_ff_out;
        end
    end

    net_lst{i} = best_nn;

    % calcula as medias
    avg_acc_test   = sum_acc_test   / num_reps_nn;
    avg_err_test   = sum_err_test   / num_reps_nn;
    avg_num_epochs = sum_num_epochs / num_reps_nn; 
    avg_best_epoch = sum_best_epoch / num_reps_nn;  
    avg_tr_time    = sum_tr_time    / num_reps_nn; 
    
    topo_str  = mat2str(curr_nn.topology);
    split_str = mat2str(curr_nn.data_split);
    
    results_lst(i, :) = { curr_nn.rank,             ...
                          curr_nn.case_name,      ...
                          curr_nn.type_imp,       ...
                          curr_nn.type_data,      ...
                          topo_str,               ...
                          curr_nn.training_fun,   ...
                          curr_nn.transf_fun_hid, ...
                          curr_nn.transf_fun_out, ...
                          split_str,              ...
                          curr_nn.epochs_max_fail,...
                          avg_err_test,           ...
                          avg_acc_test,           ...
                          avg_num_epochs,         ...
                          avg_best_epoch,         ...
                          avg_tr_time             ...
                        };


    conf_mat_path = output_folder_path + "/plot_confusao_" + curr_nn.rank + "_" ...
                    + curr_nn.case_name + "_" + curr_nn.type_data +  ".png" ;

    confusion_mat(  best_nn.out_layer_test, best_nn.out_predict_test,...
                    target_outputs, conf_mat_path)


end




res_col_names = {'rank', 'case_name', 'type_imp', 'type_data', 'topology', ...
                 'training_fun', 'transf_fun_hid', 'transf_fun_out', ...
                 'data_split', 'epochs_max_fail', 'avg_err_test', 'avg_acc_test', ...
                 'avg_num_epochs', 'avg_best_epoch', 'avg_tr_time'};


tab_results = cell2table(results_lst, 'VariableNames', res_col_names);
file_out = output_folder_path + "Resultados_Comparativo_ORIGvsNORM.xlsx";
writetable(tab_results, file_out);


fprintf("\n\nTarefa: REDES NEURONAIS ORIG vs NORM --- Concluida!\n\n");

tab_results.net = net_lst;
tab_results_sorted = sortrows(tab_results, {'avg_acc_test', 'avg_err_test'}, {'descend', 'ascend'});
results_top3 = tab_results_sorted(1:3, {'case_name', 'net'});
file_out = output_folder_path + "RN_3melhores.mat";
save(file_out, 'results_top3');

fprintf("\nTarefa: GRAVAÇAO DAS 3 MELHORES --- Guardado em %s\n\n", file_out);