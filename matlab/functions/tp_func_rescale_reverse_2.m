function reversed_case_lib = tp_func_rescale_reverse_2(case_lib, cols_min, cols_max)

    %%%%%%%%%%%%%%%%%%%%%%%%%
    %  RESCALE ENTRE -1 e 1 %
    %%%%%%%%%%%%%%%%%%%%%%%%%

    reversed_case_lib = ((case_lib + 1) / 2) .* (cols_max - cols_min) + cols_min;

end