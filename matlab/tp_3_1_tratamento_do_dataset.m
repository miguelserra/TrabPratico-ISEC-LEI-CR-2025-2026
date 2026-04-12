%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fill_nans = @tp_func_fill_nans;
retrieve = @tp_func_retrieve;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTACAO DE DATASET E SETUP INICIAL %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%nome do ficheiro do dataset de treino
name = "dataset_TP";

% le o dataset para uma tabela/dataframe
tabDS = readtable("../DADOS/" + name + ".csv");

% colunas de atributos
all_vars = string(tabDS.Properties.VariableNames);
att_cols = all_vars(1:end-1);
target_col = all_vars(end);

% colunas de atributos do tipo categorico a serem processadas
categorical_att_cols = att_cols(end-3:end);

%prepara pasta de output
time = string(datetime('now', 'Format', 'yyyy-MM-dd_HH.mm')).replace(".","h");
output_folder = "./OUTPUT_" + time + "/";
mkdir(output_folder)
mkdir(output_folder + "Common/")
mkdir(output_folder + "Median/")
mkdir(output_folder + "MICE/")

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

% guarda o dataset com categoricas convertidas para int
writetable(tabDS, output_folder + "Common/out0_" + name + "_num.xlsx");


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

writetable(tabDS_dict{"Median"}, output_folder + "Median/out1_" + name + "_fillattna_median.xlsx");
writetable(tabDS_dict{"MICE"}  , output_folder + "MICE/out1_" + name + "_fillattna_mice.xlsx"  );

fprintf("\n                                       ... concluido!\n");
fprintf(" ######################################################\n\n");

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREENCHE NaNs NA COLUNA DO TARGET %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% preenche NaNs via CBR/Retrieve usando as linhas sem NaNs para determinar
% a similaridade -> mais similar -> copiar target

for tab_name = transpose( keys(tabDS_dict) )

    tabDS2 = tabDS_dict{tab_name};

    % guarda o idx para as operaçoes mais 'a frente na case_lib
    tabDS2.original_idx = transpose(1:size(tabDS2, 1));

    mask_nans = ismissing(tabDS2.(target_col));
    case_lib = tabDS2(~mask_nans, :);
    
    % uma vez criada a case_lib apaga
    tabDS2.original_idx = [];

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
        if ismissing(tabDS2(i,target_col))
    
            fprintf("     CBR/Retrieve - Caso %i... \n", i);
        
            % devolve casos com similaridade acima do threshold (zero aqui)
            [retrieved_idxs, retrieved_simil] = retrieve(case_lib(:,all_vars), tabDS2(i,:) , 0.0, weighting_factors);
    
            % obtem max similaridade e idx da lista devolvida pelo Retrive
            [retrieved_max_simil, retrieved_max_simil_idx] = max(retrieved_simil);
            
            % traduz o idx do resultado para o index do dataset
            % os idxs de case_lib_max_simil_idx = retrieved_max_simil_idx
            % se threshold = 0, diferente de outra forma
            case_lib_max_simil_idx = retrieved_idxs(retrieved_max_simil_idx);
            tabDS2_max_simil_idx = case_lib.original_idx(case_lib_max_simil_idx);
            
            fprintf("     -> Similar com caso %i (sim = %.2f) \n\n", tabDS2_max_simil_idx, retrieved_max_simil);

            % atribui ao target(NaN) o valor do target do caso mais similar
            tabDS2.(target_col){i} = case_lib.(target_col){case_lib_max_simil_idx};
    
        end
    
    end
    
    % guarda tabela do dataset no dicionario
    tabDS_dict{tab_name} = tabDS2;

    writetable(tabDS2, output_folder + tab_name + "/out2" + "_" + name + "_FULLDATA_" + tab_name + ".xlsx");
    
    fprintf("\n #############################################\n\n");
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARA OS DADOS PARA REDES NEURONAIS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Transforma a coluna do target em 3 colunas binarias com o nome de cada
% saida possivel

for tab_name = transpose( keys(tabDS_dict) )

    tabDS2 = tabDS_dict{tab_name};
    
    test = unique(tabDS2{:,target_col});
    target_outputs = flip(string(test));


    for i = 1 : size(target_outputs,1)
        col_name = target_outputs(i);
        tabDS2.(col_name) = double( strcmp( col_name, tabDS2.(target_col) ) );
    end
    
    % elimina a coluna class_cat/target_col
    % tabDS2.(target_col) = [];

    % RESCALING
    % usamos o tabDS2{:, attr_cols} para normalizar apenas os atribrutos
    cols_min  = min(tabDS2{:, att_cols});
    cols_max  = max(tabDS2{:, att_cols});
    tabParams = table(att_cols', cols_min', cols_max', 'VariableNames', {'Attribute', 'Min', 'Max'});

    tabDS2{:, att_cols} = ( tabDS2{:, att_cols} - cols_min ) ./ (cols_max - cols_min);

    % salva as tabelas
    writetable(tabDS2   , output_folder + tab_name + "/out3" + "_" + name + "_FULLDATA_NORM_" + tab_name + ".xlsx");
    writetable(tabParams, output_folder + tab_name + "/out4" + "_" + name + "_NORM_PARAMS_"   + tab_name + ".xlsx")
end