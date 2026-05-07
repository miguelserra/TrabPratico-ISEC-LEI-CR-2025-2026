function summaryTable = run_cbr_experiments(weightSets, weightNames)
% RUN_CBR_EXPERIMENTS
% Corre várias configurações do CBR:
%   - raw_nomice
%   - raw_mice
%   - norm_nomice
%   - norm_mice
%
% Para cada configuração e conjunto de pesos:
%   - prepara/carrega o pré-processamento
%   - prepara/carrega o CBR
%   - testa no dataset_TP_test.csv
%   - guarda resultados detalhados
%   - devolve tabela resumo

if nargin < 1 || isempty(weightSets)
    [~, ~, ~, defaultWeights] = get_dataset_config();
    weightSets = {defaultWeights};
end

if nargin < 2 || isempty(weightNames)
    weightNames = cell(size(weightSets));
    for i = 1:numel(weightSets)
        weightNames{i} = sprintf('weights_%d', i);
    end
end

if numel(weightSets) ~= numel(weightNames)
    error('weightSets e weightNames têm de ter o mesmo número de elementos.');
end

% -----------------------------
% Pastas de output
% -----------------------------
preprocessedDir = fullfile('outputs', 'preprocessed');
cbrDir          = fullfile('outputs', 'cbr');
tablesDir       = fullfile('outputs', 'tables');

if ~exist(preprocessedDir, 'dir'), mkdir(preprocessedDir); end
if ~exist(cbrDir, 'dir'), mkdir(cbrDir); end
if ~exist(tablesDir, 'dir'), mkdir(tablesDir); end

% -----------------------------
% Configurações a testar
% -----------------------------
configs = { ...
    struct('useMice', false, 'normalizeData', false), ...
    struct('useMice', true,  'normalizeData', false), ...
    struct('useMice', false, 'normalizeData', true ), ...
    struct('useMice', true,  'normalizeData', true )  ...
    };

% -----------------------------
% Dataset config fixa
% -----------------------------
[numericVars, categoricalVars, targetVar, defaultWeights] = get_dataset_config();

% tabela resumo
summaryRows = {};

