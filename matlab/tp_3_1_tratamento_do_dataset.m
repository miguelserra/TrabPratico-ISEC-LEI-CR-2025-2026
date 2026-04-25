%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fill_nans = @tp_func_fill_nans;
retrieve  = @tp_func_retrieve;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTACAO DE DATASET E SETUP INICIAL %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% nome do ficheiro do dataset de treino
name = "dataset_TP";

% nome da pasta de output
output_folder = "OUTPUT_PREP";

% le o dataset para uma tabela/dataframe
tabDS = readtable("../DADOS/" + name + ".csv");

% le o dataset de teste para uma tabela/dataframe
tabDS_T = readtable("../DADOS/" + name + "_test.csv");


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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONVERSAO DE CATEGORICAS EM INTEGER %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% converte as colunas dos atributos categoricos para valor numerico com
% (de 1 até N valores unico, segundo a ordem na lista)
% este trabalho não e' automatizavel porque temos de definir ordem em pelo
% menos em 2 atributos (categoricos ordenados) -> maintenance_level e operating_mode

tabDS.maintenance_level = double( categorical(tabDS.maintenance_level, {'Low', 'Medium', 'High'} ));
tabDS.operating_mode    = double( categorical(tabDS.operating_mode   , {'Idle', 'Normal', 'Overload'} ));
tabDS.cooling_type      = double( categorical(tabDS.cooling_type     , {'Air', 'Oil'} ));
tabDS.sensor_status     = double( categorical(tabDS.sensor_status    , {'OK', 'Warning'} ));

tabDS_T.maintenance_level = double( categorical(tabDS_T.maintenance_level, {'Low', 'Medium', 'High'} ));
tabDS_T.operating_mode    = double( categorical(tabDS_T.operating_mode   , {'Idle', 'Normal', 'Overload'} ));
tabDS_T.cooling_type      = double( categorical(tabDS_T.cooling_type     , {'Air', 'Oil'} ));
tabDS_T.sensor_status     = double( categorical(tabDS_T.sensor_status    , {'OK', 'Warning'} ));

% guarda o dataset com categoricas convertidas para int
writetable(tabDS, output_folder_path + "Common/out_" + name + "_num.xlsx");
writetable(tabDS_T, output_folder_path + "Common/out_" + name + "_test_num.xlsx");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREENCHE NaNs NAS COLUNAS DOS ATRIBUTOS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% duas abordagens:  1) preenche com medianas;
%                   2) iterativamente via Multivariate Imputation by
%                      Chained Equatiosn (MICE)

ignore_cols = [target_col]; % nao preencher NaNs na coluna do target

fprintf("\n\n ######################################################\n");
fprintf(" >>> A preencher NaNs dos ATRIBUTOS ...\n\n");

tabDS_dict = fill_nans(tabDS, categorical_att_cols, ignore_cols);

writetable(tabDS_dict{"Median"}, output_folder_path + "Median/out1_" + name + "_imputedAtt_median.xlsx");
writetable(tabDS_dict{"MICE"}  , output_folder_path + "MICE/out1_" + name + "_imputedAtt_mice.xlsx"  );

fprintf("\n                                       ... concluido!\n");
fprintf(" ######################################################\n\n");

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREENCHE NaNs NA COLUNA DO TARGET %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% preenche NaNs via CBR/Retrieve usando as linhas sem NaNs para determinar
% a similaridade -> mais similar -> copiar target

disp(tabDS_dict)

