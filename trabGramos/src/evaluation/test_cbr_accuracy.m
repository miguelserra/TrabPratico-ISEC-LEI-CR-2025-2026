function [accuracy, resultsTable] = test_cbr_accuracy( ...
    testData, caseBase, numericVars, categoricalVars, targetVar, ...
    weights, ranges, simMats, threshold)
% TEST_CBR_ACCURACY
% Testa o CBR num conjunto de casos de teste.
% Para cada caso:
%   - faz Retrieve
%   - usa o caso mais similar
%   - compara a classe prevista com a classe real
%
% Saídas:
%   accuracy     - percentagem de acerto
%   resultsTable - tabela com resultados por caso

    if nargin < 9 || isempty(threshold)
        threshold = 0.8;
    end

    nCases = height(testData);

    rowIndex = (1:nCases)';
    predictedClass = strings(nCases, 1);
    trueClass = strings(nCases, 1);
    bestSimilarity = zeros(nCases, 1);
    isCorrect = false(nCases, 1);
    nRetrieved = zeros(nCases, 1);

    for i = 1:nCases
        newCase = testData(i, :);

        [retrievedCases, bestCase, sortedSims, ~] = retrieve_cases( ...
            newCase, caseBase, numericVars, categoricalVars, ...
            weights, ranges, simMats, threshold, true);

        % classe real
        trueClass(i) = string(newCase.(targetVar));

        if isempty(sortedSims) || height(bestCase) == 0
            predictedClass(i) = "";
            bestSimilarity(i) = NaN;
            nRetrieved(i) = 0;
            isCorrect(i) = false;
            continue;
        end

        % classe prevista = classe do melhor caso
        predictedClass(i) = string(bestCase.(targetVar));
        bestSimilarity(i) = sortedSims(1);
        nRetrieved(i) = height(retrievedCases);

        isCorrect(i) = predictedClass(i) == trueClass(i);
    end

    accuracy = 100 * mean(isCorrect);

    resultsTable = table( ...
        rowIndex, trueClass, predictedClass, bestSimilarity, nRetrieved, isCorrect, ...
        'VariableNames', {'row_index', 'true_class', 'predicted_class', ...
                          'best_similarity', 'n_retrieved', 'is_correct'});
end