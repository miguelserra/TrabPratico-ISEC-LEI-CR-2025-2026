%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCRIPT AUXILIAR COM DADOS COMUNS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% le o dataset para uma tabela/dataframe
tabDS = readtable("../DADOS/" + name + ".csv");

% colunas de atributos
all_vars = string(tabDS.Properties.VariableNames);
att_cols = all_vars(1:end-1);
target_col = all_vars(end);

% colunas de atributos numericos
num_att_cols = att_cols(1:end-4);

% colunas de atributos do tipo categorico a serem processadas
categorical_att_cols = att_cols(end-3:end);

%prepara pasta de output
time = string(datetime('now', 'Format', 'yyyy-MM-dd_HH.mm')).replace(".","h");
output_folder_path = "./" + output_folder + "_" + time + "/";
mkdir(output_folder_path)
mkdir(output_folder_path + "Common/")
mkdir(output_folder_path + "Median/")
mkdir(output_folder_path + "MICE/")