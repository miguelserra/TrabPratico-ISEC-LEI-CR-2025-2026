function opts = get_default_options()
    % métodos de imputação
    opts.numericFillMethod = 'median';
    opts.categoricalFillMethod = 'mode';

    % pré-processamento
    opts.useMice = true;
    opts.miceIterations = 8;
    opts.normalizeData = false;

    % flags principais
    opts.fillMissingNumeric = true;
    opts.fillMissingCategorical = true;
    opts.fillMissingTargetWithCBR = true;

    % save/load pré-processamento
    opts.loadPreprocessed = true;
    opts.savePreprocessed = true;
    opts.exportPreprocessedExcel = true;

    % save/load CBR
    opts.loadCBR = true;
    opts.saveCBR = true;
    opts.exportCBRExcel = true;

    opts.runCBRExperiments = false;
    opts.prepareNNData = true;

    % mensagens
    opts.verbose = true;
end