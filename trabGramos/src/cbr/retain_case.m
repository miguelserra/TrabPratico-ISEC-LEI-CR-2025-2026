function [updatedCaseBase, retained] = retain_case(caseBase, revisedCase, saveFile)
% RETAIN_CASE
% Pergunta ao utilizador se quer guardar o caso na case base.
% Opcionalmente guarda também a nova case base num ficheiro.

    if nargin < 3
        saveFile = '';
    end

    updatedCaseBase = caseBase;
    retained = false;

    fprintf('\n--- RETAIN ---\n');
    answer = input('Pretende guardar este caso na case base? (s/n): ', 's');

    if strcmpi(answer, 's')
        updatedCaseBase = [caseBase; revisedCase];
        retained = true;
        fprintf('-> Caso adicionado à case base.\n');

        if ~isempty(saveFile)
            [folder,~,~] = fileparts(saveFile);
            if ~exist(folder, 'dir')
                mkdir(folder);
            end
            writetable(updatedCaseBase, saveFile);
            fprintf('-> Case base guardada em: %s\n', saveFile);
        end
    else
        fprintf('-> Caso não guardado.\n');
    end
end