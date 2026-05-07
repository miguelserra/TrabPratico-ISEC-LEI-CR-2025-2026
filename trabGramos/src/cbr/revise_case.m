function [revisedCase, accepted] = revise_case(newCase, proposedTemp)
% REVISE_CASE
% Pergunta ao utilizador se quer substituir a temperature pelo valor proposto.

    revisedCase = newCase;
    accepted = false;

    fprintf('\n--- REVISE ---\n');

    if isnan(newCase.temperature)
        fprintf('Temperature atual: missing\n');
    else
        fprintf('Temperature atual: %.4f\n', newCase.temperature);
    end

    fprintf('Temperature proposta pela RN: %.4f\n', proposedTemp);

    answer = input('Aceita substituir a temperature? (s/n): ', 's');

    if strcmpi(answer, 's')
        revisedCase.temperature = proposedTemp;
        accepted = true;
        fprintf('-> Temperature atualizada.\n');
    else
        fprintf('-> Temperature mantida.\n');
    end
end