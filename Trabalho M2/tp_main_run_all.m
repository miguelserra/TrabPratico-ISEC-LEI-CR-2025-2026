function tp_main_run_all()
%% TP_MAIN_RUN_ALL - Execucao completa automatica do projeto
% Este main corre os scripts principais por ordem, sem pausas.
%
% Antes de correr:
%   1) Confirmar que estas na raiz do projeto
%   2) Confirmar que existem as pastas DADOS e functions
%   3) Para execucao final das RN, no tp_3_3_a_RN_implementacao.m:
%          modo_rapido = false;
%   4) No tp_3_3_b_RN_dataset_bruto_vs_norm.m:
%          num_reps_compare = 10;
%   5) No tp_3_3_c_guardar_melhores_RN.m:
%          num_reps_save = 10;
%
% Output:
%   - Cria pasta LOGS
%   - Guarda um ficheiro .txt com tudo o que apareceu na consola

    clc;
    close all;

    fprintf("\n======================================================\n");
    fprintf(" EXECUCAO AUTOMATICA DO TRABALHO - CBR E RN\n");
    fprintf("======================================================\n\n");

    %% CONFIGURACOES DO MAIN

    % Se estiver true, para logo no primeiro erro.
    % Para deixar correr mesmo com erros, mete false.
    STOP_ON_ERROR = true;

    % O script 3.2.a e interativo.
    % Se meteres true, ele pode ficar parado a pedir inputs.
    RUN_CBR_DEMO_INTERATIVO = false;

    %% PREPARAR PROJETO

    project_dir = fileparts(mfilename('fullpath'));

    if project_dir == ""
        project_dir = pwd;
    end

    cd(project_dir);

    if ~isfolder("DADOS")
        error("A pasta DADOS nao foi encontrada na raiz do projeto.");
    end

    if ~isfolder("functions")
        error("A pasta functions nao foi encontrada na raiz do projeto.");
    end

    addpath("functions");
    evalin('base', 'addpath("functions");');

    if ~isfolder("LOGS")
        mkdir("LOGS");
    end

    log_name = "LOGS/log_execucao_completa_" + ...
        string(datetime("now", "Format", "yyyyMMdd_HHmmss")) + ".txt";

    diary(log_name);
    diary on;

    fprintf("Pasta do projeto: %s\n", project_dir);
    fprintf("Log da execucao: %s\n", log_name);
    fprintf("STOP_ON_ERROR = %d\n", STOP_ON_ERROR);
    fprintf("RUN_CBR_DEMO_INTERATIVO = %d\n", RUN_CBR_DEMO_INTERATIVO);
    fprintf("\n");

    fprintf("ATENCAO:\n");
    fprintf("Se queres testar TODAS as configuracoes finais das RN,\n");
    fprintf("confirma que no tp_3_3_a_RN_implementacao.m tens:\n");
    fprintf("    modo_rapido = false;\n\n");

    total_start = tic;

    %% LISTA DE SCRIPTS A CORRER

    scripts = {
        "tp_3_1_tratamento_do_dataset.m", ...
        "Tratamento do dataset";

        "tp_3_2_b_CBR_testes.m", ...
        "Testes automaticos do CBR";

        "tp_3_3_a_RN_implementacao.m", ...
        "Estudo parametrico das Redes Neuronais";

        "tp_3_3_b_RN_dataset_bruto_vs_norm.m", ...
        "Comparacao RN com dataset original vs normalizado";

        "tp_3_3_c_guardar_melhores_RN.m", ...
        "Guardar as 3 melhores Redes Neuronais";

        "tp_3_3_d_testar_melhores_RN.m", ...
        "Testar melhores RN no dataset de teste";

        "tp_3_4_CBR_vs_RN.m", ...
        "Comparacao final CBR vs Redes Neuronais";
    };

    % Opcional: script interativo do ciclo CBR completo
    if RUN_CBR_DEMO_INTERATIVO
        scripts = [
            scripts(1:2, :);
            {
                "tp_3_2_a_CBR_implementacao.m", ...
                "Demonstracao interativa do ciclo CBR"
            };
            scripts(3:end, :)
        ];
    end

    %% EXECUCAO

    num_scripts = size(scripts, 1);
    summary = cell(num_scripts, 4);

    for i = 1:num_scripts

        script_file = scripts{i, 1};
        script_desc = scripts{i, 2};

        fprintf("\n\n======================================================\n");
        fprintf(" FASE %d/%d\n", i, num_scripts);
        fprintf(" Script: %s\n", script_file);
        fprintf(" Objetivo: %s\n", script_desc);
        fprintf("======================================================\n\n");

        if ~isfile(script_file)

            msg = "FICHEIRO NAO ENCONTRADO";

            fprintf("ERRO: O ficheiro %s nao existe.\n", script_file);

            summary{i, 1} = script_file;
            summary{i, 2} = script_desc;
            summary{i, 3} = msg;
            summary{i, 4} = NaN;

            if STOP_ON_ERROR
                break;
            else
                continue;
            end
        end

        fase_start = tic;

        try
            % Corre no workspace base.
            % Assim, se o script tiver clear/clc, nao apaga as variaveis deste main.
            evalin('base', "run('" + script_file + "')");

            elapsed = toc(fase_start);

            fprintf("\nFASE %d concluida com sucesso.\n", i);
            fprintf("Tempo da fase: %.2f segundos | %.2f minutos\n", elapsed, elapsed/60);

            summary{i, 1} = script_file;
            summary{i, 2} = script_desc;
            summary{i, 3} = "OK";
            summary{i, 4} = elapsed;

        catch ME

            elapsed = toc(fase_start);

            fprintf("\nERRO NA FASE %d\n", i);
            fprintf("Script: %s\n", script_file);
            fprintf("Mensagem: %s\n", ME.message);
            fprintf("Tempo ate ao erro: %.2f segundos\n", elapsed);

            if ~isempty(ME.stack)
                fprintf("\nStack do erro:\n");
                for k = 1:numel(ME.stack)
                    fprintf("  %s | linha %d\n", ME.stack(k).name, ME.stack(k).line);
                end
            end

            summary{i, 1} = script_file;
            summary{i, 2} = script_desc;
            summary{i, 3} = "ERRO: " + string(ME.message);
            summary{i, 4} = elapsed;

            if STOP_ON_ERROR
                fprintf("\nA execucao foi interrompida porque STOP_ON_ERROR = true.\n");
                break;
            end
        end
    end

    %% RESUMO FINAL

    total_elapsed = toc(total_start);

    fprintf("\n\n======================================================\n");
    fprintf(" RESUMO FINAL DA EXECUCAO\n");
    fprintf("======================================================\n\n");

    for i = 1:num_scripts

        if isempty(summary{i, 1})
            continue;
        end

        fprintf("%d) %s\n", i, summary{i, 1});
        fprintf("   Objetivo: %s\n", summary{i, 2});
        fprintf("   Estado: %s\n", string(summary{i, 3}));

        if ~isnan(summary{i, 4})
            fprintf("   Tempo: %.2f segundos | %.2f minutos\n", summary{i, 4}, summary{i, 4}/60);
        end

        fprintf("\n");
    end

    fprintf("Tempo total: %.2f segundos | %.2f minutos | %.2f horas\n", ...
        total_elapsed, total_elapsed/60, total_elapsed/3600);

    fprintf("\nLog guardado em:\n%s\n", log_name);

    fprintf("\nPastas de output esperadas:\n");
    fprintf("  OUTPUT_3.1_TRATAMENTO\n");
    fprintf("  OUTPUT_3.2.b_CBR_TESTS\n");
    fprintf("  OUTPUT_3.3.a_RN_IMPL\n");
    fprintf("  OUTPUT_3.3.b_RN_ORIG_VS_NORM\n");
    fprintf("  OUTPUT_3.3.c_MELHORES_RN\n");
    fprintf("  OUTPUT_3.3.d_TESTE_MELHORES_RN\n");
    fprintf("  OUTPUT_3.4_CBR_vs_RN\n");

    diary off;

    fprintf("\nExecucao terminada. Verifica o ficheiro de log em LOGS.\n");
end