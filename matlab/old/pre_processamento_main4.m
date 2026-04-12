tabledf         = readtable('../dataset_TP_num.xlsx');

% vars categoricas que precisam de ser arredondadas 'a unidade (a regressão
% devolve valores float mas as vars sao descritas com int)
categorical_vars = {'maintenance_level', 'operating_mode', 'cooling_type', 'sensor_status'};



% pre-preenche os nans com a mediana, como ponto de partida
col_num_nans = sum(mask_nans);
for i = 1:length(target_cols)
    target_col_name = target_cols{i};
    idx = find(strcmp(col_names, target_col_name));
    if col_num_nans(idx) > 0
        val_inicial = median(tabledf.(target_col_name), 'omitnan'); % Mediana é mais robusta
        tabledf.(target_col_name)(mask_nans(:, idx)) = val_inicial;
    end
end

% criterios de paragem do MICE
tol         = 1e-4;
max_iter    = 100;     
delta_reg   = [];


delta_curr  = 1e10;
iter        = 0;
while delta_curr > tol && iter < max_iter
    
    iter = iter + 1;
    
    % guardar a tabela para comparar variaçao
    tabledf_old = tabledf{:, target_cols};
    
    % corre a regressao para cada coluna
    for i = 1:length(target_cols)
        
        target_col = target_cols{i};
        idx_target_col = find(strcmp(col_names, target_col));
        
        if col_num_nans(idx_target_col) == 0
            continue
        end
        
        % a target_col e' a que queremos estimar neste passo, a predict_cols
        % sao as restantes colunas do set
        predict_cols = setdiff(target_cols, {target_col}, 'stable');
        mask_target_rows = mask_nans(:, idx_target_col);
        mask_predict_rows = ~mask_target_rows;
        
        % regressao linear multipla
        % calcula coefs de y = sum(coef_i * x_i) + b
        %X_p e Y_p sao os Xs e Y dos conjunto de linhas completas
        X_p = tabledf{mask_predict_rows, predict_cols};
        Y_p = tabledf{mask_predict_rows, target_col};
        X_p_1 = [ones(size(X_p, 1), 1), X_p]; 
        coefs = X_p_1 \ Y_p; %regressao aqui
    
        % X_p e Y_p sao os Xs e Y do set de treino
        X_p = tabledf{mask_target_rows, predict_cols};
        X_p_1 = [ones(size(X_p, 1), 1), X_p];
        Y_estim = X_p_1 * coefs;
        
        % verifica o maximo e minimo para nao ultrapassar esses valores e
        % arrededonda Y para o int ou (max ou min) das categorias
        if ismember(target_col, categorical_vars)
            min_val = min(tabledf.(target_col)(~mask_nans(:, idx_target_col)));
            max_val = max(tabledf.(target_col)(~mask_nans(:, idx_target_col)));
            Y_estim = max(min(round(Y_estim), max_val), min_val);
        end
        
        % uma vez trabalhados os valores, atribui-se o resultado da
        % regressao às posiçoes com nan na coluna alvo
        tabledf.(target_col)(mask_target_rows) = Y_estim;
    end
    
    % calcula convergencia
    tabledf_new = tabledf{:, target_cols};
    delta_curr = max(max(abs(tabledf_new - tabledf_old)));
    delta_reg(iter) = delta_curr;
    
    fprintf('iter %i -> Delta: %.6f\n', iter, delta_curr);
end

% plot de convergencia
figure('Name', 'Convergencia MICE');
plot(1:iter, delta_reg, '-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
xlabel('Iteraçao'); ylabel('Variação');
title('Convergencia MICE para valores em falta, entre iteraçoes');
set(gca, 'YScale', 'log');
grid on;


% output
fprintf("\n\n\n  #############################################\n")
fprintf("  ############# RESUMO RESULTADOS #############\n")
fprintf("  #############################################\n\n")
disp(table(col_names', sum(ismissing(tabledf))', 'VariableNames', {'Coluna', 'NaNs_Restantes'}));
writetable(tabledf, 'dataset_TP_num_mice.xlsx');