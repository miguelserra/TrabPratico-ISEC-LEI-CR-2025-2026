function tab = tp_func_encode_categoricals(tab)
%TP_FUNC_ENCODE_CATEGORICALS Converte atributos categóricos para códigos numéricos.
%   A mesma codificação é usada em todos os scripts, garantindo consistência
%   entre treino e teste.

    tab.maintenance_level = double(categorical(tab.maintenance_level, {'Low', 'Medium', 'High'}));
    tab.operating_mode    = double(categorical(tab.operating_mode   , {'Idle', 'Normal', 'Overload'}));
    tab.cooling_type      = double(categorical(tab.cooling_type     , {'Air', 'Oil'}));
    tab.sensor_status     = double(categorical(tab.sensor_status    , {'OK', 'Warning'}));
end
