%% TP 3.4 - Comparacao CBR vs Redes Neuronais
% Este script compara os melhores resultados obtidos com:
%   - CBR
%   - Redes Neuronais
%
% Depende de:
%   - tp_3_2_b_CBR_testes.m
%   - tp_3_3_d_testar_melhores_RN.m

clc;
close all;

fprintf("\n======================================================\n");
fprintf(" TP 3.4 - COMPARACAO CBR VS REDES NEURONAIS\n");
fprintf("======================================================\n\n");

%% CONFIGURACAO

output_folder = "OUTPUT_3.4_CBR_vs_RN";

fprintf("[INFO] Pasta de output: %s\n", output_folder);

%% PREPARAR PROJETO

fprintf("\n[1/5] A preparar projeto...\n");

project_dir = fileparts(mfilename('fullpath'));

if project_dir == ""
    project_dir = pwd;
end

cd(project_dir);

addpath("functions");

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

if ~exist(output_folder + "/Common", 'dir')
    mkdir(output_folder + "/Common");
end

fprintf("      Pasta do projeto: %s\n", project_dir);

%% LER RESULTADOS DO CBR

fprintf("\n[2/5] A ler resultados do CBR...\n");

cbr_file = "OUTPUT_3.2.b_CBR_TESTS/Common/Resultados_CBR.xlsx";

if ~isfile(cbr_file)
    error("Nao foi encontrado o ficheiro: %s\nCorre primeiro o tp_3_2_b_CBR_testes.m", cbr_file);
end

tab_cbr = readtable(cbr_file);

if isempty(tab_cbr)
    error("A tabela de resultados CBR esta vazia.");
end

% Ordenar pelo melhor acerto
tab_cbr = sortrows(tab_cbr, "taxa_acerto", "descend");

best_cbr = tab_cbr(1, :);

fprintf("      Melhor configuracao CBR:\n");
fprintf("      Configuracao: %s\n", string(best_cbr.config));
fprintf("      Taxa de acerto: %.2f%%\n", best_cbr.taxa_acerto);
fprintf("      Similaridade media: %.2f%%\n", best_cbr.similaridade_media);

%% LER RESULTADOS DAS REDES NEURONAIS

fprintf("\n[3/5] A ler resultados das Redes Neuronais...\n");

rn_file = "OUTPUT_3.3.d_TESTE_MELHORES_RN/Common/Resumo_Teste_Melhores_RN.xlsx";

if ~isfile(rn_file)
    error("Nao foi encontrado o ficheiro: %s\nCorre primeiro o tp_3_3_d_testar_melhores_RN.m", rn_file);
end

tab_rn = readtable(rn_file);

if isempty(tab_rn)
    error("A tabela de resultados RN esta vazia.");
end

% Ordenar pela melhor accuracy global
tab_rn = sortrows(tab_rn, "accuracy_global", "descend");

best_rn = tab_rn(1, :);

fprintf("      Melhor Rede Neuronal:\n");
fprintf("      Rede: %s\n", string(best_rn.rede));
fprintf("      Ficheiro: %s\n", string(best_rn.ficheiro_rede));
fprintf("      Accuracy global: %.2f%%\n", best_rn.accuracy_global);

%% CRIAR TABELA COMPARATIVA

fprintf("\n[4/5] A criar tabela comparativa...\n");

metodo = [
    "CBR";
    "Rede Neuronal"
];

melhor_configuracao = [
    string(best_cbr.config);
    string(best_rn.ficheiro_rede)
];

tipo_imputacao = [
    string(best_cbr.type_imput);
    string(best_rn.type_imp)
];

tipo_dados = [
    string(best_cbr.type_data);
    string(best_rn.type_data)
];

parametros = [
    "Pesos: " + string(best_cbr.weights);
    "Topologia: " + string(best_rn.topology) + ...
        " | Treino: " + string(best_rn.training_fun) + ...
        " | Saida: " + string(best_rn.transf_fun_out)
];

taxa_acerto = [
    best_cbr.taxa_acerto;
    best_rn.accuracy_global
];

