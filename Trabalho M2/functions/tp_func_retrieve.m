       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%   ROTINA RETRIEVE   %%%%%%%%%%%%%%%%%%
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [retrieved_indexes, similarities] = tp_func_retrieve(case_lib, new_case , threshold, weighting_factors)

    num_cases = size(case_lib,1);
    num_att   = size(case_lib,2) - 1;
    att_names = case_lib.Properties.VariableNames(1:end-1);

    if length(weighting_factors) ~= num_att
        error('[Retrieve] O vetor de pesos tem de ter %d valores, mas tem %d.', num_att, length(weighting_factors));
    end

    sim_matrices_dic = dictionary();
    sim_matrices_dic("maintenance_level") = get_maintenance_level_similarities();
    sim_matrices_dic("operating_mode")    = get_operating_mode_similarities();
    sim_matrices_dic("cooling_type")      = get_cooling_type_similarities();
    sim_matrices_dic("sensor_status")     = get_sensor_status_similarities();

    distances = zeros(num_cases, num_att);

    % atributos numericos
    for j = 1 : num_att-4
        att_name = att_names{j};
        distances(:, j) = calc_lin_dist(case_lib.(att_name), new_case.(att_name));
    end

    % atributos categoricos com matrizes de similaridade
    for j = num_att-3 : num_att
        att_name = att_names{j};
        sim_matrix = sim_matrices_dic(att_name);

        idx_cases   = case_lib{:, att_name};
        idx_newcase = new_case{1, att_name};

        sims_extraidas = sim_matrix.similarities(idx_cases, idx_newcase);
        distances(:, j) = 1 - sims_extraidas;
    end

    % normalizacao das distancias locais
    den = max(distances, [], 1);
    den(den == 0) = 1; % se uma coluna tem sempre distancia 0, nao deve gerar NaN
    distances_1 = distances ./ den;

    weighting_factors = weighting_factors(:)';
    sum_w = sum(weighting_factors);
    if sum_w == 0
        error('[Retrieve] A soma dos pesos nao pode ser zero.');
    end

    weighted_distances = distances_1 * transpose(weighting_factors);
    weighted_distances_norm = weighted_distances / sum_w;
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
            1.0     0.5     0.0
            0.5     1.0     0.5
            0.0     0.5     1.0
    ];
end

function [operating_mode_sim] = get_operating_mode_similarities()
    order = {'Idle', 'Normal', 'Overload'};
    operating_mode_sim.categories = double(categorical(order, order));
    operating_mode_sim.similarities = [
          % Idle    Normal  Overload
            1.0     0.3     0.0
            0.3     1.0     0.6
            0.0     0.6     1.0
    ];
end

function [cooling_type_sim] = get_cooling_type_similarities()
    order = {'Air', 'Oil'};
    cooling_type_sim.categories = double(categorical(order, order));
    cooling_type_sim.similarities = [
        %   Air     Oil
            1.0     0.0
            0.0     1.0
    ];
end

function [sensor_status_sim] = get_sensor_status_similarities()
    order = {'OK', 'Warning'};
    sensor_status_sim.categories = double(categorical(order, order));
    sensor_status_sim.similarities = [
        %   OK      Warning
            1.0       0.0
            0.0       1.0
    ];
end

%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULO DE DISTANCIAS %
%%%%%%%%%%%%%%%%%%%%%%%%%

function [dist] = calc_lin_dist(val1, val2)
    dist = abs(val1 - val2);
end
