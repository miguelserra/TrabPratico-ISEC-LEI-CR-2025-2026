function folder_path = tp_func_get_xlfile(wildcard_str)

    itens = dir(wildcard_str);
    folders = itens([itens.isdir]);
    
    if isempty(folders)
        error("[TRAB PRATICO] Nenhuma pasta com o wildcard '" + wildcard_str + "' foi encontrada.");
    end
    
    folders_names = {folders.name};
    sorted_folders_names = sort(folders_names);
    
    most_recent = sorted_folders_names{end};
    folder_path = fullfile(pwd, most_recent);



end