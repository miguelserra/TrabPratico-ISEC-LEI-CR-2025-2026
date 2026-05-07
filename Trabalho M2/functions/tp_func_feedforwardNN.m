function [neural_network_setup] = tp_func_feedforwardNN(neural_network_setup, hidden_calc, print_figs)
%TP_FUNC_FEEDFORWARDNN Treina e testa uma rede neuronal feedforward.
%
% Entrada:
%   neural_network_setup - estrutura com configuracao da rede
%   hidden_calc          - se true, esconde janelas de treino/figuras
%   print_figs           - se true, mostra plotconfusion e plotperf
%
% Saida:
%   neural_network_setup - mesma estrutura, mas com resultados:
%       net
%       err_glob
%       acc_glob
%       err_test
%       acc_test
%       tr_time
%       num_epochs
%       best_epoch
%       out_layer_test
%       out_predict_test

    %%%%%%%%%
    % SETUP %
    %%%%%%%%%

    case_name = string(neural_network_setup.case_name) + "_R" + string(neural_network_setup.rep_num);

    % Esconder figuras/janelas, se necessario
    if hidden_calc
        set(0, 'DefaultFigureVisible', 'off');
    end

    inp_layer = neural_network_setup.input_layer;
    out_layer = neural_network_setup.output_layer;

    % A rede espera dados no formato:
    %   atributos x casos
    %   classes x casos
    if size(inp_layer, 1) == size(out_layer, 1)
        inp_layer = transpose(inp_layer);
        out_layer = transpose(out_layer);
    end

    % Converter strings para char, para evitar erros no MATLAB
    training_fun   = char(string(neural_network_setup.training_fun));
    transf_fun_hid = char(string(neural_network_setup.transf_fun_hid));
    transf_fun_out = char(string(neural_network_setup.transf_fun_out));

    topology = neural_network_setup.topology;

    num_hid_layers = length(topology);

    % Criar rede
    net = feedforwardnet(topology, training_fun);

    % Parametros de treino
    net.trainParam.epochs = 5000;
    net.trainParam.max_fail = neural_network_setup.epochs_max_fail;

    % Divisao treino / validacao / teste
    net.divideFcn = 'dividerand';
    net.divideParam.trainRatio = neural_network_setup.data_split(1);
    net.divideParam.valRatio   = neural_network_setup.data_split(2);
    net.divideParam.testRatio  = neural_network_setup.data_split(3);

    % Funcoes de ativacao das camadas escondidas
    for i = 1:num_hid_layers
        net.layers{i}.transferFcn = transf_fun_hid;
    end

    % Funcao de ativacao da camada de saida
    net.layers{num_hid_layers + 1}.transferFcn = transf_fun_out;

    % Esconder janela de treino, se necessario
    if hidden_calc
        net.trainParam.showWindow = false;
    end

    %%%%%%%%
    % TREINO
    %%%%%%%%

    [net, tr] = train(net, inp_layer, out_layer);

    % Simulacao global com todos os dados
    out_predict_val = sim(net, inp_layer);

    error_glob = perform(net, out_predict_val, out_layer) * 100;
    acc_glob   = accuracy(out_predict_val, out_layer);

    neural_network_setup.err_glob = error_glob;
    neural_network_setup.acc_glob = acc_glob;

    if ~isempty(tr.time)
        neural_network_setup.tr_time = tr.time(end);
    else
        neural_network_setup.tr_time = NaN;
    end

    if ~isempty(tr.epoch)
        neural_network_setup.num_epochs = tr.epoch(end);
    else
        neural_network_setup.num_epochs = NaN;
    end

    if isfield(tr, 'best_epoch')
        neural_network_setup.best_epoch = tr.best_epoch;
    else
        neural_network_setup.best_epoch = NaN;
    end

    if ~hidden_calc
        fprintf("\nA correr: %s\n", case_name);
        fprintf("Erro global = %.4f\n", error_glob);
        fprintf("Precisao global = %.2f%%\n", acc_glob);
    end

    %%%%%%%%%%%%%%%
    % TESTE DA REDE
    %%%%%%%%%%%%%%%

    inp_layer_test = inp_layer(:, tr.testInd);
    out_layer_test = out_layer(:, tr.testInd);

    out_predict_test = sim(net, inp_layer_test);

    if print_figs
        figure;
        plotconfusion(out_layer_test, out_predict_test);

        figure;
        plotperf(tr);
    end

    error_test = perform(net, out_predict_test, out_layer_test) * 100;
    acc_test   = accuracy(out_predict_test, out_layer_test);

    neural_network_setup.err_test         = error_test;
    neural_network_setup.acc_test         = acc_test;
    neural_network_setup.out_layer_test   = out_layer_test;
    neural_network_setup.out_predict_test = out_predict_test;

    if ~hidden_calc
        fprintf("Erro teste = %.4f\n", error_test);
        fprintf("Precisao teste = %.2f%%\n", acc_test);
    end

    % Guardar tambem a rede treinada.
    % Isto e essencial para o ponto 3.3.c.
    neural_network_setup.net = net;
    neural_network_setup.train_record = tr;

    % Reativar figuras
    set(0, 'DefaultFigureVisible', 'on');
end


function [acc] = accuracy(target_predict, target_real)
%ACCURACY Calcula a percentagem de classificacoes corretas.

    r = 0;

    for i = 1:size(target_predict, 2)

        % Classe prevista
        [~, b] = max(target_predict(:, i));

        % Classe real
        [~, d] = max(target_real(:, i));

        if b == d
            r = r + 1;
        end
    end

    acc = r / size(target_predict, 2) * 100;
end