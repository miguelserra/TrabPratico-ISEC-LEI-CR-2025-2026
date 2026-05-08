function reversed_case_lib = tp_func_rescale_reverse(case_lib, cols_min, cols_max)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % USADA PARA CBR - O RESCALE ENTRE 0 e 1 %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    reversed_case_lib = case_lib .* (cols_max - cols_min) + cols_min;

end