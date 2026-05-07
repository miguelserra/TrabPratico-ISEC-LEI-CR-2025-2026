function resultsTable = test_best_nets_on_testset(testData, numericVars, categoricalVars, targetVar, classNames)
% TEST_BEST_NETS_ON_TESTSET
% Testa as 3 melhores redes guardadas (bestNet_1.mat, bestNet_2.mat, bestNet_3.mat)
% no dataset de teste.
%
% Inputs:
%   testData         - tabela com o dataset de teste
%   numericVars      - cell array com variáveis numéricas
%   categoricalVars  - cell array com variáveis categóricas codificadas
%   targetVar        - nome do target
%   classNames       - nomes das classes, ex: ["Normal","ElectricalFailure","MechanicalFailure"]
%
% Output:
%   resultsTable     - tabela resumo por rede

    if nargin < 5 || isempty(classNames)
        classNames = ["Normal", "ElectricalFailure", "MechanicalFailure"];
    end

    nnDir = fullfile('outputs', 'nn');
    tablesDir = fullfile('outputs', 'tables');
    analysisDir = fullfile(nnDir, 'testset_analysis');

    if ~exist(nnDir, 'dir'), mkdir(nnDir); end
    if ~exist(tablesDir, 'dir'), mkdir(tablesDir); end
    if ~exist(analysisDir, 'dir'), mkdir(analysisDir); end

    % Preparar inputs e targets do teste
    Xtest = build_nn_inputs(testData, numericVars, categoricalVars);
    [Ttest, ~, trueIndex] = build_nn_targets(testData, targetVar);

    rows = {};

    for k = 1:3
        netFile = fullfile(nnDir, sprintf('bestNet_%d.mat', k));

        if ~isfile(netFile)
            warning('Ficheiro não encontrado: %s', netFile);
            continue;
        end

        S = load(netFile, 'net', 'result');

        % compatibilidade: pode estar guardado como "net" ou dentro de "result.net"
        if isfield(S, 'net')
            net = S.net;
            if isfield(S, 'result')
                resultTrain = S.result;
            else
                resultTrain = struct();
            end
        elseif isfield(S, 'result') && isfield(S.result, 'net')
            net = S.result.net;
            resultTrain = S.result;
        else
            warning('O ficheiro %s não contém uma rede válida.', netFile);
            continue;
        end

        Xwork = Xtest;

        % aplicar normalização do treino, se existir
        if isfield(resultTrain, 'normParams') && ~isempty(resultTrain.normParams)
            if isfield(resultTrain.normParams, 'mu') && isfield(resultTrain.normParams, 'sd')
                mu = resultTrain.normParams.mu;
                sd = resultTrain.normParams.sd;
                sd(sd < 1e-12) = 1;
                Xwork = (Xtest - mu) ./ sd;
            end
        end

        % prever
        Ytest = net(Xwork);
        [~, predIndex] = max(Ytest, [], 1);

        predLabels = classNames(predIndex)';
        trueLabels = classNames(trueIndex)';

        accuracyGlobal = 100 * mean(predIndex == trueIndex);

        % accuracy por classe
        classAcc = zeros(numel(classNames), 1);
        for c = 1:numel(classNames)
            mask = trueIndex == c;
            if any(mask)
                classAcc(c) = 100 * mean(predIndex(mask) == trueIndex(mask));
            else
                classAcc(c) = NaN;
            end
        end

        % confusion chart
        fig = figure('Visible', 'off');
        confusionchart(categorical(trueLabels, classNames), categorical(predLabels, classNames));
        title(sprintf('BestNet %d - dataset_TP_test', k));
        chartFile = fullfile(analysisDir, sprintf('bestNet_%d_testset_confusion.png', k));
        saveas(fig, chartFile);
        close(fig);

        % tabela detalhada por caso
        detailTable = table( ...
            (1:numel(trueIndex))', ...
            string(trueLabels), ...
            string(predLabels), ...
            predIndex(:) == trueIndex(:), ...
            'VariableNames', {'row_index', 'true_class', 'predicted_class', 'is_correct'});

        detailFile = fullfile(tablesDir, sprintf('bestNet_%d_testset_details.xlsx', k));
        writetable(detailTable, detailFile);

        rows(end+1, :) = { ...
            k, ...
            netFile, ...
            accuracyGlobal, ...
            classAcc(1), ...
            classAcc(2), ...
            classAcc(3), ...
            chartFile, ...
            detailFile ...
        };
    end

    resultsTable = cell2table(rows, ...
        'VariableNames', { ...
            'net_rank', ...
            'net_file', ...
            'accuracy_global', ...
            'accuracy_normal', ...
            'accuracy_electrical', ...
            'accuracy_mechanical', ...
            'confusion_chart_file', ...
            'detail_excel_file'});

    outExcel = fullfile(tablesDir, 'best_nets_testset_results.xlsx');
    writetable(resultsTable, outExcel);

    outMat = fullfile(nnDir, 'best_nets_testset_results.mat');
    save(outMat, 'resultsTable');

    fprintf('  -> Resultados das melhores redes no dataset de teste exportados para: %s\n', outExcel);
    fprintf('  -> Ficheiro MAT guardado em: %s\n', outMat);
end