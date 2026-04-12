       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
%%%%%%%%%%%%%%%%%%   ROTINA RETRIEVE   %%%%%%%%%%%%%%%%%%
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [retrieved_indexes, similarities, new_case] = tp_func_retrieve(case_lib, new_case , threshold, weighting_factors)
    
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
    
    sims_dic = dictionary();
    sims_dic("maintenance_level") = get_maintenance_level_similarities();
    sims_dic("operating_mode")    = get_operating_mode_similarities();
    sims_dic("cooling_type")      = get_cooling_type_similarities();
    sims_dic("sensor_status")     = get_sensor_status_similarities();


    max_values = max(att_cols,[],1);
    all_distances = zeros(num_cases, num_att);
    
    % calculo de distancias de attributos numerico
    for j = 1 : num_att-4
        
        att_name = att_names{j};
        max_val = max_values.(att_name);

        % extrai a coluna inteira e o valor do new_case
        base_case_norm = case_lib.(att_name) / max_val;
        new_case_norm = new_case.(att_name) / max_val;
        
        all_distances(:, j) = calc_lin_dist(base_case_norm, new_case_norm);

    end

    for j = num_att-3 : num_att
           
        att_name = att_names{j};
        sims = sims_dic(att_name);

        for i = 1 : num_cases
            all_distances(i, j) = calc_local_dist( sims, ...
                                                   case_lib{i, att_name}, ...
                                                   new_case{1, att_name});
        end
    end


    weighted_distances = all_distances * transpose(weighting_factors);
    final_similarities = 1 - (weighted_distances / sum(weighting_factors));
    
    mask = final_similarities >= threshold;
    retrieved_indexes = find(mask);
    similarities = final_similarities(mask);
    

    %retrieved_indexes = [];
    %similarities      = [];
    %
    %for i = 1 : num_cases
    %    
    %    distances = zeros( 1 , num_att );
    %
    %    % calculo de distancias de attributos numericos
    %    for j = 1 : num_att-4
    %        base_case_norm = case_lib{i,att_names(j)} / max_values{1,att_names(j)};
    %        new_case_norm  = new_case{1,att_names(j)} / max_values{1,att_names(j)};
    %        distances(1,j) = calc_lin_dist(base_case_norm, new_case_norm);
    %    end
    %    
    %    % calculo de distancias de attributos categoricos
    %    for j = num_att-3 : num_att
    %
    %        distances(1,j) = calc_local_dist( sims_dic( att_names(j) )     , ...
    %                                          case_lib{ i , att_names(j) } , ...
    %                                          new_case{ 1 , att_names(j) } );
    %    end
    %
    %
    %    % aplicaçao de pesos 'as distancias
    %    weighted_distance = distances * weighting_factors';
    %
    %    % calculo
    %    normalized_weighted_distance = weighted_distance / sum(weighting_factors);
    %    final_similarity = 1 - normalized_weighted_distance;
    %    
    %
    %    
    %    if final_similarity >= threshold
    %        retrieved_indexes = [retrieved_indexes i];
    %        similarities = [similarities final_similarity];
    %    end
    %    
    %    %fprintf('Case %d out of %d has a similarity of %.2f%%...\n', i, size(case_lib,1), final_similarity*100);
    %end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MATRIZES DE SIMILARIDADE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [maintenance_level_sim] = get_maintenance_level_similarities()

    maintenance_level_sim.categories = double(categorical({'Low', 'Medium', 'High'}));

    maintenance_level_sim.similarities = [
          % Low     Medium  High
            1.0     0.5     0.0   % Low
            0.5     1.0     0.5   % Medium
            0.0     0.5     1.0   % High
    ];

end

function [operating_mode_sim] = get_operating_mode_similarities()

    operating_mode_sim.categories = double(categorical({'Idle', 'Normal', 'Overload'}));

    operating_mode_sim.similarities = [
          % Idle    Normal  Overload
            1.0     0.3     0.0      % Idle
            0.3     1.0     0.6      % Normal
            0.0     0.6     1.0      % Overload
    ];
end

function [cooling_type_sim] = get_cooling_type_similarities()
 
    cooling_type_sim.categories = double(categorical({'Air', 'Oil'}));

    cooling_type_sim.similarities = [
        %   Air     Oil 
            1.0     0.0    % Air
            0.0     1.0    % Oil
    ];

end


function [sensor_status_sim] = get_sensor_status_similarities()
 
    sensor_status_sim.categories = double(categorical({'OK', 'Warning'}));

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





