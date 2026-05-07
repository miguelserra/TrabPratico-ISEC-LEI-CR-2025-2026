clear; clc;
addpath(genpath('src'))

%% 1. Configuração
opts = get_default_options();

% overrides da experiência atual
opts.useMice = true;
opts.normalizeData = false;

opts.loadPreprocessed = true;
opts.savePreprocessed = true;

opts.loadCBR = true;
opts.saveCBR = true;

opts.runQuickRetrieveDemo = false;
opts.runCBRExperiments = true;
opts.runNNExperiments = true;
opts.runFinalComparison = true;

configName = build_config_name(opts);

%% 2. Carregar dados
if opts.verbose, fprintf('\n[1/12] A carregar dataset...\n'); end
engineData = readtable("dataset_TP.csv");
engineData = encode_categorical(engineData);

[numericVars, categoricalVars, targetVar, weights] = get_dataset_config();

if opts.verbose
    fprintf('  -> %d registos carregados\n', height(engineData));
    fprintf('  -> %d atributos numéricos, %d categóricos\n', numel(numericVars), numel(categoricalVars));
end

%% 3. Pré-processamento + normalização (com save/load)
preprocessedDir = fullfile('outputs', 'preprocessed');
tablesDir = fullfile('outputs', 'tables');
cbrDir = fullfile('outputs', 'cbr');
nnDir = fullfile('outputs', 'nn');

if ~exist(preprocessedDir, 'dir'), mkdir(preprocessedDir); end
if ~exist(tablesDir, 'dir'), mkdir(tablesDir); end
if ~exist(cbrDir, 'dir'), mkdir(cbrDir); end
if ~exist(nnDir, 'dir'), mkdir(nnDir); end

preprocessedFile = fullfile(preprocessedDir, [configName '.mat']);
preprocessedExcel = fullfile(tablesDir, ['dataset_' configName '.xlsx']);

if opts.loadPreprocessed && exist(preprocessedFile, 'file')
    if opts.verbose
        fprintf('\n[2/12] A carregar pré-processamento guardado: %s\n', preprocessedFile);
    end

    load(preprocessedFile, ...
        'engineData', 'engineDataCBR', 'prepInfo', 'normParams', ...
        'numericVars', 'categoricalVars', 'targetVar', 'weights');
else
    if opts.verbose
        fprintf('\n[2/12] Pré-processamento dos inputs...\n');
    end

    [engineData, prepInfo] = preprocess_dataset(engineData, numericVars, categoricalVars, opts);

    if opts.normalizeData
        if opts.verbose
            fprintf('\n[3/12] A normalizar dataset...\n');
        end
        [engineDataCBR, normParams] = normalize_dataset(engineData, numericVars);
    else
        if opts.verbose
            fprintf('\n[3/12] Normalização desativada.\n');
        end
        engineDataCBR = engineData;
        normParams = [];
    end

    if opts.savePreprocessed
        save(preprocessedFile, ...
            'engineData', 'engineDataCBR', 'prepInfo', 'normParams', ...
            'opts', 'numericVars', 'categoricalVars', 'targetVar', 'weights');
    end

    if opts.exportPreprocessedExcel
        writetable(engineDataCBR, preprocessedExcel);
    end
end

%% 4. Metadata CBR
if opts.verbose, fprintf('\n[4/12] A preparar metadata do CBR...\n'); end
[ranges, simMats] = prepare_cbr_metadata(engineDataCBR, numericVars);

%% 5. CBR principal
cbrFile = fullfile(cbrDir, ['cbr_' configName '.mat']);
cbrDatasetExcel = fullfile(tablesDir, ['cbr_dataset_' configName '.xlsx']);
cbrPredictionsExcel = fullfile(tablesDir, ['cbr_predictions_' configName '.xlsx']);

if opts.loadCBR && exist(cbrFile, 'file')
    if opts.verbose
        fprintf('\n[5/12] A carregar resultados do CBR: %s\n', cbrFile);
    end

    load(cbrFile, ...
        'engineDataCBR', 'predictedClasses', 'bestSimilarities', ...
        'missingTargetIdx', 'ranges', 'simMats');
else
    if opts.fillMissingTargetWithCBR
        if opts.verbose
            fprintf('\n[5/12] A preencher class_cat com CBR...\n');
        end

        missingTargetIdx = find(ismissing(engineDataCBR.(targetVar)));

        [engineDataCBR, predictedClasses, bestSimilarities] = fill_missing_target_cbr( ...
            engineDataCBR, numericVars, categoricalVars, weights, ranges, simMats);
    else
        missingTargetIdx = [];
        predictedClasses = [];
        bestSimilarities = [];
    end

    if opts.saveCBR
        save(cbrFile, ...
            'engineDataCBR', 'predictedClasses', 'bestSimilarities', ...
            'missingTargetIdx', 'ranges', 'simMats', ...
            'opts', 'numericVars', 'categoricalVars', 'targetVar', 'weights');
    end

    if opts.exportCBRExcel
        writetable(engineDataCBR, cbrDatasetExcel);

        if ~isempty(missingTargetIdx)
            predTable = table( ...
                missingTargetIdx(:), ...
                string(predictedClasses(:)), ...
                bestSimilarities(:), ...
                'VariableNames', {'row_index', 'predicted_class', 'best_similarity'});

            writetable(predTable, cbrPredictionsExcel);
        end
    end
