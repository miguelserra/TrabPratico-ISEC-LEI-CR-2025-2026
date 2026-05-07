%% TP MAIN - Execucao completa do Trabalho Pratico
% Este ficheiro serve como menu principal do projeto.
% Vai correndo os scripts por ordem e explica o que cada fase faz.
%
% IMPORTANTE:
% - Executar este ficheiro a partir da pasta principal do projeto.
% - A pasta DADOS deve estar na raiz do projeto.
% - A pasta functions deve estar na raiz do projeto.

clc;
close all;

fprintf("\n======================================================\n");
fprintf(" TRABALHO PRATICO - CBR E REDES NEURONAIS\n");
fprintf(" MAIN DE EXECUCAO\n");
fprintf("======================================================\n\n");

fprintf("Este main executa o projeto por fases:\n");
fprintf("  1) Tratamento do dataset\n");
fprintf("  2) Testes CBR\n");
fprintf("  3) Demonstração do ciclo CBR\n");
fprintf("  4) Estudo parametrico das Redes Neuronais\n");
fprintf("  5) Comparacao RN com dataset bruto vs normalizado\n");
fprintf("  6) Guardar as melhores Redes Neuronais\n");
fprintf("  7) Testar as melhores RN no dataset de teste\n");
fprintf("  8) Comparar CBR vs RN\n\n");

fprintf("A adicionar pasta functions ao path...\n");

if ~isfolder("functions")
    error("A pasta 'functions' nao foi encontrada. Verifica se estas na raiz do projeto.");
end

addpath("functions");

if ~isfolder("DADOS")
    error("A pasta 'DADOS' nao foi encontrada. Coloca a pasta DADOS na raiz do projeto.");
end

fprintf("Pastas principais encontradas.\n\n");

input("Prima ENTER para iniciar a FASE 1 - Tratamento do dataset...", "s");


%% ======================================================
% FASE 1 - TRATAMENTO DO DATASET
% =======================================================

fprintf("\n======================================================\n");
fprintf(" FASE 1 - TP 3.1 - TRATAMENTO DO DATASET\n");
fprintf("======================================================\n");
fprintf("Objetivo:\n");
fprintf("  - Ler dataset_TP.csv e dataset_TP_test.csv\n");
fprintf("  - Identificar atributos numericos, categoricos e target\n");
fprintf("  - Gerar graficos exploratorios\n");
fprintf("  - Converter variaveis categoricas para numeros\n");
fprintf("  - Preencher valores em falta nos atributos\n");
fprintf("  - Preencher valores em falta na classe usando CBR\n");
fprintf("  - Guardar datasets tratados e parametros de normalizacao\n\n");

run("tp_3_1_tratamento_do_dataset.m");

fprintf("\nFASE 1 concluida.\n");
input("Prima ENTER para continuar para a FASE 2 - Testes CBR...", "s");


%% ======================================================
% FASE 2 - TESTES CBR
% =======================================================

fprintf("\n======================================================\n");
fprintf(" FASE 2 - TP 3.2.b - TESTES DO CBR\n");
fprintf("======================================================\n");
fprintf("Objetivo:\n");
fprintf("  - Usar os datasets tratados na fase 1\n");
fprintf("  - Testar CBR com Median e MICE\n");
fprintf("  - Testar dados originais e normalizados\n");
fprintf("  - Testar diferentes conjuntos de pesos\n");
fprintf("  - Calcular taxa de acerto e similaridade media\n");
fprintf("  - Guardar tabela resumo e grafico dos resultados\n\n");

run("tp_3_2_b_CBR_testes.m");

fprintf("\nFASE 2 concluida.\n");
input("Prima ENTER para continuar para a FASE 3 - Demonstração CBR...", "s");


%% ======================================================
% FASE 3 - IMPLEMENTACAO / DEMONSTRACAO CBR
% =======================================================

fprintf("\n======================================================\n");
fprintf(" FASE 3 - TP 3.2.a - IMPLEMENTACAO DO CICLO CBR\n");
fprintf("======================================================\n");
fprintf("Objetivo:\n");
fprintf("  - Demonstrar o ciclo CBR completo\n");
fprintf("  - Retrieve: procurar casos semelhantes\n");
fprintf("  - Reuse: reutilizar a solucao encontrada\n");
fprintf("  - Revise: rever/ajustar a solucao\n");
fprintf("  - Retain: guardar o novo caso na base de casos\n\n");

fprintf("Nota: este script pode pedir interacao ao utilizador.\n\n");

run("tp_3_2_a_CBR_implementacao.m");

fprintf("\nFASE 3 concluida.\n");
input("Prima ENTER para continuar para a FASE 4 - Redes Neuronais...", "s");


%% ======================================================
% FASE 4 - ESTUDO PARAMETRICO DAS REDES NEURONAIS
% =======================================================

fprintf("\n======================================================\n");
fprintf(" FASE 4 - TP 3.3.a - ESTUDO PARAMETRICO DAS RN\n");
fprintf("======================================================\n");
fprintf("Objetivo:\n");
fprintf("  - Criar matrizes de entrada e target binario\n");
fprintf("  - Testar varias topologias de rede\n");
fprintf("  - Testar varias funcoes de treino\n");
fprintf("  - Testar varias funcoes de ativacao\n");
fprintf("  - Testar diferentes divisoes treino/validacao/teste\n");
fprintf("  - Registar medias de erro, acerto e tempo de treino\n\n");

