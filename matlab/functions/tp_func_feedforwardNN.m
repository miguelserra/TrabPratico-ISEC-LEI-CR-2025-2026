function [neural_network_setup] = tp_func_feedforwardNN(neural_network_setup, hidden_calc, print_figs)
    
    %%%%%%%%%
    % SETUP %
    %%%%%%%%%
    
    case_name = neural_network_setup.case_name + "_R" + neural_network_setup.rep_num;
    
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
    
    % desativa a normalizaçao por defeito
    net.inputs{1}.processFcns               = {};
    net.outputs{net.numLayers}.processFcns  = {};

    % evoluçao das epocas
    net.trainParam.epochs = 5000; %neural_network_setup.num_epochs;
    net.trainParam.max_fail = neural_network_setup.epochs_max_fail; % num tentativas apos err min

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
    
    out_predict_val  = sim(net, inp_layer);
    
    error_glob = perform(net, out_predict_val, out_layer) * 100;
    acc_glob   = accuracy(out_predict_val, out_layer);
    
    neural_network_setup.err_glob   = error_glob;
    neural_network_setup.acc_glob   = acc_glob;
    neural_network_setup.tr_time    = tr.time(end);
    neural_network_setup.num_epochs = tr.epoch(end);
    neural_network_setup.best_epoch = tr.best_epoch;
    
    if ~hidden_calc
        fprintf("\nA correr: %s\n", case_name);
        fprintf("\nErro na classificaçao (fase de validaçao) = %f\n", error_glob);
        fprintf("Precisao total (fase de validaçao) = %f\n", acc_glob);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % VALIDAÇAO FINAL VS SUB-DATSET DE TESTE %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    inp_layer_test = inp_layer(:, tr.testInd);
    out_layer_test = out_layer(:, tr.testInd);

    out_predict_test = sim(net, inp_layer_test);

    if print_figs
        plotconfusion(out_layer_test, out_predict_test); 
        plotperf(tr);
    end

    error_test = perform(net, out_predict_test, out_layer_test);
    acc_test   = accuracy(out_predict_test, out_layer_test);
    
    neural_network_setup.err_test         = error_test * 100;
    neural_network_setup.acc_test         = acc_test;
    neural_network_setup.out_layer_test   = out_layer_test;
    neural_network_setup.out_predict_test = out_predict_test;

    
    if ~hidden_calc
        fprintf('\nErro na classificaçao (fase de teste) = %f\n', error_test)
        fprintf("Precisao total (fase de teste) = %f\n", acc_test)
    end

    % reativa plot de figuras
    set(0, 'DefaultFigureVisible', 'on');

    neural_network_setup.net = net;
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