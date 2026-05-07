function sim = get_categorical_similarity(simInfo, val1, val2)

    idx1 = find(simInfo.categories == val1, 1);
    idx2 = find(simInfo.categories == val2, 1);

    sim = simInfo.matrix(idx1, idx2);

end