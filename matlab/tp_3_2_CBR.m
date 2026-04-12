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


%%%%%%%%%%%%%%%%%%%%%%%%%%
% IMPORTACAO DE DATASETS %
%%%%%%%%%%%%%%%%%%%%%%%%%%

datasets_names = ["Median" , "MICE"];
dataset_types  = ["FULLDATA_", "FULLDATA_NORM_"];

for name = datasets_names
    for type = dataset_types
    
        input_file_path = 
        tabDS = readtable("../DADOS/" + name + ".csv");
    
    end
end



function [] = cbr(tab_case_lib, arr_weights, str_case_name)
    
     

end