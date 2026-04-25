%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

retrieve = @tp_func_retrieve;
reuse    = @tp_func_reuse;
revise   = @tp_func_revise;
retain   = @tp_func_retain;

%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%

% nome do ficheiro do dataset de teste
name = "dataset_TP_test";

% nome da pasta de output
output_folder = "OUTPUT_CBR";

% le o dataset de teste para uma tabela/dataframe
tabDS_T_base = readtable("../DADOS/" + name + ".csv");

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

% casos de analise
type_imput = ["Median" , "MICE"];  %tipos de imputaçao de fill nans
type_data  = [ "ORIG"  , "NORM"]; %tipos de dados - originais ou normalizados



%%%%%%%%%%%%%%
% SCRIPT CBR %
%%%%%%%%%%%%%%

for t_imput = type_imput
    for t_data = type_data
        
        % grava com novo nome para podermos fazer as modificaçoes em
        % segurança (normalizaçao, por exemplo)

        tabDS_T = tabDS_T_base;
        
        wildcard = "*/*" + t_imput + "/*_" + t_data + "_*.xlsx";
        ds_file_path = tp_func_get_xlfile(wildcard);
        
        tabDS = readtable(ds_file_path);
        
        % se for o normalizado, temos de importar o ficheiro de max e min
        % de cada coluna e usa-lo para normalizar o tabDS_T
        if t_data == "NORM"
            wildcard = "*/*" + t_imput + "/*_PARAMS_*.xlsx";
            params_file_path = tp_func_get_xlfile(wildcard);
            tabParams = readtable(params_file_path);

            col_min      = tabParams{num_att_cols, 'Min'}';
            col_max      = tabParams{num_att_cols, 'Max'}';
            cols_num_att = tabDS_T{:, num_att_cols};

            % rescale do dataset de teste (apenas att numericos)
            tabDS_T{:, num_att_cols} = (cols_num_att - col_min) ./ (col_max - col_min);

        end

        % calcular as distâncias locais e a similaridade global para um novo caso e mostrar os casos acima de um limiar
        
        
    
    end
end



function [] = cbr_testing(test_case, dataset, weighting_factors)
    
    % devolve casos com similaridade acima do threshold (zero aqui)
    [retrieved_idxs, retrieved_simil] = retrieve(dataset, test_case , 0.0, weighting_factors);
    
    % obtem max similaridade e idx da lista devolvida pelo Retrive
    [retrieved_max_simil, retrieved_max_simil_idx] = max(retrieved_simil);
    
    return
    

end