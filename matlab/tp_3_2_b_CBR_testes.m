%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP CBR DATASET TESTES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% mostra imagens no ecra? 'on' : 'off'
fig_visibility = 'off';

% nome do ficheiro do dataset de teste
name = "dataset_TP";

% nome da pasta de output
output_folder = "OUTPUT_3.2.b_CBR_TESTS";

% casos de analise
type_imput = ["Median" , "MICE"];  %tipos de imputaçao de fill nans
type_data  = [ "ORIG"  , "NORM"]; %tipos de dados - originais ou normalizados


% 1 temperature
% 2 vibration
% 3 rotation speed
% 4 voltage
% 5 current
% 6 pressure
% 7 noise_level
% 8 efficiency
% 9 load_val
% 10 torque
% 11 maintenance_level
% 12 operating_mode
% 13 cooling_type
% 14 sensor_status
                                %  1   2   3   4   5   6   7   8   9  10   11  12  13  14
weighting_factors = dictionary(  ["1s", "Est", "FS2", "FS3", "soNum", "soCat"]        , ...
                               { [ 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 ]      , ... tudo 1s
                                 [ 5 , 5 , 4 , 2 , 4 , 1 , 3 , 3 , 3 , 3 , 3 , 2 , 2 , 3 ]      , ... pesos estimados
                                 [ 0 , 0 , 0 , 0 , 1 , 0 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ]      , ... Feature Selection 2 
                                 [ 0 , 1 , 0 , 0 , 1 , 0 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ]      , ... Feature Selection 3
                                 [ 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 1 , 0 , 0 , 0 , 0 ]      , ... so numericos
                                 [ 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 1 , 1 , 1 , 1 ]    }); ... so categoricos
                                 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pasta de funcoes
addpath('functions');
retrieve         = @tp_func_retrieve          ;
get_file         = @tp_func_get_xlfile        ;
normalize_values = @tp_func_rescale           ;
denorm_values    = @tp_func_rescale_reverse   ;
categ2cols       = @tp_func_categ2cols        ;
confusion_mat    = @tp_func_confusion_matrix  ;

%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%
clc;
fprintf("\n\nTarefa: TESTE DE CBR --- A Iniciar..\n\n");


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

mkdir(output_folder_path + "Common/")
mkdir(output_folder_path + "Median/")
mkdir(output_folder_path + "MICE/")



%%%%%%%%%%%%%%
% SCRIPT CBR %
%%%%%%%%%%%%%%

% le o dataset de teste para uma tabela/dataframe
wildcard = "*_TRATAM*/Common/*_test_num.xlsx";
ds_file_path = get_file(wildcard);
tabCaseLib_T_base = readtable(ds_file_path);

% usamos sempre o ficheiro sem normalizaçao e aplicamos o rescaling
% utilizando o ficheiro de parametros gerado para cada type_imput

