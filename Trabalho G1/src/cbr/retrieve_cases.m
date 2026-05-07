function [retrievedCases, bestCase, sortedSims, sortedIdx] = retrieve_cases( ...
    newCase, caseBase, numericVars, categoricalVars, weights, ranges, simMats, threshold, requireKnownTarget)
% RETRIEVE_CASES
% Calcula a similaridade entre um novo caso e todos os casos da case base.
% Devolve:
%   - casos acima do limiar
%   - melhor caso
%   - similaridades ordenadas
%   - índices ordenados
%
% Entradas:
%   newCase            -> tabela com 1 linha
%   caseBase           -> tabela com vários casos
%   threshold          -> limiar mínimo de similaridade
%   requireKnownTarget -> se true, usa só casos com class_cat conhecido

    if nargin < 8 || isempty(threshold)
        threshold = 0.8;
    end

    if nargin < 9
        requireKnownTarget = true;
    end

    % usar só casos com target conhecido, se necessário
    if requireKnownTarget
        validMask = ~ismissing(caseBase.class_cat);
        workBase = caseBase(validMask, :);
    else
        workBase = caseBase;
    end

    nCases = height(workBase);
    sims = zeros(nCases, 1);

    % calcular similaridade com cada caso
    for i = 1:nCases
        sims(i) = compute_similarity( ...
            newCase, workBase(i,:), numericVars, categoricalVars, ...
            weights, ranges, simMats);
    end

    % ordenar por similaridade descendente
    [sortedSims, order] = sort(sims, 'descend');
    sortedIdx = order;

    sortedBase = workBase(order, :);
    sortedBase.similarity = sortedSims;

    % melhor caso
    if nCases > 0
        bestCase = sortedBase(1, :);
    else
        bestCase = table();
    end

    % casos acima do limiar
    mask = sortedSims >= threshold;
    retrievedCases = sortedBase(mask, :);
end