% -----------------------------
% Loop principal
% -----------------------------
for c = 1:numel(configs)
    opts = get_default_options();
    opts.useMice = configs{c}.useMice;
    opts.normalizeData = configs{c}.normalizeData;
    opts.verbose = true;

    opts.loadPreprocessed = true;
    opts.savePreprocessed = true;
    opts.exportPreprocessedExcel = true;

    opts.loadCBR = true;
    opts.saveCBR = true;
    opts.exportCBRExcel = true;
    
    configName = build_config_name(opts);

    fprintf('\n====================================================\n');
    fprintf('Configuração: %s\n', configName);
    fprintf('====================================================\n');

    % --------------------------------------
    % 1) Carregar/preparar pré-processamento
    % --------------------------------------
    preprocessedFile = fullfile(preprocessedDir, [configName '.mat']);

    if opts.loadPreprocessed && exist(preprocessedFile, 'file')
        fprintf('[PRE] A carregar pré-processamento guardado: %s\n', preprocessedFile);

        load(preprocessedFile, ...
            'engineData', 'engineDataCBR', 'prepInfo', 'normParams', ...
            'numericVars', 'categoricalVars', 'targetVar');
    else
        fprintf('[PRE] A calcular pré-processamento...\n');

        engineData = readtable("dataset_TP.csv");
        engineData = encode_categorical(engineData);

        [engineData, prepInfo] = preprocess_dataset(engineData, numericVars, categoricalVars, opts);

        if opts.normalizeData
            [engineDataCBR, normParams] = normalize_dataset(engineData, numericVars);
        else
            engineDataCBR = engineData;
            normParams = [];
        end

        if opts.savePreprocessed
            save(preprocessedFile, ...
                'engineData', 'engineDataCBR', 'prepInfo', 'normParams', ...
                'opts', 'numericVars', 'categoricalVars', 'targetVar');

            fprintf('[PRE] Guardado em: %s\n', preprocessedFile);
        end

        if opts.exportPreprocessedExcel
            preprocessedExcel = fullfile(tablesDir, ['dataset_' configName '.xlsx']);
            writetable(engineDataCBR, preprocessedExcel);
            fprintf('[PRE] Exportado para Excel: %s\n', preprocessedExcel);
        end
    end

    % metadata CBR
    [ranges, simMats] = prepare_cbr_metadata(engineDataCBR, numericVars);

    % --------------------------------------
    % 2) Para cada conjunto de pesos
    % --------------------------------------
    for w = 1:numel(weightSets)
        weights = weightSets{w};
        weightTag = weightNames{w};
        experimentName = [configName '_' weightTag];

        fprintf('\n[CBR] Experiência: %s\n', experimentName);

        if numel(weights) ~= numel(defaultWeights)
            error('O conjunto de pesos "%s" não tem %d valores.', ...
                weightTag, numel(defaultWeights));
        end

        % ficheiros desta experiência
        cbrFile = fullfile(cbrDir, ['cbr_' experimentName '.mat']);
        cbrDatasetExcel = fullfile(tablesDir, ['cbr_dataset_' experimentName '.xlsx']);
        cbrPredictionsExcel = fullfile(tablesDir, ['cbr_predictions_' experimentName '.xlsx']);
        cbrTestExcel = fullfile(tablesDir, ['cbr_test_results_' experimentName '.xlsx']);
        cbrTestMat = fullfile(cbrDir, ['cbr_test_' experimentName '.mat']);

        % reset ao dataset base para esta experiência
        caseBase = engineDataCBR;

        % --------------------------------------
        % 2.1) Preencher target com CBR
        % --------------------------------------
        if opts.loadCBR && exist(cbrFile, 'file')
            fprintf('[CBR] A carregar resultados guardados: %s\n', cbrFile);

            load(cbrFile, ...
                'caseBase', 'predictedClasses', 'bestSimilarities', ...
                'missingTargetIdx', 'ranges', 'simMats');
        else
            fprintf('[CBR] A preencher class_cat com CBR...\n');

            missingTargetIdx = find(ismissing(caseBase.(targetVar)));

            if opts.fillMissingTargetWithCBR
                [caseBase, predictedClasses, bestSimilarities] = fill_missing_target_cbr( ...
                    caseBase, numericVars, categoricalVars, weights, ranges, simMats);
            else
                predictedClasses = [];
                bestSimilarities = [];
            end

            if opts.saveCBR
                save(cbrFile, ...
                    'caseBase', 'predictedClasses', 'bestSimilarities', ...
                    'missingTargetIdx', 'ranges', 'simMats', ...
                    'opts', 'numericVars', 'categoricalVars', 'targetVar', 'weights');

                fprintf('[CBR] Guardado em: %s\n', cbrFile);
            end

            if opts.exportCBRExcel
                writetable(caseBase, cbrDatasetExcel);

                if ~isempty(missingTargetIdx)
                    predTable = table( ...
                        missingTargetIdx(:), ...
                        string(predictedClasses(:)), ...
                        bestSimilarities(:), ...
                        'VariableNames', {'row_index', 'predicted_class', 'best_similarity'});

                    writetable(predTable, cbrPredictionsExcel);
                end

                fprintf('[CBR] Dataset exportado para: %s\n', cbrDatasetExcel);
            end
        end

        % --------------------------------------
        % 2.2) Testar no dataset_TP_test
        % --------------------------------------
        fprintf('[TEST] A testar no dataset_TP_test.csv...\n');

        testData = readtable("dataset_TP_test.csv");
        testData = encode_categorical(testData);

        if opts.normalizeData
            testDataCBR = normalize_dataset(testData, numericVars, normParams);
        else
            testDataCBR = testData;
        end

        [accuracyCBR, resultsCBR] = test_cbr_accuracy( ...
            testDataCBR, caseBase, numericVars, categoricalVars, targetVar, ...
            weights, ranges, simMats, 0.8);

        writetable(resultsCBR, cbrTestExcel);
        save(cbrTestMat, 'accuracyCBR', 'resultsCBR', 'experimentName', 'weights');

        meanBestSimilarity = mean(resultsCBR.best_similarity, 'omitnan');
        nCases = height(resultsCBR);
        nCorrect = sum(resultsCBR.is_correct);

        fprintf('[TEST] Accuracy = %.2f%% | Correctos = %d/%d | Similaridade média = %.4f\n', ...
            accuracyCBR, nCorrect, nCases, meanBestSimilarity);

        summaryRows(end+1, :) = { ...
            configName, ...
            weightTag, ...
            opts.useMice, ...
            opts.normalizeData, ...
            mat2str(weights), ...
            nCases, ...
            nCorrect, ...
            accuracyCBR, ...
            meanBestSimilarity ...
            };
    end
end

% -----------------------------
% Tabela resumo final
% -----------------------------
summaryTable = cell2table(summaryRows, ...
    'VariableNames', { ...
    'config_name', ...
    'weight_name', ...
    'use_mice', ...
    'normalize_data', ...
    'weights', ...
    'n_cases', ...
    'n_correct', ...
    'accuracy_percent', ...
    'mean_best_similarity'});

summaryFile = fullfile(tablesDir, 'cbr_experiments_summary.xlsx');
writetable(summaryTable, summaryFile);

fprintf('\n============================================\n');
fprintf('Resumo final exportado para: %s\n', summaryFile);
fprintf('============================================\n');
end