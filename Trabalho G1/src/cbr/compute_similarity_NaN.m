function simGlobal = compute_similarity_NaN(case1, case2, numericVars, categoricalVars, weights, ranges)
%«Inicialize sum of med ponderada
weightedSumSim=0;
totalWeightsUsed=0;

% Similaridade local para atributos numéricos
for i = 1:length(numericVars)
    varName = numericVars{i};
    a = case1.(varName);
    b = case2.(varName);
    w=weights(i);
    if ~isnan(a) && ~isnan(b)
        rangeValue = ranges.(varName);

        if rangeValue == 0
            sim = 1;
        else
            sim = 1 - abs(a - b) / rangeValue;
        end
        weightedSumSim= weightedSumSim+(sim*w);
        totalWeightsUsed= totalWeightsUsed+w;
    end
end


% Similaridade local para atributos categóricos
offset=length(numericVars); % Para saltar os pesos das numéricas
for j = 1:length(categoricalVars)
    varName = categoricalVars{j};
    a = case1.(varName);
    b = case2.(varName);
    w=weights(offset+j);
    if ~isnan(a) && ~isnan(b)
        sim = double(a == b);
        weightedSumSim= weightedSumSim+(sim*w);
        totalWeightsUsed= totalWeightsUsed+w;
    end
end
if totalWeightsUsed>0
    % Similaridade global
    simGlobal = weightedSumSim/ totalWeightsUsed;
else
    simGlobal=0;
end


end