function [best3, worst3] = select_best_worst_nn_configs(summaryTable)
% SELECT_BEST_WORST_NN_CONFIGS
% Devolve as 3 melhores e as 3 piores configurações,
% ordenadas pela mean_accuracy_test.

    if height(summaryTable) < 6
        error('A summaryTable deve ter pelo menos 6 configurações.');
    end

    sortedTable = sortrows(summaryTable, 'mean_accuracy_test', 'descend');

    best3 = sortedTable(1:3, :);
    worst3 = sortedTable(end-2:end, :);
end