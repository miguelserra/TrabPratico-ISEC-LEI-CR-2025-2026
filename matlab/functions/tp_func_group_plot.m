function tp_func_group_plot(xlsx_path, xlsx_cols, xtickslbl_rot)


    results_tab = readtable(xlsx_path);
    group_summ = groupsummary(results_tab, xlsx_cols, 'mean', {'avg_acc_test', 'avg_err_test'});
    
    cases = string(group_summ.(xlsx_cols(1)));

    if length(xlsx_cols) > 1
        for i = 2:length(xlsx_cols)
            cases = cases + " | " + string(group_summ.(xlsx_cols(i)));
        end
    end

    x     = 1:length(cases);

    acc   = group_summ.mean_avg_acc_test;
    err   = group_summ.mean_avg_err_test;
    

    fig = figure('Color', 'w', 'Position', [100 100 150*length(cases) 400]);
    

    yyaxis left
    bar(x - 0.2, acc, 0.4);
    ylabel('Precisão [%]');
    ylim([0, 100]);
    

    yyaxis right
    bar(x + 0.2, err, 0.4);
    ylabel('Erro (MSE) [%]');
    ylim([0, 35]);
    
    ax = gca;
    ax.XTickLabelRotation = xtickslbl_rot;
    xticks(x);
    xticklabels(cases);
    legend({'Acc', 'MSE'}, 'Location', 'southoutside', 'Orientation', 'horizontal');

    grid on;
    grid minor;
    
    name = join(string(xlsx_cols), "_");
    exportgraphics(fig,"plot_Acc_MSE_" + name + ".png", "Resolution", 300);
    close(fig);
end