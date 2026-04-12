function [new_temperature] = tp_func_reuse(retrieved_cases, new_case)

    clc
    clear
    
    %set non-random seed
    rng('default');
    rng(1);
    
    % input data
    filename = 'fertility_Diagnosis.txt';
    delimiterIn = ',';
    Data = importdata(filename,delimiterIn);
        
    % create training and testing matrices
    [entries, attributes] = size(Data);
    entries_breakpoint = round(entries*.90); %set breakpoint for training and testing data at 90% of dataset
    inputlayersize = 9;
    outputlayersize = attributes - inputlayersize;
    
    trainingdata = Data(1:entries_breakpoint,:); %truncate first 90% entries for training data
    trainingdata_inputs = trainingdata(:,1:inputlayersize); %90%x9 matrix input training data
    trainingdata_outputs = trainingdata(:,inputlayersize+1:end); %90:1 matrix output training data
    
    testingdata = Data(entries_breakpoint:end,:); %truncate last 10 entries for testing data
    testingdata_inputs = testingdata(:,1:inputlayersize); %10:9 matrix input testing data
    testingdata_outputs = testingdata(:,inputlayersize+1:end); %10:1 matrix output testing data  
          
    error_tolerance = 0.05;
    hiddenlayersize = 7;
    
    %initialize random synapse weights AND biases with a mean of 0
    syn0 = 2*rand(inputlayersize, hiddenlayersize) - 1; 
    bias0 = 2*rand(1, hiddenlayersize) - 1; 
    
    syn1 = 2*rand(hiddenlayersize, outputlayersize) - 1; 
    bias1 = 2*rand(1, outputlayersize) - 1; 
      
    %feedforward untrained training data
    layer0 = trainingdata_inputs;
    layer1 = 1 ./ (1 + exp(-1 .* (layer0 * syn0 + bias0))); 
    layer2 = 1 ./ (1 + exp(-1 .* (layer1 * syn1 + bias1))); 
    
    %check for accuracy
    err = immse(layer2, trainingdata_outputs);
    fprintf("Untrained: Mean Squared Error with Trainingdata: %f\n", err)
    
    %feedforward untrained testing data
    layer0_test = testingdata_inputs;
    layer1_test = 1 ./ (1 + exp(-1 .* (layer0_test * syn0 + bias0))); 
    layer2_test = 1 ./ (1 + exp(-1 .* (layer1_test * syn1 + bias1))); 
    
    %check for accuracy
    err_test = immse(layer2_test, testingdata_outputs);
    fprintf("Untrained: Mean Squared Error with Testingdata: %f\n", err_test)
    
    %best alpha for fertilitydata = 0.001
    for alpha = [0.001]

        fprintf("Training with alpha: %f\n", alpha)
        
        for iter = 1:1000000
            % feedforward
            layer0 = trainingdata_inputs;
            layer1 = 1 ./ (1 + exp(-1 .* (layer0 * syn0 + bias0))); 
            layer2 = 1 ./ (1 + exp(-1 .* (layer1 * syn1 + bias1))); 
    
            % cost function (how much did we miss)
            layer2_error = layer2 - trainingdata_outputs;
    
            % which direction is the target value (using optimized derivative: L*(1-L))
            layer2_delta = layer2_error .* (layer2 .* (1 - layer2));
    
            % how much did each l1 value contribute to l2 error
            layer1_error = layer2_delta * syn1.';
    
            % which direction is target l1 (using optimized derivative: L*(1-L))
            layer1_delta = layer1_error .* (layer1 .* (1 - layer1));
    
            % adjust values (weights and biases)
            errorval = mean(abs(layer2_error));
            
            syn1 = syn1 - alpha .* (layer1.' * layer2_delta);
            syn0 = syn0 - alpha .* (layer0.' * layer1_delta);
            
            bias1 = bias1 - alpha .* sum(layer2_delta, 1);
            bias0 = bias0 - alpha .* sum(layer1_delta, 1);
            

            % pelos vistos a comunidade IA favorece o for+break em det do
            % while-loop com dupla condiçao
            if errorval < error_tolerance
                fprintf("Stopping at: %f error\n", errorval)
                break
            end
                
            %print out debug data
            if iter == 1 || mod(iter,100000) == 0
                fprintf("\titer=%.0f, Error: %f\n", iter, errorval)
            end      
        end
        
        if errorval > error_tolerance
            fprintf("Value Below Tolerance not found, please adjust alpha\n\n")
        else
            fprintf("Value Below Tolerance found: %f\n\n", errorval)
        end
    end
    
    %feedforward trained training data
    layer0 = trainingdata_inputs;
    layer1 = 1 ./ (1 + exp(-1 .* (layer0 * syn0 + bias0))); 
    layer2 = 1 ./ (1 + exp(-1 .* (layer1 * syn1 + bias1))); 
    err = immse(layer2, trainingdata_outputs);
    fprintf("Trained: Mean Squared Error with Trainingdata: %f\n", err)
    
    %feedforward trained testing data
    layer0_test = testingdata_inputs;
    layer1_test = 1 ./ (1 + exp(-1 .* (layer0_test * syn0 + bias0))); 
    layer2_test = 1 ./ (1 + exp(-1 .* (layer1_test * syn1 + bias1))); 
    err_test = immse(layer2_test, testingdata_outputs);
    fprintf("Trained: Mean Squared Error with Testingdata: %f\n", err_test)


end

