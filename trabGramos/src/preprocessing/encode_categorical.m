
% maintenance_level foi codificada de forma ordinal:
% Low=1, Medium=2, High=3
% porque os valores têm uma progressão natural de nível de manutenção.

% Ordinais
%maintenance_level: Low=1, Medium=2, High=3
%operating_mode: Idle=0, Normal=1, Overload=2

% Binárias nominais
%cooling_type: Air=0, Oil=1
%sensor_status: OK=0, Warning=1

function engineData = encode_categorical(engineData)

    % Garantir que as colunas estão em string
    engineData.maintenance_level = string(engineData.maintenance_level);
    engineData.operating_mode    = string(engineData.operating_mode);
    engineData.cooling_type      = string(engineData.cooling_type);
    engineData.sensor_status     = string(engineData.sensor_status);

    % maintenance_level: Low=1, Medium=2, High=3
    ml = NaN(height(engineData),1);
    ml(engineData.maintenance_level == "Low")    = 1;
    ml(engineData.maintenance_level == "Medium") = 2;
    ml(engineData.maintenance_level == "High")   = 3;
    engineData.maintenance_level = ml;

    % operating_mode: Idle=0, Normal=1, Overload=2
    om = NaN(height(engineData),1);
    om(engineData.operating_mode == "Idle")    = 0;
    om(engineData.operating_mode == "Normal")  = 1;
    om(engineData.operating_mode == "Overload") = 2;
    engineData.operating_mode = om;
   

    % cooling_type: Air=0, Oil=1
    ct = NaN(height(engineData),1);
    ct(engineData.cooling_type == "Air") = 0;
    ct(engineData.cooling_type == "Oil") = 1;
    engineData.cooling_type = ct;


    % sensor_status: OK=0, Warning=1
    ss = NaN(height(engineData),1);
    ss(engineData.sensor_status == "OK") = 0;
    ss(engineData.sensor_status == "Warning") = 1;
    engineData.sensor_status = ss;

end