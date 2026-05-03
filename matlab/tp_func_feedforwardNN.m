function [net, acc_val, acc_test] = tp_func_feedforwardNN(neural_network_setup, hidden_calc, print_figs)
    
    %%%%%%%%%
    % SETUP %
    %%%%%%%%%
    
    case_name = neural_network_setup.case_name + "_R-" + neural_network_setup.num_run;
    
    fprintf("\nA correr: %s\n", case_name)

    % bloquear  
    if hidden_calc
        set(0, 'DefaultFigureVisible', 'off');
    end

    inp_layer = neural_network_setup.input_layer;   
    out_layer = neural_network_setup.output_layer;

    if size(inp_layer,1) == size(out_layer,1)
        inp_layer = transpose(inp_layer);
        out_layer = transpose(out_layer);
    end
    
    num_hid_layers = length(neural_network_setup.topology);

    net = feedforwardnet(   neural_network_setup.topology, ...
                            neural_network_setup.training_fun   );
    
    % divisao do dataset
    net.divideFcn = 'dividerand'; % por defeito, p/ todos os casos
    net.divideParam.trainRatio = neural_network_setup.data_split(1);
    net.divideParam.valRatio   = neural_network_setup.data_split(2);
    net.divideParam.testRatio  = neural_network_setup.data_split(3);

    % atribuiçao da func de ativacao 'a(s) camada(s) escondida(s)
    
    for i = 1: num_hid_layers
        net.layers{i}.transferFcn = neural_network_setup.transf_fun_hid;
    end
    
    % funcs de ativacao da(s) escondida(s)
    net.layers{num_hid_layers + 1}.transferFcn = neural_network_setup.transf_fun_out;

   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TREINO COM SUB-DATASET DE TREINO VS SUB-DATSET DE VALIDACAO %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if hidden_calc
        net.trainParam.showWindow = false;
    end

    [net,tr] = train(net, inp_layer, out_layer);
    
    out_val  = sim(net, inp_layer);
    
    if print_figs
        plotconfusion(out_layer, out_val);
        fig_conf = gcf;
        conf_mat_path = "PlotConfusao_"+ case_name + ".png" ;
        exportgraphics(fig_conf, conf_mat_path, 'Resolution', 300);
        close(fig_conf);

        plotperf(tr);
        fig_perf = gcf;
        perf_path = "PlotPerform_"+ case_name + ".png" ;
        exportgraphics(fig_perf, perf_path, 'Resolution', 300);
        close(fig_perf);
    end

    inp_layer_val = inp_layer(:, tr.valInd);
    out_layer_val = out_layer(:, tr.valInd);
    out_val = sim(net, inp_layer_val);
    
    error_val = perform(net, out_val, out_layer_val);
    acc_val   = accuracy(out_val, out_layer_val);

    fprintf("\nErro na classificaçao (fase de validaçao) = %f\n", error_val);
    fprintf("Precisao total (fase de validaçao) = %f\n", acc_val);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % VALIDAÇAO FINAL VS SUB-DATSET DE TESTE %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    inp_layer_test = inp_layer(:, tr.testInd);
    out_layer_test = out_layer(:, tr.testInd);

    out_test = sim(net, inp_layer_test);

    error_test = perform(net, out_test, out_layer_test);
    acc_test   = accuracy(out_test, out_layer_test);
    fprintf('\nErro na classificaçao (fase de teste) = %f\n', error_test)
    fprintf("Precisao total (fase de teste) = %f\n", acc_test)

    % reativa plot de figuras
    set(0, 'DefaultFigureVisible', 'on');
end



function [acc] = accuracy(target_predict, target_real)

    %Calcula e mostra a percentagem de classificacoes corretas

    r=0;
    for i=1:size(target_predict,2)

        % Para cada classificacao  
        [ ~ , b ] = max( target_predict(:,i) );  % b guarda a linha onde encontrou valor mais alto da saida obtida
        [ ~ , d ] = max(    target_real(:,i) );  % d guarda a linha onde encontrou valor mais alto da saida desejada
        
        % se estao na mesma linha, a classificacao foi correta (incrementa 1)
        if b == d
            r = r + 1;
        end
    end

    acc = r / size(target_predict,2) * 100;

end