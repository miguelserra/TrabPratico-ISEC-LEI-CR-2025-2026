function folder_path = tp_func_get_xlfile(wildcard_str)

    items = dir(wildcard_str);
    folders = items(~[items.isdir]);
    
    if isempty(folders)
        error("[TRAB PRATICO] Nenhum ficheiro com o wildcard '" + wildcard_str + "' foi encontrado.");
    end
    
    [~, idx] = sort({folders.name});
    most_recent_idx = idx(end);
    
    target_folder = folders(most_recent_idx).folder;
    target_name = folders(most_recent_idx).name;
    
    folder_path = fullfile(target_folder, target_name);
end