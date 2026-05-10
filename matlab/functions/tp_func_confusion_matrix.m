function tp_func_confusion_matrix(out_layer, predict, labels, filefullpath, plot_title)


    fig_conf = plotconfusion(out_layer, predict); 

    ax = gca;

    ax.FontSize = 16;

    labels = replace(labels, ["Mechanical", "Electrical", "Failure"], ... 
                             ["Mech ", "Elec ", "Fail"]);


    labels = [transpose(labels(:)), ""];
    ax.XTickLabel = labels;
    ax.YTickLabel = labels;
    ax.XTickLabelRotation = 45;
    ax.YTickLabelRotation = 45;

    txts = findall(fig_conf, 'Type', 'Text');
    set(txts, 'FontSize', 16);

    title(plot_title);
    ax.Title.FontSize = 14;
    ax.Title.FontWeight = 'normal';

    exportgraphics(fig_conf, filefullpath, 'Resolution', 300);
    close(fig_conf);


end