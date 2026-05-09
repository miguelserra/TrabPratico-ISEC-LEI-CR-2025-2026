function rescaled_case_lib = tp_func_rescale_2(case_lib, cols_min, cols_max)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % USADA PARA AS REDES NEURONAIS ENTRE FAZENDO O RESCALE ENTRE -1 e 1 %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    rescaled_case_lib = 2 * (case_lib - cols_min) ./ (cols_max - cols_min) - 1 ;

end