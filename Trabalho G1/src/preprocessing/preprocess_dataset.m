function [engineData, info] = preprocess_dataset(engineData, numericVars, categoricalVars, opts)

info = struct();

if opts.verbose
    fprintf('  -> Missing iniciais nos inputs: %d\n', ...
        sum(sum(ismissing(engineData(:, [numericVars categoricalVars])))));
end

[engineData, fillInfo]= fill_missing_inputs(engineData, numericVars, categoricalVars, opts);
info.fillInfo = fillInfo;

if opts.verbose
    fprintf('  -> Preenchimento inicial concluído\n');
end

if opts.useMice
    if opts.verbose
        fprintf('  -> A executar MICE (%d iterações)...\n', opts.miceIterations);
    end

    [engineData, miceInfo] = fill_nans_mice(engineData, numericVars, categoricalVars, opts, fillInfo.originalNumericMissingMask);

    info.miceInfo = miceInfo;

    if opts.verbose
        fprintf('  -> MICE concluído\n');
    end
end

if opts.verbose
    fprintf('  -> Missing finais nos inputs: %d\n', ...
        sum(sum(ismissing(engineData(:, [numericVars categoricalVars])))));
end

end