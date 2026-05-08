%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT AUXILIAR COM DADOS COMUNS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
addpath('functions');

% colunas de atributos

if ~exist('tabCaseLib', 'var')
    tabCaseLib = readtable("../DADOS/" + name + ".csv");
end

all_vars = string(tabCaseLib.Properties.VariableNames);
att_cols = all_vars(1:end-1);
target_col = all_vars(end);

% colunas de atributos numericos
num_att_cols = att_cols(1:end-4);

% colunas de atributos do tipo categorico a serem processadas
categorical_att_cols = att_cols(end-3:end);

%prepara pasta de output
if output_folder ~= ""
    time = string(datetime('now', 'Format', 'yyyy-MM-dd_HH.mm')).replace(".","h");
    output_folder_path = "./" + output_folder + "_" + time + "/";
    mkdir(output_folder_path)
end