function [ranges, simMats] = prepare_cbr_metadata(engineData, numericVars)

    ranges = get_ranges(engineData, numericVars);

    simMats = get_similarity_matrices();
end