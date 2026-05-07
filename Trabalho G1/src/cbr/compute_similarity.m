function simGlobal = compute_similarity(case1, case2, numericVars, categoricalVars, weights, ranges, simMats)

nVars = numel(numericVars) + numel(categoricalVars);

if numel(weights) ~= nVars
    error('O número de pesos não corresponde ao número total de variáveis.');
end

localSims =zeros(1, nVars);
k = 1;

% Similaridade local para atributos numéricos
for i = 1:length(numericVars)
    varName = numericVars{i};
    a = case1.(varName);
    b = case2.(varName);

    rangeValue = ranges.(varName);

    if rangeValue == 0
        sim = 1;
    else
        sim = 1 - abs(a - b) / rangeValue;
        sim  = max(0, sim);
    end

    localSims(k) = sim;
    k = k + 1; % Increment index for localSims
end

% Similaridade local para atributos categóricos com matriz
for j = 1:length(categoricalVars)
    varName = categoricalVars{j};
    a = case1.(varName);
    b = case2.(varName);

    simInfo = simMats.(varName);

    sim = get_categorical_similarity(simInfo,a, b );

    localSims(k) = sim;
    k = k + 1; % Increment index for localSims
end

% Similaridade global
simGlobal = sum(localSims .* weights) / sum(weights);

end