%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

retrieve = @tp_func_retrieve;

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
type_data  = [ "ORIG"  , "NORM"]; %tipos de dados - originais ou normalizados

type_imput = ["Median" , "MICE"];  %tipos de imputaçao de fill nans

weighting_factors = dictionary(  ["w", "w2", "1s"] , ...
                               { [5,5,4,2,4,1,3,3,3,3,3,2,2,3],     ... pesos estimados, w
                                 [25,25,16,4,16,1,9,9,9,9,9,4,4,9], ... w^2
                                 [1,1,1,1,1,1,1,1,1,1,1,1,1,1]   });... tudo 1s
                                  


%%%%%%%%%%%%%%
% SCRIPT CBR %
%%%%%%%%%%%%%%

for t_data = type_data

    % grava tabela do dataset de teste com novo nome para este ciclo
    tabDS_T = tabDS_T_base;
    
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

    for t_imput = type_imput

        % le o ficheiro excel do dataset desejado para dentro de tabDS
        wildcard = "*/*" + t_imput + "/*_" + t_data + "_*.xlsx";
        ds_file_path = tp_func_get_xlfile(wildcard);
        tabDS = readtable(ds_file_path);

        for t_wf = transpose( keys(weighting_factors) )   
           
            %pesos
            wf = weighting_factors{t_wf};

            % calcular as distâncias locais e a similaridade global para um
            % novo caso e mostrar os casos acima de um limiar
            tabDS_T.("class_cat_predict") = cbr_testing(tabDS_T, tabDS, wf);

        end
    end
end



function [target_val] = cbr_testing(test_case, dataset, weighting_factors)
    
    % devolve casos com similaridade acima do threshold (zero aqui)
    %NAO MUDAR THRESHOLD PORQUE SENAO O IDX DEIXA DE CORRESPONDER
    [retrieved_idxs, retrieved_simil] = retrieve(dataset, test_case , 0.0, weighting_factors);
    
    % obtem max similaridade e idx da lista devolvida pelo Retrive
    [retrieved_max_simil, retrieved_max_simil_idx] = max(retrieved_simil);
    
    % retorna o valor do target estimado
    target_val = dataset.class_cat{retrieved_max_simil_idx};

end