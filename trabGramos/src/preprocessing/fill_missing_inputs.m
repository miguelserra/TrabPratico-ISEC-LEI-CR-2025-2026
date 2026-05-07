function [engineData, info] = fill_missing_inputs(engineData, numericVars, categoricalVars, opts)

info = struct();
info.numeric = struct();
info.categorical = struct();
info.originalNumericMissingMask = false(height(engineData), numel(numericVars));

% Fill missing numeric variables with the median
if opts.fillMissingNumeric
    for i = 1:length(numericVars)
        varName = numericVars{i};
        col = engineData.(varName);

        miss = isnan(col);
        nMiss = sum(miss);
        info.originalNumericMissingMask(:,i)=miss;

        if nMiss==0
            continue;
        end

        switch lower(opts.numericFillMethod)
            case 'mean'
                fillValue = mean(col, 'omitnan');
            case 'median'
                fillValue = median(col, 'omitnan');
            otherwise
                error('Método numérico desconhecido: %s', opts.numericFillMethod);
        end

        col(miss)= fillValue;
        engineData.(varName)=col;

        info.numeric.(varName).missingCount = nMiss;
        info.numeric.(varName).fillValue = fillValue;

        if opts.verbose
            fprintf('     [num] %-18s -> %3d missing preenchidos com %.6f\n', ...
                varName, nMiss, fillValue);
        end
    end
end


% Fill missing categorical variables with the mode
if opts.fillMissingCategorical
    for j = 1:length(categoricalVars)
        varName = categoricalVars{j};
        col = engineData.(varName);
        validValues=col(~isnan(col));

        miss = isnan(col);
        nMiss = sum(miss);

        if nMiss==0
            continue;
        end

        switch lower(opts.categoricalFillMethod)
            case 'mode'
                fillValue = mode(validValues);
            otherwise
                error('Método categórico desconhecido: %s', opts.categoricalFillMethod);
        end

        col(miss) = fillValue;
        engineData.(varName) = col;

        info.categorical.(varName).missingCount = nMiss;
        info.categorical.(varName).fillValue = fillValue;

        if opts.verbose
            fprintf('     [cat] %-18s -> %3d missing preenchidos com %.0f\n', ...
                varName, nMiss, fillValue);
        end
    end
end
end


