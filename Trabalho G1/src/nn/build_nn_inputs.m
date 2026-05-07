function X = build_nn_inputs(engineData, numericVars, categoricalVars)
% BUILD_NN_INPUTS
% Constrói a matriz de inputs para a RN no formato:
%   linhas = features
%   colunas = amostras
%
% Assume que:
% - os missing dos inputs já foram tratados
% - as variáveis categóricas já foram codificadas numericamente

    inputVars = [numericVars, categoricalVars];

    nVars = numel(inputVars);
    nCases = height(engineData);

    X = zeros(nVars, nCases);

    for i = 1:nVars
        varName = inputVars{i};
        X(i, :) = engineData.(varName)';
    end
end