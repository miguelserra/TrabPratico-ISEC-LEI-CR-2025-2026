function ranges = get_ranges(engineData, numericVars)
% Calcula o range de cada variável numérica: max - min
% Se o range for 0, coloca 1 para evitar divisões por zero.
    ranges = struct();

    for i = 1:length(numericVars)
        varName = numericVars{i};
        col = engineData.(varName);
    
        ranges.(varName) = max(col) - min(col);

        if ranges.(varName) == 0
            warning(['Variable ', varName, ' has no range (all values are the same).']);
            ranges.(varName) = 1; % Assign 1
        end
            
    end
end