function file_path = tp_func_get_xlfile(wildcard_str)
%TP_FUNC_GET_XLFILE Procura um ficheiro usando wildcard.
%
% Exemplo:
%   ficheiro = tp_func_get_xlfile("*_TRATAM*/Median/*_ORIG_*.xlsx");

    if isstring(wildcard_str)
        wildcard_str = char(wildcard_str);
    end

    items = dir(wildcard_str);
    files = items(~[items.isdir]);

    if isempty(files)
        error("[TP] Nenhum ficheiro encontrado com o wildcard: %s", wildcard_str);
    end

    % Escolhe o ficheiro mais recente
    [~, idx] = max([files.datenum]);

    file_path = fullfile(files(idx).folder, files(idx).name);
end