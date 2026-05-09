function tp_func_confusion_matrix(out_layer, predict, labels, filefullpath)


    fig_conf = plotconfusion(out_layer, predict); 

    ax = gca;

    labels = replace(labels, ["Mechanical", "Electrical", "Failure"], ... 
                             ["Mech ", "Elec ", "Fail"]);

    labels = [transpose(labels(:)), ""];
    ax.XTickLabel = labels;
    ax.YTickLabel = labels;
    

    ax.XTickLabelRotation = 45;
    ax.YTickLabelRotation = 45;

    exportgraphics(fig_conf, filefullpath, 'Resolution', 300);
    close(fig_conf);


end