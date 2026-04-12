function tabDS_dict = tp_func_fill_nans(tabDS, categorical_attr_col, ignore_cols)

    col_names = tabDS.Properties.VariableNames;
    mask_nans = ismissing(tabDS);
    
    % cria um dataframe sem a variavel de saida
    attr_cols = setdiff(col_names, ignore_cols, 'stable'); %'stable' mantem a ordem do array

    % pre-preenche os nans com a mediana que serve de ponto de partida do
    % MICE
    col_num_nans = sum(mask_nans);
    for i = 1:length(attr_cols)

        attr_col_name = attr_cols{i};
        idx = find(strcmp(col_names, attr_col_name));

        if col_num_nans(idx) > 0
            val_inicial = median(tabDS.(attr_col_name), 'omitnan'); % omitnan para nao considerar nans no calc
            tabDS.(attr_col_name)(mask_nans(:, idx)) = val_inicial;
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OUTPUT 1 - dataset com nans substituidos por medianas %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tabDS_median = tabDS;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % criterios de paragem do MICE
    tol         = 1e-4;
    max_iter    = 100;     
    delta_reg   = [];
    
    
    delta_curr  = 1e10;
    iter        = 0;
    while delta_curr > tol && iter < max_iter
        
        iter = iter + 1;
        
        % guardar a tabela para comparar variaçao
        tabDS_old = tabDS{:, attr_cols};
        
        % corre a regressao para cada coluna
        for i = 1:length(attr_cols)
            
            attr_col = attr_cols{i};
            idx_attr_col = find(strcmp(col_names, attr_col));
            
            if col_num_nans(idx_attr_col) == 0
                continue
            end
            
            % a attr_col e' a que queremos estimar neste passo, a predict_cols
            % sao as restantes colunas do set
            predict_cols = setdiff(attr_cols, {attr_col}, 'stable');
            mask_attr_rows = mask_nans(:, idx_attr_col);
            mask_predict_rows = ~mask_attr_rows;
            
            % regressao linear multipla
            % calcula coefs de y = sum(coef_i * x_i) + b
            % X_p e Y_p sao os Xs e Y dos conjunto de linhas completas
            X_p = tabDS{mask_predict_rows, predict_cols};
            Y_p = tabDS{mask_predict_rows, attr_col};
            X_p_1 = [ones(size(X_p, 1), 1), X_p]; 
            coefs = X_p_1 \ Y_p; %regressao aqui
        
            % X_p e Y_p sao os Xs e Y do set de treino
            X_p = tabDS{mask_attr_rows, predict_cols};
            X_p_1 = [ones(size(X_p, 1), 1), X_p];
            Y_estim = X_p_1 * coefs;
            
            % verifica o maximo e minimo para nao ultrapassar esses valores e
            % arrededonda Y para o int ou (max ou min) das vars categoricas
            if ismember(attr_col, categorical_attr_col)
                min_val = min(tabDS.(attr_col)(~mask_nans(:, idx_attr_col)));
                max_val = max(tabDS.(attr_col)(~mask_nans(:, idx_attr_col)));
                Y_estim = max(min(round(Y_estim), max_val), min_val);
            end
            
            % uma vez trabalhados os valores, atribui-se o resultado da
            % regressao às posiçoes com nan na coluna alvo
            tabDS.(attr_col)(mask_attr_rows) = Y_estim;
        end
        
        % calcula convergencia
        tabDS_new = tabDS{:, attr_cols};
        delta_curr = max(max(abs(tabDS_new - tabDS_old)));
        delta_reg(iter) = delta_curr;
        
        fprintf('iter %i -> Delta: %.6f\n', iter, delta_curr);
    end
    
    % plot de convergencia
    fig = figure('Name', 'Convergencia MICE', 'visible','off');
    plot(1:iter, delta_reg, '-o', 'LineWidth', 2, 'MarkerFaceColor', 'b');
    xlabel('Iteraçao'); ylabel('Variaçao');
    title('Convergencia MICE para valores em falta, entre iteraçoes');
    set(gca, 'YScale', 'log');
    grid on;
    saveas(fig,'Convergencia MICE','jpg');
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % OUTPUT 2 - dataset com nans substituidos por MICE %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tabDS_mice = tabDS;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    tabDS_dict = dictionary(["Median", "MICE"], {tabDS_median, tabDS_mice});

end