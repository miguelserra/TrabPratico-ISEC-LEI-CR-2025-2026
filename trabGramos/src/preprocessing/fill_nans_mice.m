function [engineData, info] = fill_nans_mice(engineData, numericVars, categoricalVars, opts, originalMissingMask)
% FILL_NANS_MICE
% Refina os missing values dos atributos numéricos com uma abordagem tipo MICE.
% Assume que os missing já foram inicialmente preenchidos por mediana/moda.
%
% Inputs:
%   engineData          - tabela com os dados
%   numericVars         - cell array com nomes das variáveis numéricas
%   categoricalVars     - cell array com nomes das categóricas codificadas
%   opts                - estrutura de opções
%   originalMissingMask - matriz lógica [n x p] com missing originais numéricos
%
% Outputs:
%   engineData          - tabela refinada
%   info                - estrutura com dados da convergência

    if nargin < 5 || isempty(originalMissingMask)
        error('É necessário passar a máscara original dos missing numéricos.');
    end

    info = struct();
    info.iterations = opts.miceIterations;
    info.maxDelta = zeros(opts.miceIterations, 1);

    n = height(engineData);
    p = numel(numericVars);

    % -----------------------------
    % Construir matriz numérica
    % -----------------------------
    Xnum = zeros(n, p);
    for j = 1:p
        Xnum(:, j) = engineData.(numericVars{j});
    end

    % -----------------------------
    % Construir matriz categórica codificada
    % -----------------------------
    Xcat = zeros(n, numel(categoricalVars));
    for j = 1:numel(categoricalVars)
        Xcat(:, j) = engineData.(categoricalVars{j});
    end

    % -----------------------------
    % Critério de convergência
    % -----------------------------
    tol = 1e-4;

    for it = 1:opts.miceIterations
        Xold = Xnum;

        if opts.verbose
            fprintf('     iteração MICE %d/%d\n', it, opts.miceIterations);
        end

        % -----------------------------------------
        % Refinar uma variável numérica de cada vez
        % -----------------------------------------
        for j = 1:p
            miss = originalMissingMask(:, j);
            obs = ~miss;

            if ~any(miss)
                continue;
            end

            % usar as restantes numéricas + categóricas como preditores
            predIdx = setdiff(1:p, j);
            Xall = [Xnum(:, predIdx), Xcat];
            yall = Xnum(:, j);

            % treino só com valores observados
            Xtrain = Xall(obs, :);
            ytrain = yall(obs);

            % normalização local dos preditores
            mu = mean(Xtrain, 1);
            sd = std(Xtrain, 0, 1);
            sd(sd < 1e-12) = 1;

            XtrainZ = (Xtrain - mu) ./ sd;

            % regressão linear múltipla
            beta = [ones(size(XtrainZ,1),1), XtrainZ] \ ytrain;

            % previsão dos missing
            Xmiss = Xall(miss, :);
            XmissZ = (Xmiss - mu) ./ sd;
            yhat = [ones(size(XmissZ,1),1), XmissZ] * beta;

            % limitar ao intervalo observado
            lo = min(ytrain);
            hi = max(ytrain);
            yhat = max(lo, min(hi, yhat));

            % atualizar só os missing originais
            Xnum(miss, j) = yhat;

            if opts.verbose
                fprintf('       %-18s -> %3d valores refinados\n', numericVars{j}, sum(miss));
            end
        end

        % -----------------------------------------
        % Medir convergência
        % -----------------------------------------
        delta = max(abs(Xnum(:) - Xold(:)));
        info.maxDelta(it) = delta;

        if opts.verbose
            fprintf('       delta máximo = %.8f\n', delta);
        end

        if delta < tol
            info.maxDelta = info.maxDelta(1:it);
            break;
        end
    end

    % -----------------------------
    % Copiar de volta para a tabela
    % -----------------------------
    for j = 1:p
        engineData.(numericVars{j}) = Xnum(:, j);
    end

    % -----------------------------
    % Guardar gráfico de convergência
    % -----------------------------
    if ~exist(fullfile('outputs', 'tables'), 'dir')
        mkdir(fullfile('outputs', 'tables'));
    end

    fig = figure('Name', 'Convergencia MICE', 'Visible', 'off');
    plot(1:numel(info.maxDelta), info.maxDelta, '-o', 'LineWidth', 2);
    xlabel('Iteração');
    ylabel('Delta máximo');
    title('Convergência do MICE');
    set(gca, 'YScale', 'log');
    grid on;

    saveas(fig, fullfile('outputs', 'tables', 'convergencia_mice.jpg'));
    close(fig);
end