end

%% 6. Resumo final do dataset tratado
if opts.verbose, fprintf('\n[6/12] Resumo final...\n'); end
show_missing_summary(engineDataCBR, numericVars, categoricalVars, targetVar);

%% 7. Carregar dataset de teste
if opts.verbose, fprintf('\n[7/12] A carregar dataset_TP_test...\n'); end
testData = readtable("dataset_TP_test.csv");
testData = encode_categorical(testData);

if opts.normalizeData
    testDataCBR = normalize_dataset(testData, numericVars, normParams);
else
    testDataCBR = testData;
end

%% 8. Demo opcional do Retrieve
if opts.runQuickRetrieveDemo
    if opts.verbose, fprintf('\n[8/12] Teste rápido do Retrieve...\n'); end

    newCase = testDataCBR(1,:);

    [retrievedCases, bestCase, sortedSims, sortedIdx] = retrieve_cases( ...
        newCase, engineDataCBR, numericVars, categoricalVars, ...
        weights, ranges, simMats, 0.8, true);

    fprintf('  -> Nº de casos acima do limiar: %d\n', height(retrievedCases));

    if ~isempty(sortedSims)
        fprintf('  -> Melhor similaridade: %.4f\n', sortedSims(1));
    end

    disp('Melhor caso encontrado:');
    disp(bestCase);
end

%% 9. Teste do CBR no dataset_TP_test
if opts.verbose, fprintf('\n[9/12] Teste do CBR no dataset_TP_test...\n'); end

[accuracyCBR, resultsCBR] = test_cbr_accuracy( ...
    testDataCBR, engineDataCBR, numericVars, categoricalVars, targetVar, ...
    weights, ranges, simMats, 0.8);

resultsFile = fullfile(tablesDir, ['cbr_test_results_' configName '.xlsx']);
writetable(resultsCBR, resultsFile);

testMatFile = fullfile(cbrDir, ['cbr_test_' configName '.mat']);
save(testMatFile, 'accuracyCBR', 'resultsCBR', 'configName');

%% 10. Experiências automáticas do CBR
if opts.runCBRExperiments
    if opts.verbose, fprintf('\n[10/12] Experiências automáticas do CBR...\n'); end

    weightSets = {weights};
    weightNames = {'manual'};

    summaryTable = run_cbr_experiments(weightSets, weightNames);
    disp(summaryTable);
end

%% 11. Preparação dos dados para RN
if opts.verbose, fprintf('\n[11/12] Preparação dos dados para RN...\n'); end

X = build_nn_inputs(engineDataCBR, numericVars, categoricalVars);
[T, classNames, classIndex] = build_nn_targets(engineDataCBR, targetVar);

fprintf('  -> Inputs RN: %d features x %d amostras\n', size(X,1), size(X,2));
fprintf('  -> Targets RN: %d classes x %d amostras\n', size(T,1), size(T,2));

%% 12. Pipeline das RN + comparação final
if opts.runNNExperiments
    [summaryNN, allNNResults] = run_nn_experiments(engineDataCBR, numericVars, categoricalVars, targetVar);

    [best3NN, worst3NN] = select_best_worst_nn_configs(summaryNN);

    writetable(best3NN, fullfile('outputs', 'tables', 'nn_best3.xlsx'));
    writetable(worst3NN, fullfile('outputs', 'tables', 'nn_worst3.xlsx'));

    analysisNN = analyze_selected_nn_configs(best3NN, worst3NN, classNames); %#ok<NASGU>
    resultsBestNets = test_best_nets_on_testset(testData, numericVars, categoricalVars, targetVar, classNames); %#ok<NASGU>
end

if opts.runFinalComparison
    cbrBestFile = fullfile('outputs', 'tables', 'cbr_test_results_raw_mice.xlsx');
    rnBestFile  = fullfile('outputs', 'tables', 'best_nets_testset_results.xlsx');

    comparisonCBRvsRN = compare_cbr_vs_rn( ...
        cbrBestFile, ...
        rnBestFile, ...
        1, ...
        fullfile('outputs', 'tables', 'final_cbr_vs_rn'));

    disp('=== Comparação final CBR vs RN ===');
    disp(comparisonCBRvsRN);
end