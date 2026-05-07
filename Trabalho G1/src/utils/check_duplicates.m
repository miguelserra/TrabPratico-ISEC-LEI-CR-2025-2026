[~, idUnique] = unique(engineData, "rows", "stable");
duplicateMask = true(height(engineData), 1);
duplicateMask(idUnique) = false;

numDuplicates = sum(duplicateMask);
disp(numDuplicates)

duplicateRows = engineData(duplicateMask, :);