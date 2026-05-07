function [summaryTable, allResults] = run_nn_experiments(engineDataForNN, numericVars, categoricalVars, targetVar)
% RUN_NN_EXPERIMENTS
% Corre várias experiências de redes neuronais para classificação.
%
% Inputs:
%   engineDataForNN  - tabela com dataset tratado e target preenchido
%   numericVars      - cell array das variáveis numéricas
%   categoricalVars  - cell array das variáveis categóricas codificadas
%   targetVar        - nome da variável target (ex: 'class_cat')
%
% Outputs:
%   summaryTable     - tabela resumo por configuração
%   allResults       - cell array com resultados detalhados

    % --------------------------------------
    % Pastas de output
    % --------------------------------------
    nnDir = fullfile('outputs', 'nn');
    tablesDir = fullfile('outputs', 'tables');

    if ~exist(nnDir, 'dir'), mkdir(nnDir); end
    if ~exist(tablesDir, 'dir'), mkdir(tablesDir); end

    % --------------------------------------
    % Preparar dados
    % --------------------------------------
    X = build_nn_inputs(engineDataForNN, numericVars, categoricalVars);
    [T, classNames, classIndex] = build_nn_targets(engineDataForNN, targetVar);

    % --------------------------------------
    % Configurações a testar
    % --------------------------------------
    hiddenLayerConfigs = { [10], [15 5], [8 8 4] };
    hiddenLayerNames   = { '10', '15_5', '8_8_4' };

    trainFcns = { 'trainbr', 'trainscg', 'traingdx' };
    divideConfigs = { [0.70 0.15 0.15], [0.60 0.20 0.20] };
    divideNames   = { '70_15_15', '60_20_20' };

    normalizeFlags = [false true];

    nReps = 10;

    % --------------------------------------
    % Estruturas para guardar resultados
    % --------------------------------------
    summaryRows = {};
    allResults = {};

    configCounter = 0;

    interations= numel(hiddenLayerNames)*numel(trainFcns)*numel(divideConfigs)*numel(normalizeFlags);
    inter=0;
    % --------------------------------------
    % Loop principal
    % --------------------------------------
    for h = 1:numel(hiddenLayerConfigs)
        for t = 1:numel(trainFcns)
            for d = 1:numel(divideConfigs)
                for nrm = 1:numel(normalizeFlags)

                    
                    configCounter = configCounter + 1;

                    hiddenLayers = hiddenLayerConfigs{h};
                    hiddenName = hiddenLayerNames{h};

                    trainFcn = trainFcns{t};

                    divideRatios = divideConfigs{d};
                    divideName = divideNames{d};

                    normalizeInputs = normalizeFlags(nrm);

                    configName = sprintf('nn_%s_%s_%s_%s', ...
                        hiddenName, ...
                        trainFcn, ...
                        divideName, ...
                        ternary_str(normalizeInputs, 'norm', 'raw'));

                    inter=inter+1;

                    fprintf('\n====================================================\n');
                    fprintf('RN Configuração [%d/%d]: %s\n',inter,interations,  configName);
                    fprintf('====================================================\n');

                    repGlobalAcc = zeros(nReps, 1);
                    repTestAcc = zeros(nReps, 1);
                    repFiles = strings(nReps, 1);

                    bestRepAcc = -inf;
                    bestRepResult = [];
                    bestRep = 1;

                    for rep = 1:nReps
                        seed = 100 + rep;

                        fprintf('[RN] %s | repetição %d/%d\n', configName, rep, nReps);

                        savePrefix = fullfile(nnDir, sprintf('%s_rep_%02d', configName, rep));

                        result = train_and_evaluate_nn( ...
                            X, T, classNames, ...
                            hiddenLayers, ...
                            trainFcn, ...
                            divideRatios, ...
                            seed, ...
                            normalizeInputs, ...
                            savePrefix);

                        repGlobalAcc(rep) = result.accuracyGlobal;
                        repTestAcc(rep) = result.accuracyTest;
                        repFiles(rep) = string(savePrefix);

                        % guardar resultado detalhado desta repetição
                        repMatFile = [savePrefix '.mat'];
                        save(repMatFile, 'result');

                        if result.accuracyTest > bestRepAcc
                            bestRepAcc = result.accuracyTest;
                            bestRepResult = result;
                            bestRep = rep;
                        end
                    end

                    % estatísticas da configuração
                    meanGlobal = mean(repGlobalAcc);
                    stdGlobal  = std(repGlobalAcc);

                    meanTest = mean(repTestAcc);
                    stdTest  = std(repTestAcc);

                    fprintf('[RN] Média accuracy global = %.2f%% ± %.2f\n', meanGlobal, stdGlobal);
                    fprintf('[RN] Média accuracy teste  = %.2f%% ± %.2f\n', meanTest, stdTest);

                    % guardar melhor repetição da configuração
                    bestNetFile = fullfile(nnDir, ['best_' configName '.mat']);
                    save(bestNetFile, 'bestRepResult', 'bestRep');

                    % guardar para análise posterior
                    allResults{configCounter, 1} = struct( ...
                        'configName', configName, ...
                        'hiddenLayers', hiddenLayers, ...
                        'trainFcn', trainFcn, ...
                        'divideRatios', divideRatios, ...
                        'normalizeInputs', normalizeInputs, ...
                        'repGlobalAcc', repGlobalAcc, ...
                        'repTestAcc', repTestAcc, ...
                        'bestRep', bestRep, ...
                        'bestRepResult', bestRepResult, ...
                        'bestNetFile', bestNetFile);

                    % linha de resumo
                    summaryRows(end+1, :) = { ...
                        configName, ...
                        mat2str(hiddenLayers), ...
                        trainFcn, ...
                        mat2str(divideRatios), ...
                        normalizeInputs, ...
                        nReps, ...
                        meanGlobal, ...
                        stdGlobal, ...
                        meanTest, ...
                        stdTest, ...
                        bestRep, ...
                        bestNetFile ...
                    };
                end
            end
        end
    end

    % --------------------------------------
    % Tabela resumo final
    % --------------------------------------
    summaryTable = cell2table(summaryRows, ...
        'VariableNames', { ...
            'config_name', ...
            'hidden_layers', ...
            'train_fcn', ...
            'divide_ratios', ...
            'normalize_inputs', ...
            'n_repetitions', ...
            'mean_accuracy_global', ...
            'std_accuracy_global', ...
            'mean_accuracy_test', ...
            'std_accuracy_test', ...
            'best_rep', ...
            'best_net_file'});

    % ordenar por accuracy teste média decrescente
    summaryTable = sortrows(summaryTable, 'mean_accuracy_test', 'descend');

    % guardar resumo
    summaryExcel = fullfile(tablesDir, 'nn_experiments_summary.xlsx');
    writetable(summaryTable, summaryExcel);

    summaryMat = fullfile(nnDir, 'nn_experiments_summary.mat');
    save(summaryMat, 'summaryTable', 'allResults');

    fprintf('\n============================================\n');
    fprintf('Resumo RN exportado para: %s\n', summaryExcel);
    fprintf('Resumo RN guardado em: %s\n', summaryMat);
    fprintf('============================================\n');
end

function out = ternary_str(cond, a, b)
    if cond
        out = a;
    else
        out = b;
    end
end