fprintf("Nota: esta fase pode demorar, porque treina varias redes.\n\n");

run("tp_3_3_a_RN_implementacao.m");

fprintf("\nFASE 4 concluida.\n");
input("Prima ENTER para continuar para a FASE 5 - Bruto vs Normalizado...", "s");


%% ======================================================
% FASE 5 - RN DATASET BRUTO VS NORMALIZADO
% =======================================================

fprintf("\n======================================================\n");
fprintf(" FASE 5 - TP 3.3.b - RN BRUTO VS NORMALIZADO\n");
fprintf("======================================================\n");
fprintf("Objetivo:\n");
fprintf("  - Comparar o desempenho das RN com dados originais\n");
fprintf("  - Comparar o desempenho das RN com dados normalizados\n");
fprintf("  - Analisar impacto da normalizacao\n");
fprintf("  - Gerar resultados e matrizes de confusao\n\n");

run("tp_3_3_b_RN_dataset_bruto_vs_norm.m");

fprintf("\nFASE 5 concluida.\n");
input("Prima ENTER para continuar para a FASE 6 - Guardar melhores RN...", "s");


%% ======================================================
% FASE 6 - GUARDAR AS MELHORES REDES
% =======================================================

fprintf("\n======================================================\n");
fprintf(" FASE 6 - TP 3.3.c - GUARDAR MELHORES RN\n");
fprintf("======================================================\n");
fprintf("Objetivo:\n");
fprintf("  - Ler os resultados do estudo parametrico\n");
fprintf("  - Identificar as 3 melhores configuracoes\n");
fprintf("  - Treinar novamente essas configuracoes\n");
fprintf("  - Guardar as 3 melhores redes neuronais em ficheiros .mat\n\n");

if exist("tp_3_3_c_guardar_melhores_RN.m", "file")
    run("tp_3_3_c_guardar_melhores_RN.m");
else
    fprintf("AVISO: O ficheiro tp_3_3_c_guardar_melhores_RN.m ainda nao existe.\n");
    fprintf("Esta fase sera ignorada.\n");
end

fprintf("\nFASE 6 concluida.\n");
input("Prima ENTER para continuar para a FASE 7 - Testar melhores RN...", "s");


%% ======================================================
% FASE 7 - TESTAR MELHORES REDES NO DATASET DE TESTE
% =======================================================

fprintf("\n======================================================\n");
fprintf(" FASE 7 - TP 3.3.d - TESTAR MELHORES RN\n");
fprintf("======================================================\n");
fprintf("Objetivo:\n");
fprintf("  - Carregar as 3 melhores redes guardadas\n");
fprintf("  - Aplicar as redes ao dataset_TP_test.csv\n");
fprintf("  - Calcular taxa de acerto global\n");
fprintf("  - Calcular taxa de acerto por classe\n");
fprintf("  - Gerar matrizes de confusao\n\n");

if exist("tp_3_3_d_testar_melhores_RN.m", "file")
    run("tp_3_3_d_testar_melhores_RN.m");
else
    fprintf("AVISO: O ficheiro tp_3_3_d_testar_melhores_RN.m ainda nao existe.\n");
    fprintf("Esta fase sera ignorada.\n");
end

fprintf("\nFASE 7 concluida.\n");
input("Prima ENTER para continuar para a FASE 8 - Comparacao CBR vs RN...", "s");


%% ======================================================
% FASE 8 - COMPARACAO CBR VS REDES NEURONAIS
% =======================================================

fprintf("\n======================================================\n");
fprintf(" FASE 8 - TP 3.4 - COMPARACAO CBR VS RN\n");
fprintf("======================================================\n");
fprintf("Objetivo:\n");
fprintf("  - Comparar os melhores resultados do CBR\n");
fprintf("  - Comparar os melhores resultados das Redes Neuronais\n");
fprintf("  - Analisar vantagens e limitacoes de cada metodo\n");
fprintf("  - Gerar tabela final para o relatorio\n\n");

if exist("tp_3_4_CBR_vs_RN.m", "file")
    run("tp_3_4_CBR_vs_RN.m");
else
    fprintf("AVISO: O ficheiro tp_3_4_CBR_vs_RN.m ainda nao existe.\n");
    fprintf("Esta fase sera ignorada.\n");
end


%% ======================================================
% FIM
% =======================================================

fprintf("\n======================================================\n");
fprintf(" EXECUCAO DO PROJETO CONCLUIDA\n");
fprintf("======================================================\n\n");

fprintf("Resumo das fases:\n");
fprintf("  1) Dataset tratado\n");
fprintf("  2) CBR testado\n");
fprintf("  3) Ciclo CBR demonstrado\n");
fprintf("  4) Redes neuronais treinadas/testadas\n");
fprintf("  5) Bruto vs normalizado comparado\n");
fprintf("  6) Melhores redes guardadas, se script existir\n");
fprintf("  7) Melhores redes testadas, se script existir\n");
fprintf("  8) CBR vs RN comparado, se script existir\n\n");

fprintf("Verifica as pastas de output criadas pelos scripts.\n");