
tabledf = readtable('../dataset_TP_num.xlsx');

arr_subsets_cols = table2array(readtable('lista_subsets.xlsx'));

for i = 1:length(arr_subsets_cols)
    
    col_names = arr_subsets_cols(i,:);
    col_names(col_names == "") = []; %remove posiçoes do col_namesay "vazias"
    
    output_file = col_names(1) + ".xlsx";

    criar_sub_dataset(tabledf, col_names, output_file)
    
end
    


