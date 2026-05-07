function analysisTable = analyze_selected_nn_configs(best3NN, worst3NN, classNames)
% ANALYZE_SELECTED_NN_CONFIGS
% Analisa as 3 melhores e 3 piores configurações de RN.
% Para cada configuração:
%   - carrega o ficheiro best_net_file
%   - extrai métricas principais
%   - gera confusion charts (global e teste)
%   - guarda tabela resumo
%   - guarda as 3 melhores redes com nomes simples

    if nargin < 3 || isempty(classNames)
        classNames = ["Normal", "ElectricalFailure", "MechanicalFailure"];
    end

    tablesDir = fullfile('outputs', 'tables');
    nnDir = fullfile('outputs', 'nn');
    analysisDir = fullfile(nnDir, 'selected_analysis');

    if ~exist(tablesDir, 'dir'), mkdir(tablesDir); end
    if ~exist(nnDir, 'dir'), mkdir(nnDir); end
    if ~exist(analysisDir, 'dir'), mkdir(analysisDir); end

    selected = [best3NN; worst3NN];
    groupTag = [repmat("best", height(best3NN), 1); repmat("worst", height(worst3NN), 1)];

    rows = {};

    for i = 1:height(selected)
        configName = string(selected.config_name(i));
        bestNetFile = string(selected.best_net_file(i));
        groupName = groupTag(i);

        if ~isfile(bestNetFile)
            warning('Ficheiro não encontrado: %s', bestNetFile);
            continue;
        end

        S = load(bestNetFile, 'bestRepResult', 'bestRep');

        if ~isfield(S, 'bestRepResult')
            warning('O ficheiro %s não contém bestRepResult.', bestNetFile);
            continue;
        end

        result = S.bestRepResult;

        % métricas
        accGlobal = result.accuracyGlobal;
        accTest = result.accuracyTest;
        bestRep = S.bestRep;

        % guardar confusion chart global
        fig1 = figure('Visible', 'off');
        confusionchart( ...
            categorical(result.trueLabels, classNames), ...
            categorical(result.predLabels, classNames));
        title(sprintf('%s - Global', configName));
        globalFile = fullfile(analysisDir, sprintf('%s_global.png', configName));
        saveas(fig1, globalFile);
        close(fig1);

        % guardar confusion chart teste
        fig2 = figure('Visible', 'off');
        confusionchart( ...
            categorical(result.trueLabelsTest, classNames), ...
            categorical(result.predLabelsTest, classNames));
        title(sprintf('%s - Test', configName));
        testFile = fullfile(analysisDir, sprintf('%s_test.png', configName));
        saveas(fig2, testFile);
        close(fig2);

        % guardar as 3 melhores redes com nomes simples
        if groupName == "best"
            rankInBest = sum(groupTag(1:i) == "best");
            net = result.net; %#ok<NASGU>
            save(fullfile(nnDir, sprintf('bestNet_%d.mat', rankInBest)), 'net', 'result');
        end

        rows(end+1, :) = { ...
            groupName, ...
            configName, ...
            string(selected.hidden_layers(i)), ...
            string(selected.train_fcn(i)), ...
            string(selected.divide_ratios(i)), ...
            logical(selected.normalize_inputs(i)), ...
            bestRep, ...
            accGlobal, ...
            accTest, ...
            globalFile, ...
            testFile ...
        };
    end

    analysisTable = cell2table(rows, ...
        'VariableNames', { ...
            'group_name', ...
            'config_name', ...
            'hidden_layers', ...
            'train_fcn', ...
            'divide_ratios', ...
            'normalize_inputs', ...
            'best_rep', ...
            'accuracy_global', ...
            'accuracy_test', ...
            'confusion_global_file', ...
            'confusion_test_file'});

    outExcel = fullfile(tablesDir, 'nn_selected_analysis.xlsx');
    writetable(analysisTable, outExcel);

    outMat = fullfile(nnDir, 'nn_selected_analysis.mat');
    save(outMat, 'analysisTable');

    fprintf('  -> Análise das RN selecionadas exportada para: %s\n', outExcel);
    fprintf('  -> Ficheiro MAT guardado em: %s\n', outMat);
end