metrica_secundaria = [
    best_cbr.similaridade_media;
    NaN
];

observacoes = [
    "CBR classifica com base no caso mais semelhante.";
    "RN classifica com base no modelo aprendido durante o treino."
];

tab_comp = table( ...
    metodo, ...
    melhor_configuracao, ...
    tipo_imputacao, ...
    tipo_dados, ...
    parametros, ...
    taxa_acerto, ...
    metrica_secundaria, ...
    observacoes ...
);

out_excel = output_folder + "/Common/Comparacao_CBR_vs_RN.xlsx";
writetable(tab_comp, out_excel);

fprintf("      Tabela comparativa guardada em:\n");
fprintf("      %s\n", out_excel);

%% CRIAR GRAFICO COMPARATIVO

fprintf("\n[5/5] A gerar grafico comparativo...\n");

fig = figure('Visible', 'off', 'Position', [100 100 900 500]);

bar(tab_comp.taxa_acerto);

xticks(1:height(tab_comp));
xticklabels(tab_comp.metodo);

ylabel("Taxa de acerto / Accuracy [%]", "FontWeight", "bold");
ylim([0 100]);

title("Comparacao CBR vs Redes Neuronais");
grid on;

plot_file = output_folder + "/Common/plot_CBR_vs_RN.png";
exportgraphics(fig, plot_file, 'Resolution', 300);
close(fig);

fprintf("      Grafico guardado em:\n");
fprintf("      %s\n", plot_file);

%% CRIAR TEXTO PARA RELATORIO

txt_file = output_folder + "/Common/Resumo_CBR_vs_RN.txt";

fid = fopen(txt_file, "w");

fprintf(fid, "Comparacao CBR vs Redes Neuronais\n");
fprintf(fid, "=================================\n\n");

fprintf(fid, "Melhor resultado CBR:\n");
fprintf(fid, "- Configuracao: %s\n", string(best_cbr.config));
fprintf(fid, "- Tipo de imputacao: %s\n", string(best_cbr.type_imput));
fprintf(fid, "- Tipo de dados: %s\n", string(best_cbr.type_data));
fprintf(fid, "- Pesos: %s\n", string(best_cbr.weights));
fprintf(fid, "- Taxa de acerto: %.2f%%\n", best_cbr.taxa_acerto);
fprintf(fid, "- Similaridade media: %.2f%%\n\n", best_cbr.similaridade_media);

fprintf(fid, "Melhor resultado RN:\n");
fprintf(fid, "- Rede: %s\n", string(best_rn.rede));
fprintf(fid, "- Ficheiro: %s\n", string(best_rn.ficheiro_rede));
fprintf(fid, "- Tipo de imputacao: %s\n", string(best_rn.type_imp));
fprintf(fid, "- Tipo de dados: %s\n", string(best_rn.type_data));
fprintf(fid, "- Topologia: %s\n", string(best_rn.topology));
fprintf(fid, "- Funcao de treino: %s\n", string(best_rn.training_fun));
fprintf(fid, "- Funcao de saida: %s\n", string(best_rn.transf_fun_out));
fprintf(fid, "- Accuracy global: %.2f%%\n\n", best_rn.accuracy_global);

fprintf(fid, "Analise:\n");
fprintf(fid, "O CBR tem a vantagem de ser mais interpretavel, pois a classificacao e baseada nos casos semelhantes encontrados na base de casos.\n");
fprintf(fid, "As Redes Neuronais podem apresentar melhor capacidade de generalizacao, pois aprendem padroes a partir dos dados de treino, mas sao menos interpretaveis.\n");
fprintf(fid, "A escolha do melhor metodo deve considerar nao apenas a taxa de acerto, mas tambem a explicabilidade, o custo computacional e a facilidade de manutencao.\n");

fclose(fid);

fprintf("      Texto resumo guardado em:\n");
fprintf("      %s\n", txt_file);

fprintf("\n======================================================\n");
fprintf(" TP 3.4 concluido.\n");
fprintf("======================================================\n\n");