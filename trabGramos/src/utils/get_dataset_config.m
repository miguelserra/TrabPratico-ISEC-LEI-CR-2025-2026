
function [numericVars, categoricalVars, targetVar, weights] = get_dataset_config()

% Numéricas contínuas:
% temperature, vibration, rotation_speed, voltage, current,
% pressure, noise_level, efficiency, load_val, torque
numericVars = {'temperature','vibration','rotation_speed','voltage', ...
               'current','pressure','noise_level','efficiency', ...
               'load_val','torque'};

% Categóricas ordinais:
% maintenance_level, operating_mode

% Categóricas binárias/nominais:
% cooling_type, sensor_status
categoricalVars = {'maintenance_level','operating_mode','cooling_type','sensor_status'};

% Target:
% class_cat
targetVar = 'class_cat';

% initial weights
%weights = ones(1, length(numericVars) + length(categoricalVars));
% Ordem: 10 numéricas + 4 categóricas
% [temp, vib, rot, volt, curr, pres, noise, eff, load, torq, maint, mode, cool, sens]
weights = [4, 5, 2, 2, 2, 3, 3, 2, 2, 2, 1, 3, 1, 4];

end
