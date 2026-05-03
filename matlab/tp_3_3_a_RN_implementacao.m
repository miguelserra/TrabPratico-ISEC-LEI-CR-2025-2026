%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETROS ESTUDO PARAM. DE TREINO REDES NEURONAIS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parametros quanto aos dados de entrada
%type_imput = ["Median" , "MICE"]; 
t_imput   = "MICE"              ; % tipo de imputaçao de fill nans
type_data = [ "ORIG"  , "NORM"] ; %tipos de dados - originais ou normalizado

% parametros quanto à topologia das redes neuronais
topology = {10; [5 5]; 6; [3 3]; 12; [6 6]; [4 4 4]} ;  

% parametros de treino 
training_fun   = ["trainlm", "trainbfg", "traingd"];
transf_fun_hid = ["poslin" , "logsig"  , "tansig"];
transf_fun_out = ["purelin", "logsig" ];

% proporçoes de treino/validaçao/teste
data_split_proportions = {[0.7 0.15 0.15], [0.7 0.2 0.1], [0.9, 0.05, 0.05]};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_file         = @tp_func_get_xlfile      ;
normalize_values = @tp_func_rescale         ;
denorm_values    = @tp_func_rescale_reverse ;
nn_ff            = @tp_func_feedforwardNN   ;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%
clc;
fprintf("\n\nTarefa: IMPLEMENTACAO DE REDES NEURONAIS --- A Iniciar..\n\n");

% nome do ficheiro do dataset de teste
name = "dataset_TP";

% nome da pasta de output
output_folder = "OUTPUT_3.3.a_RN_IMPL";


%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
%&&&  ARRANQUE DO ESTUDO PARAMETRICO   &&&
%&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

% le o ficheiro excel do dataset desejado para dentro de tabCaseLib
wildcard = "*_TRATAM*/*" + t_imput + "/*_ORIG_*.xlsx";
ds_file_path = get_file(wildcard);
tabCaseLib = readtable(ds_file_path);

% se for o normalizado, temos de importar o ficheiro de max e min
wildcard = "*_TRATAM*/*" + t_imput + "/*_PARAMS_*.mat";
params_file_path = get_file(wildcard);
load(params_file_path); % load de dict_att_min e dict_att_max

% prepara as pastas e nomes comuns via script aux
tp_3_0_setup_common;
% neste script ficam definidas as variaveis: 
%       tabCaseLib
%       tabCaseLib_T_base
%       all_vars
%       att_cols
%       target_col
%       num_att_cols
%       categorical_att_cols
%       output_folder_path
%       time

% Transforma a coluna do target em 3 colunas binarias 
unique_outputs = unique(tabCaseLib{:,target_col});
target_outputs = flip(string(unique_outputs));
for col_name = transpose(target_outputs)
    tabCaseLib.(col_name) = double( strcmp( col_name, tabCaseLib.(target_col) ) );
end

% elimina a coluna class_cat/target_col
tabCaseLib.(target_col) = [];


for t_data = type_data

    if t_data == "NORM"
        % rescale dos datasets treino e de teste (apenas att numericos)
        % so os attributos numericos senao da' cabo das matrizes sim
        cols_min = dict_att_min(att_cols);
        cols_max = dict_att_max(att_cols);
        tabCaseLib{:,att_cols} = normalize_values(tabCaseLib{:,att_cols}, cols_min, cols_max);
    end

    nn_setup.input_layer  = transpose(tabCaseLib{:,att_cols});
    nn_setup.output_layer = transpose(tabCaseLib{:,target_outputs});
    
    for topo = transpose(topology)
        nn_setup.topology = topo;

        for trainf = training_fun
            nn_setup.training_fun = trainf;

            for transffHid = transf_fun_hid
                nn_setup.transf_fun_hid = transffHid;

                for transffOut = transf_fun_out
                    nn_setup.transf_fun_out = transffOut;
                    
                    for proportions = data_split_proportions
                        nn_setup.data_split = proportions;

                        for i = 1 : 10
                            results = nn_ff(nn_setup);
                        end

                    end
                end
            end
        end
    end

end



