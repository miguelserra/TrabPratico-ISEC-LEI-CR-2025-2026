function comparisonTable = compare_cbr_vs_rn(cbrTestExcel, rnTestResultsExcel, rnRank, outputPrefix)
% COMPARE_CBR_VS_RN
% Compara o desempenho final do CBR com uma das melhores RN no dataset_TP_test.
%
% Inputs:
%   cbrTestExcel      - ficheiro Excel com os resultados detalhados do CBR
%                       ex: outputs/tables/cbr_test_results_raw_nomice.xlsx
%   rnTestResultsExcel - ficheiro Excel com os resultados das melhores RN
%                       ex: outputs/tables/best_nets_testset_results.xlsx
%   rnRank            - qual das bestNet usar (1, 2 ou 3)
%   outputPrefix      - prefixo para guardar outputs
%
% Output:
%   comparisonTable   - tabela final de comparação

    if nargin < 3 || isempty(rnRank)
        rnRank = 1;
    end

    if nargin < 4 || isempty(outputPrefix)
        outputPrefix = fullfile('outputs', 'tables', 'final_cbr_vs_rn');
    end

    outDir = fileparts(outputPrefix);
    if ~isempty(outDir) && ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    classNames = ["Normal", "ElectricalFailure", "MechanicalFailure"];

    % ---------------------------------------------------
    % 1) Ler resultados detalhados do CBR
    % ---------------------------------------------------
    cbrTable = readtable(cbrTestExcel);

    cbrGlobal = 100 * mean(cbrTable.is_correct);

    cbrPerClass = zeros(numel(classNames), 1);
    for i = 1:numel(classNames)
        mask = string(cbrTable.true_class) == classNames(i);
        if any(mask)
            cbrPerClass(i) = 100 * mean(cbrTable.is_correct(mask));
        else
            cbrPerClass(i) = NaN;
        end
    end

    % confusion chart do CBR
    fig1 = figure('Visible', 'off');
    confusionchart(categorical(string(cbrTable.true_class), classNames), ...
                   categorical(string(cbrTable.predicted_class), classNames));
    title('CBR - dataset\_TP\_test');
    cbrChartFile = [outputPrefix '_cbr_confusion.png'];
    saveas(fig1, cbrChartFile);
    close(fig1);

    % ---------------------------------------------------
    % 2) Ler resultados finais das melhores RN
    % ---------------------------------------------------
    rnTable = readtable(rnTestResultsExcel);

    rowMask = rnTable.net_rank == rnRank;
    if ~any(rowMask)
        error('Não foi encontrada nenhuma RN com net_rank = %d.', rnRank);
    end

    rnRow = rnTable(rowMask, :);

    rnGlobal = rnRow.accuracy_global(1);
    rnPerClass = [ ...
        rnRow.accuracy_normal(1); ...
        rnRow.accuracy_electrical(1); ...
        rnRow.accuracy_mechanical(1)];

    rnChartFile = string(rnRow.confusion_chart_file(1));

    % ---------------------------------------------------
    % 3) Comparação quantitativa
    % ---------------------------------------------------
    method = ["CBR"; "RN"];

    accuracy_global = [cbrGlobal; rnGlobal];
    accuracy_normal = [cbrPerClass(1); rnPerClass(1)];
    accuracy_electrical = [cbrPerClass(2); rnPerClass(2)];
    accuracy_mechanical = [cbrPerClass(3); rnPerClass(3)];

    % ---------------------------------------------------
    % 4) Comparação qualitativa
    % (ajusta estas descrições no relatório com base no que observaste)
    % ---------------------------------------------------
    interpretability = [ ...
        "Alta - casos similares e pesos visíveis"; ...
        "Média/Baixa - modelo caixa preta" ...
    ];

    online_adaptation = [ ...
        "Alta - Retain permite adaptação direta"; ...
        "Baixa - requer novo treino/ajuste" ...
    ];

    missing_sensitivity = [ ...
        "Média - precisa de imputação prévia mas lida bem com casos"; ...
        "Alta - RN depende fortemente do pré-processamento" ...
    ];

    outlier_robustness = [ ...
        "Média/Alta - depende da similaridade e dos pesos"; ...
        "Média - pode generalizar bem, mas também ser sensível a dados extremos" ...
    ];

    training_prediction_time = [ ...
        "Treino baixo / previsão moderada"; ...
        "Treino mais alto / previsão muito rápida" ...
    ];

    confusion_chart_file = [string(cbrChartFile); rnChartFile];

    comparisonTable = table( ...
        method, ...
        accuracy_global, ...
        accuracy_normal, ...
        accuracy_electrical, ...
        accuracy_mechanical, ...
        interpretability, ...
        online_adaptation, ...
        missing_sensitivity, ...
        outlier_robustness, ...
        training_prediction_time, ...
        confusion_chart_file);

    % ---------------------------------------------------
    % 5) Guardar outputs
    % ---------------------------------------------------
    excelFile = [outputPrefix '.xlsx'];
    matFile = [outputPrefix '.mat'];

    writetable(comparisonTable, excelFile);
    save(matFile, 'comparisonTable');

    fprintf('  -> Comparação CBR vs RN exportada para: %s\n', excelFile);
    fprintf('  -> Ficheiro MAT guardado em: %s\n', matFile);
end