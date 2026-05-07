function result = train_and_evaluate_nn(X, T, classNames, hiddenLayers, trainFcn, divideRatios, seed, normalizeInputs, savePrefix)
% TRAIN_AND_EVALUATE_NN
% Treina e avalia uma configuração de rede neuronal para classificação.
%
% Inputs:
%   X               - inputs [nFeatures x nSamples]
%   T               - targets one-hot [nClasses x nSamples]
%   classNames      - nomes das classes (string array)
%   hiddenLayers    - topologia, ex: [10], [15 5], [8 8 4]
%   trainFcn        - ex: 'trainbr', 'trainscg', 'traingdx'
%   divideRatios    - ex: [0.70 0.15 0.15]
%   seed            - seed para rng
%   normalizeInputs - true/false
%   savePrefix      - prefixo para guardar confusion chart (opcional)
%
% Output:
%   result - struct com rede, métricas, previsões, índices, etc.

    if nargin < 9
        savePrefix = '';
    end

    rng(seed);

    nSamples = size(X, 2);

    % -----------------------------------------
    % 1) Divisão manual dos índices
    % -----------------------------------------
    perm = randperm(nSamples);

    nTrain = round(divideRatios(1) * nSamples);
    nVal   = round(divideRatios(2) * nSamples);
    nTest  = nSamples - nTrain - nVal;

    trainInd = perm(1:nTrain);
    valInd   = perm(nTrain+1:nTrain+nVal);
    testInd  = perm(nTrain+nVal+1:end);

    % -----------------------------------------
    % 2) Normalização opcional com parâmetros
    %    calculados apenas no treino
    % -----------------------------------------
    Xwork = X;
    normParams = [];

    if normalizeInputs
        mu = mean(X(:, trainInd), 2);
        sd = std(X(:, trainInd), 0, 2);
        sd(sd < 1e-12) = 1;

        Xwork = (X - mu) ./ sd;

        normParams.mu = mu;
        normParams.sd = sd;
    end

    % -----------------------------------------
    % 3) Criar rede
    % -----------------------------------------
    net = patternnet(hiddenLayers, trainFcn);

    % camadas ocultas
    for i = 1:numel(hiddenLayers)
        net.layers{i}.transferFcn = 'tansig';
    end

    % saída
    net.layers{end}.transferFcn = 'softmax';
    % desempenho
    if strcmpi(trainFcn, 'trainbr')
        net.performFcn = 'mse';
    else
        net.performFcn = 'crossentropy';
    end

    % divisão fixa
    net.divideFcn = 'divideind';
    net.divideParam.trainInd = trainInd;
    net.divideParam.valInd   = valInd;
    net.divideParam.testInd  = testInd;

    net.trainParam.showWindow = false;
    net.trainParam.showCommandLine = false;

    % -----------------------------------------
    % 4) Treino
    % -----------------------------------------
    [net, tr] = train(net, Xwork, T);

    % -----------------------------------------
    % 5) Previsões
    % -----------------------------------------
    Y = net(Xwork);

    [~, predIndex] = max(Y, [], 1);
    [~, trueIndex] = max(T, [], 1);

    accuracyGlobal = 100 * mean(predIndex == trueIndex);
    accuracyTest   = 100 * mean(predIndex(testInd) == trueIndex(testInd));

    % classes em string
    predLabels = classNames(predIndex)';
    trueLabels = classNames(trueIndex)';

    predLabelsTest = classNames(predIndex(testInd))';
    trueLabelsTest = classNames(trueIndex(testInd))';

    % -----------------------------------------
    % 6) Guardar confusion charts, se pedido
    % -----------------------------------------
    if ~isempty(savePrefix)
        outDir = fileparts(savePrefix);
        if ~isempty(outDir) && ~exist(outDir, 'dir')
            mkdir(outDir);
        end

        fig1 = figure('Visible', 'off');
        confusionchart(categorical(trueLabels, classNames), categorical(predLabels, classNames));
        title('Confusion Chart - Global');
        saveas(fig1, [savePrefix '_global.png']);
        close(fig1);

        fig2 = figure('Visible', 'off');
        confusionchart(categorical(trueLabelsTest, classNames), categorical(predLabelsTest, classNames));
        title('Confusion Chart - Test');
        saveas(fig2, [savePrefix '_test.png']);
        close(fig2);
    end

    % -----------------------------------------
    % 7) Resultado
    % -----------------------------------------
    result = struct();
    result.net = net;
    result.tr = tr;

    result.hiddenLayers = hiddenLayers;
    result.trainFcn = trainFcn;
    result.divideRatios = divideRatios;
    result.seed = seed;
    result.normalizeInputs = normalizeInputs;

    result.normParams = normParams;

    result.trainInd = trainInd;
    result.valInd = valInd;
    result.testInd = testInd;

    result.Y = Y;
    result.predIndex = predIndex;
    result.trueIndex = trueIndex;

    result.predLabels = predLabels;
    result.trueLabels = trueLabels;

    result.predLabelsTest = predLabelsTest;
    result.trueLabelsTest = trueLabelsTest;

    result.accuracyGlobal = accuracyGlobal;
    result.accuracyTest = accuracyTest;
end