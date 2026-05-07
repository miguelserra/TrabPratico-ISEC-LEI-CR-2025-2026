%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT AUXILIAR COM DADOS COMUNS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Este script assume que a variavel tabCaseLib ja existe no workspace.
% Serve para nao repetir, em todos os scripts, a definicao das colunas,
% da pasta de output e do caminho para a pasta functions.

if ~exist('verbose','var')
    verbose = true;
end

% Adiciona a pasta functions ao path, sem adicionar a pasta old.
if exist('project_dir','var') && isfolder(fullfile(project_dir, 'functions'))
    addpath(fullfile(project_dir, 'functions'));
elseif isfolder('functions')
    addpath('functions');
elseif isfolder(fullfile(pwd, 'functions'))
    addpath(fullfile(pwd, 'functions'));
else
    warning('[SETUP] Pasta functions nao encontrada.');
end

if ~exist('tabCaseLib','var')
    error('[SETUP] A variavel tabCaseLib tem de existir antes de chamar tp_3_0_setup_common.');
end

% Colunas de atributos e target.
all_vars   = string(tabCaseLib.Properties.VariableNames);
att_cols   = all_vars(1:end-1);
target_col = all_vars(end);

% Segundo o dataset/enunciado: as ultimas 4 colunas antes do target sao categoricas.
num_att_cols          = att_cols(1:end-4);
categorical_att_cols = att_cols(end-3:end);

% Prepara pasta de output.
if ~exist('output_folder','var')
    output_folder = "";
end

if output_folder ~= ""
    %time = string(datetime('now', 'Format', 'yyyy-MM-dd_HH.mm.ss')).replace(".","h");
    output_folder_path = "./" + output_folder + "/";
    if ~exist(output_folder_path, 'dir')
        mkdir(output_folder_path);
    end
else
    output_folder_path = "";
end

if verbose
    fprintf("\n[SETUP] Configuracao comum carregada.\n");
    fprintf("        Linhas treino      : %d\n", height(tabCaseLib));
    fprintf("        Total de colunas   : %d\n", numel(all_vars));
    fprintf("        Atributos numericos: %d\n", numel(num_att_cols));
    fprintf("        Atributos categor. : %d\n", numel(categorical_att_cols));
    fprintf("        Target             : %s\n", target_col);

    if output_folder_path ~= ""
        fprintf("        Pasta de output    : %s\n", output_folder_path);
    end
end
