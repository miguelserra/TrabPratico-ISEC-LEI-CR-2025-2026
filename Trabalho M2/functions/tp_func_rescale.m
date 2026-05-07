function rescaled_case_lib = tp_func_rescale(case_lib, cols_min, cols_max)

    ranges = cols_max - cols_min;
    ranges(ranges == 0) = 1; % evita divisao por zero em colunas constantes
    rescaled_case_lib = (case_lib - cols_min) ./ ranges;

end
