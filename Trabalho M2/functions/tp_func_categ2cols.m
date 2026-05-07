function [cases_table, target_outputs] = tp_func_categ2cols(cases_table, target_col)

    % Transforma a coluna do target em 3 colunas binarias 
    unique_outputs = unique(cases_table{:,target_col});
    target_outputs = flip(string(unique_outputs));
    for col_name = transpose(target_outputs)
        cases_table.(col_name) = double( strcmp( col_name, cases_table.(target_col) ) );
    end
    
    % elimina a coluna class_cat/target_col
    cases_table.(target_col) = [];

end