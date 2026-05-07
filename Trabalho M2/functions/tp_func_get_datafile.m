function file_path = tp_func_get_datafile(file_name)
%TP_FUNC_GET_DATAFILE Localiza um ficheiro dentro da pasta DADOS.
%   Permite correr o projeto quando a pasta DADOS está dentro da pasta do
%   projeto ou quando está no nível acima (../DADOS), como estava previsto
%   originalmente em alguns scripts.

    if isstring(file_name)
        file_name = char(file_name);
    end

    func_dir = fileparts(mfilename('fullpath'));
    project_dir = fileparts(func_dir);

    candidates = {
        fullfile(project_dir, 'DADOS', file_name), ...
        fullfile(project_dir, '..', 'DADOS', file_name), ...
        fullfile(pwd, 'DADOS', file_name), ...
        fullfile(pwd, '..', 'DADOS', file_name)
    };

    file_path = '';
    for i = 1:numel(candidates)
        if isfile(candidates{i})
            file_path = candidates{i};
            return;
        end
    end

    error("[TRAB PRATICO] Ficheiro de dados não encontrado: %s", file_name);
end
