       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
%%%%%%%%%%%%%%%%%%   ROTINA RETRIEVE   %%%%%%%%%%%%%%%%%%
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [retrieved_indexes, similarities] = tp_func_retrieve(case_lib, new_case , threshold, weighting_factors)
    
    num_cases = size(case_lib,1);
    num_att   = size(case_lib,2) - 1;
    att_names = case_lib.Properties.VariableNames(1:end-1);
    att_cols  = case_lib(:,att_names);

    % weighting_factors 
    %weighting_factors = [...
    %    4, ... % 1 temperature
    %    3, ... % 2 vibration
    %    2, ... % 3 rotation speed
    %    4, ... % 4 voltage
    %    3, ... % 5 current
    %    3, ... % 6 pressure
    %    4, ... % 7 noise_level
    %    2, ... % 8 efficiency
    %    2, ... % 9 load_val
    %    4, ... % 10 torque
    %    3, ... % 11 maintenance_level
    %    3, ... % 12 operating_mode
    %    1, ... % 13 cooling_type
    %    4];... % 14 sensor_status
    
    sim_matrices_dic = dictionary();
    sim_matrices_dic("maintenance_level") = get_maintenance_level_similarities();
    sim_matrices_dic("operating_mode")    = get_operating_mode_similarities();
    sim_matrices_dic("cooling_type")      = get_cooling_type_similarities();
    sim_matrices_dic("sensor_status")     = get_sensor_status_similarities();


    
    distances = zeros(num_cases, num_att);
    
    % calculo de distancias de attributos numericos
    for j = 1 : num_att-4
        att_name = att_names{j};
        distances(:, j) = calc_lin_dist(case_lib.(att_name), new_case.(att_name));
    end

    for j = num_att-3 : num_att
           
        att_name = att_names{j};
        sim_matrix = sim_matrices_dic(att_name);

        % for i = 1 : num_cases
        %     distances(i, j) = calc_local_dist( sim_matrix, ...
        %                                            case_lib{i, att_name}, ...
        %                                            new_case{1, att_name});
        % end
        
        % forma vetorizada mais rapida a calcular que o for-loop 
        idx_cases   = case_lib{:, att_name};
        idx_newcase = new_case{1, att_name};

        sims_extraidas = sim_matrix.similarities(idx_cases, idx_newcase);

        distances(:, j) = 1 - sims_extraidas;
        
    end

    distances_1 = distances ./ max(distances);
    weighted_distances = distances_1 * transpose(weighting_factors);
    weighted_distances_norm = weighted_distances / sum(weighting_factors);
    final_similarities = 1 - weighted_distances_norm;
    
    mask = final_similarities >= threshold;
    retrieved_indexes = find(mask);
    similarities = final_similarities(mask);
    

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATRIZES DE SIMILARIDADE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [maintenance_level_sim] = get_maintenance_level_similarities()
    
    order = {'Low', 'Medium', 'High'};
    maintenance_level_sim.categories = double(categorical(order, order));

    maintenance_level_sim.similarities = [
          % Low     Medium  High
            1.0     0.5     0.0   % Low
            0.5     1.0     0.5   % Medium
            0.0     0.5     1.0   % High
    ];

end

function [operating_mode_sim] = get_operating_mode_similarities()
    
    order = {'Idle', 'Normal', 'Overload'};
    operating_mode_sim.categories = double(categorical(order, order));

    operating_mode_sim.similarities = [
          % Idle    Normal  Overload
            1.0     0.3     0.0      % Idle
            0.3     1.0     0.6      % Normal
            0.0     0.6     1.0      % Overload
    ];

end

function [cooling_type_sim] = get_cooling_type_similarities()
    
    order = {'Air', 'Oil'};
    cooling_type_sim.categories = double(categorical(order, order));

    cooling_type_sim.similarities = [
        %   Air     Oil 
            1.0     0.0    % Air
            0.0     1.0    % Oil
    ];

end


function [sensor_status_sim] = get_sensor_status_similarities()
 
    order = {'OK', 'Warning'};
    sensor_status_sim.categories = double(categorical(order, order));

    sensor_status_sim.similarities = [
        %   OK      Warning 
            1.0       0.0    % OK
            0.0       1.0    % Warning
    ];

end


%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULO DE DISTANCIAS %
%%%%%%%%%%%%%%%%%%%%%%%%%

% para atributos categoricos ordinais e nominais
function [dist] = calc_local_dist(sim, val1, val2)
    i1 = find(sim.categories == val1);
    i2 = find(sim.categories == val2);
    dist = 1 - sim.similarities(i1,i2);
end

% para atributos numéricos continuos
function [dist] = calc_lin_dist(val1, val2)
    dist = abs(val1 - val2);
end