results_lst = struct('config', {}, 'taxa_acerto', {}, 'similaridade_media', {});
inc = 0;
for t_imput = type_imput
    
    % le o ficheiro excel do dataset desejado para dentro de tabCaseLib
    wildcard = "*_TRATAM*/*" + t_imput + "/*_ORIG_*.xlsx";
    ds_file_path = get_file(wildcard);
    tabCaseLib_base = readtable(ds_file_path);

    % se for o normalizado, temos de importar o ficheiro de max e min
    wildcard = "*_TRATAM*/*" + t_imput + "/*_PARAMS_*.mat";
    params_file_path = get_file(wildcard);
    load(params_file_path); % load de dict_att_min e dict_att_max

    for t_data = type_data

        % grava tabelas dos datasets com novo nome para este ciclo, para as
        % proteger as originais de escrita
        tabCaseLib = tabCaseLib_base;
        tabCaseLib_T = tabCaseLib_T_base;

        if t_data == "NORM"
            % rescale dos datasets treino e de teste (apenas att numericos)
            % so os attributos numericos senao da' cabo das matrizes sim
            cols_min = dict_att_min(num_att_cols);
            cols_max = dict_att_max(num_att_cols);
            tabCaseLib{:, num_att_cols} = normalize_values(tabCaseLib{:, num_att_cols}, cols_min, cols_max);
            tabCaseLib_T{:, num_att_cols} = normalize_values(tabCaseLib_T{:, num_att_cols}, cols_min, cols_max);
        end
        
        for t_wf = transpose( keys(weighting_factors) )   
            
            fprintf("Teste CBR para %s - %s - %s\n", t_imput, t_data, t_wf)

            %pesos
            wf = weighting_factors{t_wf};

            % calcular as distâncias locais e a similaridade global para um
            % novo caso e mostrar os casos acima de um limiar
            
            for i = 1:size(tabCaseLib_T,1)

                % devolve casos com similaridade acima do threshold (-Inf aqui)
                %NAO MUDAR THRESHOLD PORQUE SENAO O IDX DEIXA DE CORRESPONDER
                [ ~ , retrieved_simil] = retrieve(tabCaseLib(:,all_vars), tabCaseLib_T(i,all_vars) , -Inf, wf);
                
                % obtem max similaridade e idx da lista devolvida pelo Retrive
                [retrieved_max_simil, retrieved_max_simil_idx] = max(retrieved_simil);
                
                % retorna o valor do target estimado
                predict_target = cell2mat(tabCaseLib{retrieved_max_simil_idx,"class_cat"});

                % Guarda os resultados na linha correspondente da tabela
                % (Usamos string() caso o target original venha como cell array de texto)
                tabCaseLib_T.class_cat_predict{i}  = predict_target; 
                tabCaseLib_T.predict_idx(i)        = retrieved_max_simil_idx;
                tabCaseLib_T.predict_similarity(i) = retrieved_max_simil;

            end
            
            accuracy_mask = string(tabCaseLib_T.class_cat_predict) == string(tabCaseLib_T.class_cat);
            accuracy_ratio = sum(accuracy_mask)./size(accuracy_mask,1) * 100;
            
            sim_max = max(tabCaseLib_T.predict_similarity) *100;
            sim_min = min(tabCaseLib_T.predict_similarity) *100;
            sim_med = mean(tabCaseLib_T.predict_similarity)*100;
            sim_std = std(tabCaseLib_T.predict_similarity) *100;

            fprintf("  Taxa de acerto: \t%.2f%%\n"        , accuracy_ratio);
            fprintf("  Similaridade Maxima: \t\t%.2f%%\n" , sim_max       );
            fprintf("  Similaridade Minima: \t\t%.2f%%\n" , sim_min       );
            fprintf("  Similaridade Media: \t\t%.2f%%\n"  , sim_med       );
            fprintf("  Similaridade DesvPad: \t%.2f%%\n\n", sim_std       );

            path = output_folder_path + t_imput + "/out" + "_" + t_imput + "_"+ t_data + "_" + t_wf + ".xlsx";
            writetable(tabCaseLib_T, path);
            

            config_name = t_imput + "-" + t_data + "-" + t_wf;
            
            inc = inc + 1;
            results_lst(inc).config             = config_name;
            results_lst(inc).taxa_acerto        = accuracy_ratio;
            results_lst(inc).similaridade_media = sim_med;
    

            predict_col = target_col + "_predict";
            [cases_table     , target_outputs] = categ2cols(tabCaseLib_T, target_col );
            [pred_cases_table,       ~       ] = categ2cols(tabCaseLib_T, predict_col);
            
            out_test    = transpose(cases_table{:,target_outputs});
            out_predict = transpose(pred_cases_table{:,target_outputs});

            conf_mat_path = output_folder_path + t_imput + "/plot_confusao_" + "_" + t_imput + "_"+ t_data + "_" + t_wf + ".png" ;
            confusion_mat(out_test, out_predict, target_outputs, conf_mat_path, t_imput + "_"+ t_data + "_" + t_wf);

        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%
% RESUMO DOS RESULTADOS %
%%%%%%%%%%%%%%%%%%%%%%%%%

tab_res_cbr = struct2table(results_lst);
file_name = output_folder_path + "Common/Resumo_Testes_CBR.xlsx";
writetable(tab_res_cbr, file_name);


%%%%%%%%%%%%%%%%%%%%%%%
% PLOT DOS RESULTADOS %
%%%%%%%%%%%%%%%%%%%%%%%
 
fprintf("\nTarefa: GERAR PLOTS --- Atributos vs Target...\n");

data_to_plot = [tab_res_cbr.taxa_acerto, tab_res_cbr.similaridade_media];

fig_cbr = figure('Visible', fig_visibility, 'Position', [100, 100, 1200, 600]); 
b = bar(data_to_plot, 1, 'grouped');

xticks(1:height(tab_res_cbr));
xticklabels(tab_res_cbr.config);
xtickangle(45); 
ylabel('Percentagem [%]', 'FontWeight', 'bold');
ylim([0 100]); 
grid on;

legend({'Taxa de Acerto', 'Similaridade Media'}, 'Location', 'southoutside', 'NumColumns', 2);
grid on;
grid minor;

file_name = output_folder_path + "Common/plot_Resumo_Testes_CBR.png";
exportgraphics(fig_cbr, file_name, 'Resolution', 300);

fprintf("\nTarefa: GERAR PLOTS --- Graficos exportados.\n\n");

fprintf("Tarefa: TESTE DE CBR --- Concluida sem erros.")