for tab_name = transpose( keys(tabDS_dict) )

    tabDS = tabDS_dict{tab_name};
    
    % para esta tarefa e' necessario normalizar os valores numericos antes
    % de os passar ao retrieve
    max_vals = max(tabDS{:,num_att_cols});
    min_vals = min(tabDS{:,num_att_cols});
    ranges   = max_vals - min_vals;
    tabDS{:,num_att_cols} = ( tabDS{:,num_att_cols} - min_vals ) ./ ranges;

    % guarda o idx para as operaçoes mais 'a frente na case_lib
    tabDS.original_idx = transpose(1:size(tabDS, 1));

    mask_nans = ismissing(tabDS.(target_col));
    case_lib = tabDS(~mask_nans, :);
    
    % NAO ESQUECER QUE len(case_lib) < len(tabDS) !!!!
    % POR ISSO E' ESTRITAMENTE NECESSARIO GUARDAR O IDX ORIGINAL ANTES DE
    % APLICAR A MASCARA mask_nans. DE OUTRA FORMA E' IMPOSSIVEL SABER O IDX
    % NA TABELA ORIGINAL tabDS.

    % uma vez criada a case_lib apaga a coluna (auxiliar)
    tabDS.original_idx = [];

    % weighting_factors
    
    % usando so' 1s
    % weighting_factors = ones( size(tabDS,2)-1 );
    
    % outros casos
    weighting_factors = [     ...
                          5 , ... % 1 temperature
                          5 , ... % 2 vibration
                          4 , ... % 3 rotation_speed
                          2 , ... % 4 voltage
                          4 , ... % 5 current
                          1 , ... % 6 pressure
                          3 , ... % 7 noise_level
                          3 , ... % 8 efficiency
                          3 , ... % 9 load_val
                          3 , ... % 10 torque
                          3 , ... % 11 maintenance_level
                          2 , ... % 12 operating_mode
                          2 , ... % 13 cooling_type
                          3 ];... % 14 sensor_status

    fprintf("\n\n ##############################################\n");
    fprintf(" >>> A preencher NaNs do TARGET - tabela %s\n", tab_name);
    fprintf(" ##############################################\n\n");
    
    for i = 1:size(tabDS,1)
        
        % se linha tem NaN no Target
        if ismissing(tabDS(i,target_col))
    
            fprintf("     CBR/Retrieve - Caso %i... \n", i);
        
            % devolve casos com similaridade acima do threshold (zero aqui)
            % case_lib(:,all_vars) nao manda a coluna original_idx para
            % prevenir erro no calculo que
            [retrieved_idxs, retrieved_simil] = retrieve(case_lib(:,all_vars), tabDS(i,:) , 0.0, weighting_factors);
    
            % obtem max similaridade e idx da lista devolvida pelo Retrive
            [retrieved_max_simil, retrieved_max_simil_idx] = max(retrieved_simil);
            
            % traduz o idx do resultado para o index do dataset
            % os idxs de case_lib_max_simil_idx = retrieved_max_simil_idx
            % se threshold = 0, diferente de outra forma
            case_lib_max_simil_idx = retrieved_idxs(retrieved_max_simil_idx);
            tabDS_max_simil_idx = case_lib.original_idx(case_lib_max_simil_idx);
            
            fprintf("     -> Similar com caso %i (sim = %.2f) \n\n", tabDS_max_simil_idx, retrieved_max_simil);

            % atribui ao target(NaN) o valor do target do caso mais similar
            tabDS_dict{tab_name}.(target_col){i} = case_lib.(target_col){case_lib_max_simil_idx};
    
        end
    
    end
    

    writetable(tabDS_dict{tab_name}, output_folder_path + tab_name + "/out2" + "_" + name + "_IMPUTED_ORIG_" + tab_name + ".xlsx");
    
    fprintf("\n #############################################\n\n");
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARA OS DADOS PARA REDES NEURONAIS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Transforma a coluna do target em 3 colunas binarias com o nome de cada
% saida possivel

for tab_name = transpose( keys(tabDS_dict) )

    tabDS = tabDS_dict{tab_name};
    
    test = unique(tabDS{:,target_col});
    target_outputs = flip(string(test));

    for i = 1 : size(target_outputs,1)
        col_name = target_outputs(i);
        tabDS.(col_name) = double( strcmp( col_name, tabDS.(target_col) ) );
    end
    
    % elimina a coluna class_cat/target_col
    % tabDS.(target_col) = [];

    % RESCALING
    % usamos o tabDS{:, attr_cols} para normalizar apenas os atribrutos
    cols_min  = min(tabDS{:, att_cols});
    cols_max  = max(tabDS{:, att_cols});
    
    dictkeys = string(att_cols);
    dict_att_min = dictionary(dictkeys, cols_min);
    dict_att_max = dictionary(dictkeys, cols_max);
    
    tabDS{:, att_cols} = ( tabDS{:, att_cols} - cols_min ) ./ (cols_max - cols_min);

    % salva o dataset e os parametros
    opath = output_folder_path + tab_name;
    writetable(tabDS, opath + "/out3" + "_" + name + "_IMPUTED_NORM_" + tab_name + ".xlsx");
    save(opath + "/out4" + "_" + name + "_NORM_PARAMS_" + tab_name + ".mat", 'dict_att_min', 'dict_att_max');

end

disp("Tarefa: TRATAMENTO DO DATASET --- Concluida sem erros")