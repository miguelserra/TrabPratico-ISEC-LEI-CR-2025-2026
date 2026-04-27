
%%%%%%%%%%%%%%%%%%%
% INPUT NOVO CASO %
%%%%%%%%%%%%%%%%%%%

similarity_threshold = 0.9;

clear struct_new_case;
struct_new_case.temperature        = 68.16126505 ;
struct_new_case.vibration          = 2.8537325   ;
struct_new_case.rotation_speed     = 1527.084843 ;
struct_new_case.voltage            = 230.198028  ;
struct_new_case.current            = 11.45129021 ;
struct_new_case.pressure           = 5.838895141 ;
struct_new_case.noise_level        = 83.15363686 ;
struct_new_case.efficiency         = 0.777862081 ;
struct_new_case.load_val           = 62.05525774 ;
struct_new_case.torque             = 151.566407  ;
struct_new_case.maintenance_level  = 'Low'       ;
struct_new_case.operating_mode     = 'Overload'  ;
struct_new_case.cooling_type       = 'Air'       ;
struct_new_case.sensor_status      = 'OK'        ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP DATASET E PESOS CBR %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% casos de analise
type_imput        = "MICE";  %tipos de imputaçao de fill nans
type_data         = "NORM";  %tipos de dados - originais ou normalizados
weighting_factors = "w";






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HANDLES DE FUNCOES                                               %
%                        !!! IMPORTANTE !!!                        %
% >>> REVER SEMPRE ESTE SETOR QUANDO SE ALTERAREM FUNÇOES!!!!! <<< %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
retrieve = @tp_func_retrieve    ;
reuse    = @tp_func_reuse       ;
revise   = @tp_func_revise      ;
retain   = @tp_func_retain      ;
get_file = @tp_func_get_xlfile  ;



%%%%%%%%%%%%%%%%%%%%%%%
% PREPARAÇAO DE DADOS %
%%%%%%%%%%%%%%%%%%%%%%%

clc;
fprintf("\n\nTarefa: IMPLEMENTACAO DE CBR --- A Iniciar..\n\n");

% nome do ficheiro do dataset de teste
name = "dataset_TP";

% nome da pasta de output (nao cria outputs se = "")
%output_folder = "";
output_folder = "OUTPUT_3.2.a_CBR_IMPL";

% importa o dataset - abre o original, nao o normalizado (so' para NN)
wildcard = "*_TRATAM*/*" + type_imput + "/*_ORIG_*.xlsx";
ds_file_path = get_file(wildcard);
tabCaseLib = readtable(ds_file_path);

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

% temos de importar o ficheiro de max e min de cada coluna
% e usa-lo para normalizar o struct_new_case
wildcard = "*_TRATAM*/*" + type_imput + "/*_PARAMS_*.mat";
params_file_path = get_file(wildcard);
load(params_file_path);

dict_wf = dictionary(  ["w", "w2", "1s" , "soCat"]      ,   ...
                     { [5,5,4,2,4,1,3,3,3,3,3,2,2,3]    ,   ... pesos estimados, w
                       [25,25,16,4,16,1,9,9,9,9,9,4,4,9],   ... w^2
                       [1,1,1,1,1,1,1,1,1,1,1,1,1,1]    ,   ... tudo 1s
                       [0,0,0,0,0,0,0,0,0,0,1,1,1,1]   });  ... so categoricos

wf = dict_wf{weighting_factors};

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONVERSAO DADOS ENTRADA %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

struct_new_case.maintenance_level = double( categorical(string(struct_new_case.maintenance_level), ["Low", "Medium", "High"] ));
struct_new_case.operating_mode    = double( categorical(string(struct_new_case.operating_mode   ), ["Idle", "Normal", "Overload"] ));
struct_new_case.cooling_type      = double( categorical(string(struct_new_case.cooling_type     ), ["Air", "Oil"] ));
struct_new_case.sensor_status     = double( categorical(string(struct_new_case.sensor_status    ), ["OK", "Warning"] ));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%
% PREPARAÇAO CBR %
%%%%%%%%%%%%%%%%%%

% cria o placeolder para a class_cat (evita erro no retrieve..)
struct_new_case.class_cat = "";

% converte a struct struct_new_case para tabela
tabNewCase = struct2table(struct_new_case, 'AsArray', true);

if type_data == "NORM"
    % rescaling do novo caso para os valores continuos
    col_min = dict_att_min(num_att_cols);
    col_max = dict_att_max(num_att_cols);

    tabCaseLib{:, num_att_cols} = (tabCaseLib{:, num_att_cols} - col_min) ./ (col_max - col_min);
    tabNewCase{:, num_att_cols} = (tabNewCase{:, num_att_cols} - col_min) ./ (col_max - col_min);
end


%%%%%%%%%%%%%%
%  RETRIEVE  %
%%%%%%%%%%%%%%

[ retrieved_indexes , retrieved_simil] = retrieve( tabCaseLib(:,all_vars) ,   ...
                                                   tabNewCase(:,all_vars) ,   ...
                                                   similarity_threshold   ,   ...
                                                   wf     );

if size(retrieved_indexes, 1) == 0
    error("[Retrieve] [ERRO] Não foram devolvidas soluçoes. Ajustar Threshold!!\n\n");
end

retrieved_cases = tabCaseLib(retrieved_indexes, :);
retrieved_cases.similarity = retrieved_simil;

retrieved_cases_orig = retrieved_cases;
retrieved_cases_orig{:,num_att_cols} = retrieved_cases{:,num_att_cols} .* (col_max - col_min) + col_min;


col_idx = table(retrieved_indexes, 'VariableNames', "Indice");
retrieved_cases_orig = [col_idx, retrieved_cases_orig];

fprintf("\n[Retrieve] Lista de casos com similaridade acima de %.2f%%\n\n", similarity_threshold * 100);
disp(retrieved_cases_orig)

if output_folder ~= ""
    path = output_folder_path + "/out_RETRIEVED_CASES_" + t_imput + "_"+ t_data + "_" + weighting_factors + ".xlsx";
    writetable(retrieved_cases_orig, path);
end


%%%%%%%%%%%%%
%   REUSE   %
%%%%%%%%%%%%%

[new_temp_norm, ff_error] = reuse(retrieved_cases, tabNewCase);

tmax = col_max(1);
tmin = col_min(1);
new_temp_orig = new_temp_norm * (tmax - tmin) + tmin;

fprintf("\n[Reuse] Temperatura prevista para o Novo Caso é = %.3fºC (MSError_treino= %.3f%%)\n\n", new_temp_orig, ff_error);


%%%%%%%%%%%%
%  REVISE  %
%%%%%%%%%%%%

[case_idx, struct_new_case] = revise(retrieved_indexes, struct_new_case, new_temp_orig);

struct_new_case.class_cat = tabCaseLib{case_idx, "class_cat"};

fprintf("\n[Revise] Caso %i foi seleccionado com exito\n", case_idx);
if struct_new_case.temperature == new_temp_orig
    fprintf("[Revise] Temperatura do caso %i alterado para %.3fºC\n", case_idx, new_temp_orig);
end
disp(struct_new_case);


%%%%%%%%%%%%
%  RETAIN  %
%%%%%%%%%%%%
if output_folder ~= ""
    path = output_folder_path + "/out" + "_" + t_imput + "_"+ t_data + "_" + "datasetTP_with_retained.xlsx";
    writetable(retrieved_cases_orig, path);
    retain(tabCaseLib, struct_new_case, path);
else
    fprintf("[Retain] Sem pasta de output definida. A sair...");
end

