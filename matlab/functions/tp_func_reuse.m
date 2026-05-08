function [new_temperature, ff_error] = tp_func_reuse(tabRetrievedCases, tabNewCase)
  
    % BASEADO NO CODIGO APRESENTADO EM
    % https://www.instructables.com/Simple-Neural-Network-in-Matlab-for-Predicting-Sci/
    % Modificoes inclui introduçao de Bias
    % Não se fez set de validaçao porque temos apenas os poucos casos do CBR Retrieve


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % SETUP REDE NEURONAL FEEDFORWARD %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    input_cols  = ["vibration","rotation_speed","voltage"];
    output_cols = ["temperature"];
    

    error_tol = 0.05;
    
    hidden_layer_size = 3       ;  % tam camada intermedia calculada por 2/3*(N_out-N_inp)
    alpha             = 0.001   ;  % coef de aprendizagem
    epochs            = 10000   ;  % numero de epocas de treino

    
    % força uma randomizaçao eficaz
    rng('shuffle', 'twister'); 

    
    %%%%%%%%%%
    % SCRIPT %
    %%%%%%%%%%

    % Assume que tabRetrievedCases vem normalizada para os atributos numericos!
    % caso algo se altere, devem ser normalizados aqui
    inputs  = tabRetrievedCases{:,input_cols };
    outputs = tabRetrievedCases{:,output_cols};
    
    input_layer_size  = length(input_cols);
    output_layer_size = length(output_cols);
    
    % iniciar pesos e bias com valores aleatorios
    w0 = 2*rand(input_layer_size, hidden_layer_size) - 1; 
    b0 = 2*rand(1, hidden_layer_size) - 1; 
    w1 = 2*rand(hidden_layer_size, output_layer_size) - 1; 
    b1 = 2*rand(1, output_layer_size) - 1; 
      

    for iter = 1:epochs

        % feedforward usando expressão do sigmoide
        layer0 = inputs;
        layer1 = 1 ./ (1 + exp(-1 .* (layer0 * w0 + b0))); 
        layer2 = 1 ./ (1 + exp(-1 .* (layer1 * w1 + b1))); 

        % regra delta
        layer2_error = layer2 - outputs;

        % delta local ( atraves da derivada da funcao sigmoide L*(1-L) ) 
        layer2_delta = layer2_error .* (layer2 .* (1 - layer2));

        % erro transferido para a layer1
        layer1_error = layer2_delta * transpose(w1);

        % delta local ( atraves da derivada da funcao sigmoide L*(1-L) )
        layer1_delta = layer1_error .* (layer1 .* (1 - layer1));

        % ajuste de pesos
        error_val = mean(abs(layer2_error));
        
        w1 = w1 - alpha .* (transpose(layer1) * layer2_delta);
        w0 = w0 - alpha .* (transpose(layer0) * layer1_delta);
        
        b1 = b1 - alpha .* sum(layer2_delta, 1);
        b0 = b0 - alpha .* sum(layer1_delta, 1);
        

        % pelos vistos a comunidade IA favorece o for+break em det do
        % while-loop com dupla condiçao
        if error_val < error_tol
            break
        end
            
    end
    
    if error_val > error_tol
        fprintf("Não foi encontrado erro abaixo da tolerancia. Alterar coef. de aprendizagem (alpha) ou tolerancia de erro.\n\n")
    end


    % calculo do erro
    layer0 = inputs;
    layer1 = 1 ./ (1 + exp(-1 .* (layer0 * w0 + b0))); 
    layer2 = 1 ./ (1 + exp(-1 .* (layer1 * w1 + b1))); 
    ff_error = mean((layer2(:) - outputs(:)).^2)*100;


    % extrai os sensores do NOVO motor
    new_input = tabNewCase{:, input_cols};
    
    % faz o Feedforward usando os pesos TREINADOS
    layer1_new = 1 ./ (1 + exp(-1 .* (new_input * w0 + b0))); 
    new_temperature = 1 ./ (1 + exp(-1 .* (layer1_new * w1 + b1))); 
    

end





