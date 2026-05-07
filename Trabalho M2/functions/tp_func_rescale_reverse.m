function reversed_case_lib = tp_func_rescale_reverse(case_lib, cols_min, cols_max)

    ranges = cols_max - cols_min;
    ranges(ranges == 0) = 1;
    reversed_case_lib = case_lib .* ranges + cols_min;

end
