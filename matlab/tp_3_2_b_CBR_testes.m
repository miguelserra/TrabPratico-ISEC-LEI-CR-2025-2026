%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
retrieve = @tp_func_retrieve;
get_file = @tp_func_get_xlfile;

%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%
clc;
fprintf("\n\nTarefa: TESTE DE CBR --- A Iniciar..\n\n");


% nome do ficheiro do dataset de teste
name = "dataset_TP";

% nome da pasta de output
output_folder = "OUTPUT_3.2.b_CBR_TESTS";

% le o dataset de teste para uma tabela/dataframe
wildcard = "*_TRATAM*/Common/*_num.xlsx";
ds_file_path = get_file(wildcard);
tabCaseLib = readtable(ds_file_path);

% le o dataset de teste para uma tabela/dataframe
wildcard = "*_TRATAM*/Common/*_test_num.xlsx";
ds_file_path = get_file(wildcard);
tabCaseLib_T_base = readtable(ds_file_path);

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

mkdir(output_folder_path + "Median/")
mkdir(output_folder_path + "MICE/")

% casos de analise
type_imput = ["Median" , "MICE"];  %tipos de imputaçao de fill nans
type_data  = [ "ORIG"  , "NORM"]; %tipos de dados - originais ou normalizados

weighting_factors = dictionary(  ["w", "w2", "1s" , "soCat"] , ...
                               { [5,5,4,2,4,1,3,3,3,3,3,2,2,3],     ... pesos estimados, w
                                 [25,25,16,4,16,1,9,9,9,9,9,4,4,9], ... w^2
                                 [1,1,1,1,1,1,1,1,1,1,1,1,1,1]    ,... tudo 1s
                                 [0,0,0,0,0,0,0,0,0,0,1,1,1,1]   });... so categoricos
                                 
                                 

%%%%%%%%%%%%%%
% SCRIPT CBR %
%%%%%%%%%%%%%%

% usamos sempre o ficheiro sem normalizaçao e aplicamos o rescaling
% utilizando o ficheiro de parametros gerado para cada type_imput

for t_imput = type_imput
    
    % le o ficheiro excel do dataset desejado para dentro de tabCaseLib
    wildcard = "*_TRATAM*/*" + t_imput + "/*_ORIG_*.xlsx";
    ds_file_path = get_file(wildcard);
    tabCaseLib_base = readtable(ds_file_path);
    
    % grava tabelas dos datasets com novo nome para este ciclo, para as
    % proteger as originais de escrita
    tabCaseLib = tabCaseLib_base;
    tabCaseLib_T = tabCaseLib_T_base;

    % se for o normalizado, temos de importar o ficheiro de max e min
    wildcard = "*_TRATAM*/*" + t_imput + "/*_PARAMS_*.mat";
    params_file_path = get_file(wildcard);
    load(params_file_path); % load de dict_att_min e dict_att_max

    for t_data = type_data

        if t_data == "NORM"
            % rescale dos datasets treino e de teste (apenas att numericos)
            % so os attributos numericos senao da' cabo das matrizes sim
            col_min = dict_att_min(num_att_cols);
            col_max = dict_att_max(num_att_cols);

            tabCaseLib{:, num_att_cols} = (tabCaseLib{:, num_att_cols} - col_min) ./ (col_max - col_min);
            tabCaseLib_T{:, num_att_cols} = (tabCaseLib_T{:, num_att_cols} - col_min) ./ (col_max - col_min);
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
                predict_target = tabCaseLib{retrieved_max_simil_idx,"class_cat"};

                % Guarda os resultados na linha correspondente da tabela
                % (Usamos string() caso o target original venha como cell array de texto)
                tabCaseLib_T.class_cat_predict{i}  = string(predict_target); 
                tabCaseLib_T.predict_idx(i)        = retrieved_max_simil_idx;
                tabCaseLib_T.predict_similarity(i) = retrieved_max_simil;

            end
            
            success_mask = string(tabCaseLib_T.class_cat_predict) == string(tabCaseLib_T.class_cat);
            success_rate = sum(success_mask)./size(success_mask,1)*100;
            sim_max = max(tabCaseLib_T.predict_similarity) *100;
            sim_min = min(tabCaseLib_T.predict_similarity) *100;
            sim_med = mean(tabCaseLib_T.predict_similarity)*100;
            sim_std = std(tabCaseLib_T.predict_similarity) *100;

            fprintf("  Taxa de previsoes corretas: \t%.2f%%\n", success_rate);
            fprintf("  Similaridade Maxima: \t\t%.2f%%\n", sim_max);
            fprintf("  Similaridade Minima: \t\t%.2f%%\n", sim_min);
            fprintf("  Similaridade Media: \t\t%.2f%%\n", sim_med);
            fprintf("  Similaridade DesvPad: \t%.2f%%\n\n", sim_std);

            path = output_folder_path + t_imput + "/out" + "_" + t_imput + "_"+ t_data + "_" + t_wf + ".xlsx";
            writetable(tabCaseLib_T, path);
    

        end
    end
end

disp("Tarefa: TESTE DE CBR --- Concluida sem erros")