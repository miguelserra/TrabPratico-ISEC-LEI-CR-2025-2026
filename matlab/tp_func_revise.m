function [case_idx, new_case] = tp_func_revise(retrieved_indexes, new_case, new_temperature)
    
    code = str2double('-');
        
    while isnan(code) || fix(code) ~= code || ismember(code, retrieved_indexes) == 0
        fprintf('Dos casos devolvidos pelo Revise, qual se apresenta mais proximo do Novo Caso?\n');
        code = str2double(input('Indice do caso: ','s'));
    end
    
    case_idx = fix(code);

    %REVISE TEMPERATURA
    fprintf('\nActualizar a temperatura com valor dado pela Rede Neuronal? (y/n) \n');
    option = input('Option: ','s');

    if option == 'y' || option == 'Y'
        new_case.temperature = new_temperature;
    end

end

