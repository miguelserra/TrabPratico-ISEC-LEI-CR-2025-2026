function rescaled_case_lib = tp_func_rescale(case_lib, cols_min, cols_max)

    rescaled_case_lib = (case_lib - cols_min) ./ (cols_max - cols_min);

end