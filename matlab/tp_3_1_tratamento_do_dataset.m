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
output_folder = "OUTPUT_3.1_TRATAMENTO";

% le o dataset para uma tabela/dataframe
tabCaseLib = readtable("../DADOS/" + name + ".csv");

% le o dataset de teste para uma tabela/dataframe
tabCaseLib_T = readtable("../DADOS/" + name + "_test.csv");


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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLOT DE ATRIBUTOS VS TARGET %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf("\nTarefa: GERAR PLOTS --- Atributos vs Target...\n");


tabCaseLib_NoNaNs = rmmissing(tabCaseLib);
target_data = categorical(tabCaseLib_NoNaNs.(target_col));
ordem_atual = categories(target_data);
target_data = reordercats(target_data, flip(ordem_atual));

for col_name = att_cols
    
    fig = figure('Visible', 'off', 'Position', [100 100 800 600]); 
    file_name = output_folder_path + "Common/plot_" + col_name + ".png";

    if ismember(col_name, num_att_cols)
        
        boxplot(tabCaseLib_NoNaNs.(col_name), target_data);
        xlabel(strrep(target_col, "_", " "), 'FontWeight', 'bold');
        ylabel(strrep(col_name, "_", " "), 'FontWeight', 'bold');
        grid on;
        
    elseif ismember(col_name, categorical_att_cols)

        att_data = categorical(tabCaseLib_NoNaNs.(col_name));
        freq_matrix = crosstab(att_data, target_data);
        
        labels_att = categories(att_data);
        labels_target = categories(target_data);
        bar(freq_matrix, 'grouped');
        xlabel(strrep(col_name, "_", " "), 'FontWeight', 'bold');
        ylabel('Num. ocorrencias', 'FontWeight', 'bold');
        
        xticklabels(labels_att);
        legend(labels_target, 'Location', 'southoutside', 'NumColumns', 3);
        grid on;
        
    end
    
    
    exportgraphics(fig, file_name, 'Resolution', 300);
    close(fig);
    
    fprintf("     Guardado: %s\n", file_name);
end

fprintf("\nTarefa: GERAR PLOTS --- plots foram exportados com sucesso!\n");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONVERSAO DE CATEGORICAS EM INTEGER %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% converte as colunas dos atributos categoricos para valor numerico com
% (de 1 até N valores unico, segundo a ordem na lista)
% este trabalho não e' automatizavel porque temos de definir ordem em pelo
% menos em 2 atributos (categoricos ordenados) -> maintenance_level e operating_mode

tabCaseLib.maintenance_level = double( categorical(tabCaseLib.maintenance_level, {'Low', 'Medium', 'High'} ));
tabCaseLib.operating_mode    = double( categorical(tabCaseLib.operating_mode   , {'Idle', 'Normal', 'Overload'} ));
tabCaseLib.cooling_type      = double( categorical(tabCaseLib.cooling_type     , {'Air', 'Oil'} ));
tabCaseLib.sensor_status     = double( categorical(tabCaseLib.sensor_status    , {'OK', 'Warning'} ));

tabCaseLib_T.maintenance_level = double( categorical(tabCaseLib_T.maintenance_level, {'Low', 'Medium', 'High'} ));
tabCaseLib_T.operating_mode    = double( categorical(tabCaseLib_T.operating_mode   , {'Idle', 'Normal', 'Overload'} ));
tabCaseLib_T.cooling_type      = double( categorical(tabCaseLib_T.cooling_type     , {'Air', 'Oil'} ));
tabCaseLib_T.sensor_status     = double( categorical(tabCaseLib_T.sensor_status    , {'OK', 'Warning'} ));

% guarda o dataset com categoricas convertidas para int
writetable(tabCaseLib  , output_folder_path + "Common/out_" + name + "_num.xlsx");
writetable(tabCaseLib_T, output_folder_path + "Common/out_" + name + "_test_num.xlsx");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREENCHE NaNs NAS COLUNAS DOS ATRIBUTOS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% duas abordagens:  1) preenche com medianas;
%                   2) iterativamente via Multivariate Imputation by
%                      Chained Equatiosn (MICE)

ignore_cols = [target_col]; % nao preencher NaNs na coluna do target

fprintf("\n\n ######################################################\n");
fprintf(" >>> A preencher NaNs dos ATRIBUTOS ...\n\n");

tabCaseLib_dict = fill_nans(tabCaseLib, categorical_att_cols, ignore_cols);

writetable(tabCaseLib_dict{"Median"}, output_folder_path + "Median/out1_" + name + "_imputedAtt_median.xlsx");
writetable(tabCaseLib_dict{"MICE"}  , output_folder_path + "MICE/out1_" + name + "_imputedAtt_mice.xlsx"  );

