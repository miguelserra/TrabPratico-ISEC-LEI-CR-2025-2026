function [proposedTemp, net] = reuse_temperature_nn(caseBase, newCase, modelFile, forceRetrain)
% REUSE_TEMPERATURE_NN
% Usa uma rede neuronal feedforward para propor um valor de temperature
% com base em vibration, rotation_speed e voltage.
%
% Entradas:
%   caseBase     - tabela com os casos da base
%   newCase      - tabela com 1 linha
%   modelFile    - caminho .mat para guardar/carregar a rede
%   forceRetrain - true para forçar treino novo
%
% Saídas:
%   proposedTemp - temperatura proposta
%   net          - rede treinada/carregada

    if nargin < 3 || isempty(modelFile)
        modelFile = fullfile('outputs', 'nn', 'reuse_temperature_net.mat');
    end

    if nargin < 4
        forceRetrain = false;
    end

    modelDir = fileparts(modelFile);
    if ~exist(modelDir, 'dir')
        mkdir(modelDir);
    end

    % Carregar rede já treinada, se existir
    if ~forceRetrain && exist(modelFile, 'file')
        S = load(modelFile, 'net');
        net = S.net;
    else
        % Usar só linhas válidas
        validRows = ~isnan(caseBase.temperature) & ...
                    ~isnan(caseBase.vibration) & ...
                    ~isnan(caseBase.rotation_speed) & ...
                    ~isnan(caseBase.voltage);

        X = caseBase{validRows, {'vibration', 'rotation_speed', 'voltage'}}';
        Y = caseBase{validRows, 'temperature'}';

        if isempty(X) || isempty(Y)
            error('Não há dados suficientes para treinar a rede do Reuse.');
        end

        net = fitnet(10, 'trainscg');
        net.trainParam.showWindow = false;
        net.trainParam.epochs = 300;

        net.divideParam.trainRatio = 0.70;
        net.divideParam.valRatio   = 0.15;
        net.divideParam.testRatio  = 0.15;

        net = train(net, X, Y);

        save(modelFile, 'net');
    end

    % Prever temperatura do novo caso
    xNew = newCase{1, {'vibration', 'rotation_speed', 'voltage'}}';

    if any(isnan(xNew))
        error('O novo caso tem valores em falta em vibration, rotation_speed ou voltage.');
    end

    proposedTemp = net(xNew);
    proposedTemp = double(proposedTemp);
end