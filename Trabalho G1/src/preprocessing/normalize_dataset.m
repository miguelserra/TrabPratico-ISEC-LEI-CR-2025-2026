function [Tnorm, normParams] = normalize_dataset(T, numericVars, normParams)
% NORMALIZE_DATASET
% Normaliza colunas numéricas por min-max para o intervalo [0,1]
%
% Uso:
%   [Tnorm, normParams] = normalize_dataset(T, numericVars)
%   TtestNorm = normalize_dataset(Ttest, numericVars, normParams)
%
% Entradas:
%   T          - tabela MATLAB
%   numericVars - cell array com nomes das variáveis numéricas a normalizar
%   normParams - estrutura com min/max já calculados (opcional)
%
% Saídas:
%   Tnorm      - tabela normalizada
%   normParams - estrutura com os parâmetros usados

    Tnorm = T;

    if nargin < 3 || isempty(normParams)
        normParams = struct();
        computeParams = true;
    else
        computeParams = false;
    end

    for i = 1:numel(numericVars)
        varName = numericVars{i};
        x = T.(varName);

        if ~isnumeric(x)
            error('A variável "%s" não é numérica.', varName);
        end

        if computeParams
            xmin = min(x, [], 'omitnan');
            xmax = max(x, [], 'omitnan');

            normParams.(varName).min = xmin;
            normParams.(varName).max = xmax;
        else
            xmin = normParams.(varName).min;
            xmax = normParams.(varName).max;
        end

        if xmax == xmin
            % coluna constante
            xnorm = zeros(size(x));
        else
            xnorm = (x - xmin) / (xmax - xmin);
        end

        Tnorm.(varName) = xnorm;
    end
end