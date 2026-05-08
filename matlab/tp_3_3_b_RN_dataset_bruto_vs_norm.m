%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETROS ESTUDO PARAM. DE TREINO REDES NEURONAIS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parametros quanto aos dados de entrada
%type_imput = ["Median" , "MICE"]; 
t_imput   = "MICE"              ; % tipo de imputaçao de fill nans
type_data = [ "ORIG"  , "NORM"];

num_reps_nn = 30;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath('functions')
get_file         = @tp_func_get_xlfile      ;
normalize_values = @tp_func_rescale_2         ;
denorm_values    = @tp_func_rescale_reverse_2 ;
nn_ff            = @tp_func_feedforwardNN   ;
categ2cols       = @tp_func_categ2cols      ;

%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%
clc;
rng('shuffle', 'twister'); % força uma randomizaçao eficaz

% nome da pasta de output
output_folder = "OUTPUT_3.3.b_RN_ORIGvsNORM";
 
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
tab_results_sorted = sortrows(tabResultsNN, {'avg_acc_test', 'avr_err_test'}, {'descend', 'ascend'});

% extrai os 3 melhores e os 3 piores e anota a sua classificaçao
neural_networks_topScorers = tab_results_sorted(1:3, :);
neural_networks_botScorers = tab_results_sorted(end-2:end, :);

neural_networks_topScorers.rank = repmat("topScorer", 3, 1);
neural_networks_botScorers.rank = repmat("botScorer", 3, 1);

% combina numa tabela unica
neural_networks = [neural_networks_topScorers; neural_networks_botScorers];

% neural_networks = neural_networks(:,col_names);
neural_networks.topology   = cellfun(@str2num, neural_networks.topology, 'UniformOutput', false);
neural_networks.data_split = cellfun(@str2num, neural_networks.data_split, 'UniformOutput', false);


%%%%%%%%%%%%%%%%%%%%%
% INICIO DA ANALISE %
%%%%%%%%%%%%%%%%%%%%%

fprintf("\n\nTarefa: REDES NEURONAIS ORIG vs NORM --- A Iniciar..\n\n");

num_cases = size(neural_networks, 1) * 2; % (3 + 3) 'casos' * 2 'orig/norm'
results_lst = cell(num_cases, 17);
idx = 0;

for i = 1:height(neural_networks)
    
    nn_case = table2struct(neural_networks(i, :));

    for t_data = type_data
        

        tabCaseLib = tabCaseLib_base; % trabalha sobre copia do dataset

        if t_data == "NORM"
            cols_min = dict_att_min(att_cols);
            cols_max = dict_att_max(att_cols);
            tabCaseLib{:, att_cols} = normalize_values(tabCaseLib{:, att_cols}, cols_min, cols_max);
        end
    
        nn_case.input_layer  = tabCaseLib{:,att_cols};
        nn_case.output_layer = tabCaseLib{:,target_outputs};


        sum_acc_glob   = 0; sum_acc_test   = 0; 
        sum_err_glob   = 0; sum_err_test   = 0;
        sum_num_epochs = 0; sum_best_epoch = 0;
        sum_tr_time    = 0;

        best_err_nn = Inf;
        best_nn = [];
        for n = 1 : num_reps_nn
            nn_case.rep_num = n;
            [nn_ff_out] = nn_ff(nn_case, true, false);
            sum_acc_test = sum_acc_test + nn_ff_out.acc_test;
            sum_err_test = sum_err_test + nn_ff_out.err_test; 

            % guarda a repetiçao da rede com menor erro MSE
            if nn_ff_out.err_test < best_err_nn
                best_err_nn = nn_ff_out.err_test;
                best_nn = nn_ff_out;
            end
        end


        % calcula as medias
        avg_acc_test = sum_acc_test / num_reps_nn;
        avg_err_test = sum_err_test / num_reps_nn;
        
        topo_str  = mat2str(nn_case.topology);
        split_str = mat2str(nn_case.data_split);
        
        
        idx = idx + 1;
        results_lst(idx, :) = { nn_case.rank,             ...
                                nn_case.case_name,      ...
                                nn_case.type_imp,       ...
                                nn_case.type_data,      ...
                                topo_str,               ...
                                nn_case.training_fun,   ...
                                nn_case.transf_fun_hid, ...
                                nn_case.transf_fun_out, ...
                                nn_case.max_fail,     ...
                                split_str,              ...
                                avg_err_glob,           ...
                                avg_err_test,           ...
                                avg_acc_glob,           ...
                                avg_acc_test,           ...
                                avg_num_epochs,         ...
                                avg_best_epoch,         ...
                                avg_tr_time             ...
                            };


        fig_conf = plotconfusion(best_nn.out_layer_test, best_nn.out_predict_test); 
        conf_mat_path = output_folder_path + "/plot_confusao_" + nn_case.rank + "_" + nn_case.case_name + "_" + t_data +  ".png" ;
        exportgraphics(fig_conf, conf_mat_path, 'Resolution', 300);
        close(fig_conf);

    end

end


res_col_names = {'case_name', 'type_imp', 'type_data', 'topology', ...
                 'training_fun', 'transf_fun_hid', 'transf_fun_out', ...
                 'data_split', 'epochs_max_fail',' avg_err_global',  ...
                 'avr_err_test', 'avg_acc_global', 'avg_acc_test',  ...
                 'avg_num_epochs', 'avg_best_epoch', 'avg_tr_time'};
            

tab_results = cell2table(results_lst, 'VariableNames', res_col_names);
file_out = output_folder_path + "Resultados_Comparativo_ORIGvsNORM.xlsx";
writetable(tab_results, file_out);


fprintf("\n\nTarefa: REDES NEURONAIS ORIG vs NORM --- Concluida!\n\n");