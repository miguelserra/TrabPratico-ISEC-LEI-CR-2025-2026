function [acc] = tp_func_accuracy_NN(target_predict, target_real)

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