fprintf("\n                                       ... concluido!\n");
fprintf(" ######################################################\n\n");

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREENCHE NaNs NA COLUNA DO TARGET %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% preenche NaNs via CBR/Retrieve usando as linhas sem NaNs para determinar
% a similaridade -> mais similar -> copiar target

disp(tabCaseLib_dict)

for tab_name = transpose( keys(tabCaseLib_dict) )

    tabCaseLib = tabCaseLib_dict{tab_name};
    
    % para esta tarefa e' necessario normalizar os valores numericos antes
    % de os passar ao retrieve - metodo rescaling
    max_vals = max(tabCaseLib{:,num_att_cols});
    min_vals = min(tabCaseLib{:,num_att_cols});
    ranges   = max_vals - min_vals;
    tabCaseLib{:,num_att_cols} = ( tabCaseLib{:,num_att_cols} - min_vals ) ./ ranges;

    % guarda o idx para as operaçoes mais 'a frente na case_lib
    tabCaseLib.original_idx = transpose(1:size(tabCaseLib, 1));

    mask_nans = ismissing(tabCaseLib.(target_col));
    case_lib = tabCaseLib(~mask_nans, :);
    
    % NAO ESQUECER QUE len(case_lib) < len(tabCaseLib) !!!!
    % POR ISSO E' ESTRITAMENTE NECESSARIO GUARDAR O IDX ORIGINAL ANTES DE
    % APLICAR A MASCARA mask_nans. DE OUTRA FORMA E' IMPOSSIVEL SABER O IDX
    % NA TABELA ORIGINAL tabCaseLib.

    % uma vez criada a case_lib apaga a coluna (auxiliar)
    tabCaseLib.original_idx = [];

    % weighting_factors
    
    % usando so' 1s
    % weighting_factors = ones( size(tabCaseLib,2)-1 );
    
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
    
    for i = 1:size(tabCaseLib,1)
        
        % se linha tem NaN no Target
        if ismissing(tabCaseLib(i,target_col))
    
            fprintf("     CBR/Retrieve - Caso %i... \n", i);
        
            % devolve casos com similaridade acima do threshold (zero aqui)
            % case_lib(:,all_vars) nao manda a coluna original_idx para
            % prevenir erro no calculo que
            [retrieved_idxs, retrieved_simil] = retrieve(case_lib(:,all_vars), tabCaseLib(i,:) , 0.0, weighting_factors);
    
            % obtem max similaridade e idx da lista devolvida pelo Retrive
            [retrieved_max_simil, retrieved_max_simil_idx] = max(retrieved_simil);
            
            % traduz o idx do resultado para o index do dataset
            % os idxs de case_lib_max_simil_idx = retrieved_max_simil_idx
            % se threshold = 0, diferente de outra forma
            case_lib_max_simil_idx = retrieved_idxs(retrieved_max_simil_idx);
            tabCaseLib_max_simil_idx = case_lib.original_idx(case_lib_max_simil_idx);
            
            fprintf("     -> Similar com caso %i (sim = %.2f) \n\n", tabCaseLib_max_simil_idx, retrieved_max_simil);

            % atribui ao target(NaN) o valor do target do caso mais similar
            tabCaseLib_dict{tab_name}.(target_col){i} = case_lib.(target_col){case_lib_max_simil_idx};
    
        end
    
    end
    

    writetable(tabCaseLib_dict{tab_name}, output_folder_path + tab_name + "/out2" + "_" + name + "_IMPUTED_ORIG_" + tab_name + ".xlsx");
    
    fprintf("\n #############################################\n\n");
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARA NORMALIZAÇAO %
%%%%%%%%%%%%%%%%%%%%%%%%


for tab_name = transpose( keys(tabCaseLib_dict) )

    tabCaseLib = tabCaseLib_dict{tab_name};

    % RESCALING
    % calculo dos parametros de rescaling (min e max de cada coluna)
    cols_min  = min(tabCaseLib{:, att_cols});
    cols_max  = max(tabCaseLib{:, att_cols});
    
    dictkeys = string(att_cols);
    dict_att_min = dictionary(dictkeys, cols_min);
    dict_att_max = dictionary(dictkeys, cols_max);
    
    % salva os parametros de normalização
    outfilepath = output_folder_path + tab_name + "/out4" + "_" + name + "_NORM_PARAMS_" + tab_name + ".mat";
    save(outfilepath , 'dict_att_min', 'dict_att_max');

end

disp("Tarefa: TRATAMENTO DO DATASET --- Concluida sem erros")

