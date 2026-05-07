function simMats = get_similarity_matrices()

    simMats.maintenance_level.categories = [1 2 3];   % Low Medium High
    simMats.maintenance_level.matrix = [
        1.0  0.5  0.0
        0.5  1.0  0.5
        0.0  0.5  1.0
    ];

    simMats.operating_mode.categories = [0 1 2];      % Idle Normal Overload
    simMats.operating_mode.matrix = [
        1.0  0.4  0.0
        0.4  1.0  0.6
        0.0  0.6  1.0
    ];

    simMats.cooling_type.categories = [0 1];          % Air Oil
    simMats.cooling_type.matrix = [
        1.0  0.0
        0.0  1.0
    ];

    simMats.sensor_status.categories = [0 1];         % OK Warning
    simMats.sensor_status.matrix = [
        1.0  0.0
        0.0  1.0
    ];

end