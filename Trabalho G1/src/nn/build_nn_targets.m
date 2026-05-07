function [T, classNames, classIndex] = build_nn_targets(engineData, targetVar)
% BUILD_NN_TARGETS
% Constrói o target one-hot para classificação multiclasse.
%
% Saídas:
%   T          -> matriz 3 x N
%   classNames -> nomes das classes por ordem
%   classIndex -> índice inteiro de cada amostra (1..3)

    y = string(engineData.(targetVar));
    nCases = numel(y);

    % ordem fixa das classes
    classNames = ["Normal", "ElectricalFailure", "MechanicalFailure"];

    T = zeros(numel(classNames), nCases);
    classIndex = zeros(1, nCases);

    for i = 1:nCases
        idx = find(y(i) == classNames, 1);

        if isempty(idx)
            error('Classe desconhecida na linha %d: %s', i, y(i));
        end

        T(idx, i) = 1;
        classIndex(i) = idx;
    end
end