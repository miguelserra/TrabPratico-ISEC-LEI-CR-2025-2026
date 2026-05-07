function [engineData, predictedClasses, bestSimilarities] = fill_missing_target_cbr(engineData, numericVars, categoricalVars, weights, ranges, simMats)

% Identificar quem tem e nao teo o alvo.
knownMask = ~ismissing(engineData.class_cat);
unknownMask = ismissing(engineData.class_cat);

knownCases = engineData(knownMask, :);
unknownCases = engineData(unknownMask, :);

% Initialize the predictedClasses and bestSimilarities arrays
predictedClasses = cell(height(unknownCases), 1);
bestSimilarities = zeros(height(unknownCases), 1);

for j = 1:height(unknownCases)
    sims = zeros(height(knownCases), 1);
    for i = 1:height(knownCases)
        %sims(i) = compute_similarity_NaN(unknownCases(j,:), knownCases(i,:),  numericVars, categoricalVars, weights, ranges, simMats);
        sims(i) = compute_similarity(unknownCases(j,:), knownCases(i,:),  numericVars, categoricalVars, weights, ranges, simMats);
    end
    % Find best value
    %[bestSim, bestId] = max(sims);
    % Store the predicted class and similarity value
    %predictedClasses{j} = knownCases.class_cat{bestId};
    %bestSimilarities(j)= bestSim;
    
    k = 3; % Número de vizinhos
    [sortedSims, sortedIds] = sort(sims, 'descend');
    
    % Buscar as classes dos k vizinhos
    topClasses = knownCases.class_cat(sortedIds(1:k));
    
    % Votação (a classe que mais aparece)
    predictedClasses{j} = char(mode(categorical(topClasses)));
    bestSimilarities(j) = mean(sortedSims(1:k)); % Similaridade média dos k-vizinhos

    if mod(j,10) == 0
        fprintf('Caso %d de %d\n', j, height(unknownCases));
    end
end
%% Insere os nomes das categorias de volta na tabela
engineData.class_cat(unknownMask) = predictedClasses;

end