function tabCaseLib_dict = tp_func_fill_nans(tabCaseLib, categorical_attr_col, ignore_cols)
%TP_FUNC_FILL_NANS Preenche valores em falta nos atributos.
%   Produz duas versoes:
%   - Median: numericos por mediana e categoricos por moda;
%   - MICE: imputacao iterativa simples baseada em regressao linear.
%
%   Esta implementacao usa apenas MATLAB base. Nao usa Statistics Toolbox.

    col_names = string(tabCaseLib.Properties.VariableNames);
    categorical_attr_col = string(categorical_attr_col);
    ignore_cols = string(ignore_cols);

    mask_nans = ismissing(tabCaseLib);

    % colunas a imputar: todas menos as ignoradas, normalmente o target
    attr_cols = setdiff(col_names, ignore_cols, 'stable');

    % Pre-preenchimento: mediana para numericos e moda para categoricos.
    % Este tambem serve como ponto inicial do MICE.
    col_num_nans = sum(mask_nans);

    for i = 1:numel(attr_cols)

        attr_col_name = attr_cols(i);
        idx = find(col_names == attr_col_name);

        if col_num_nans(idx) > 0
            if ~any(categorical_attr_col == attr_col_name)
                val_inicial = median(tabCaseLib.(attr_col_name), 'omitnan');
            else
                val_inicial = mode(tabCaseLib.(attr_col_name));
            end

            tabCaseLib.(attr_col_name)(mask_nans(:, idx)) = val_inicial;
        end
    end

    % OUTPUT 1 - dataset com NaNs substituidos por mediana/moda
    tabCaseLib_median = tabCaseLib;

    % Criterios de paragem do MICE
    tol       = 1e-4;
    max_iter  = 100;
    delta_reg = [];

    delta_curr = Inf;
    iter = 0;

    while delta_curr > tol && iter < max_iter

        iter = iter + 1;

        tabCaseLib_old = tabCaseLib{:, attr_cols};

        for i = 1:numel(attr_cols)

            attr_col = attr_cols(i);
            idx_attr_col = find(col_names == attr_col);

            % So se recalculam colunas que tinham NaNs originalmente.
            if col_num_nans(idx_attr_col) == 0
                continue;
            end

            predict_cols = setdiff(attr_cols, attr_col, 'stable');
            mask_attr_rows = mask_nans(:, idx_attr_col);
            mask_predict_rows = ~mask_attr_rows;

            X_p = tabCaseLib{mask_predict_rows, predict_cols};
            Y_p = tabCaseLib{mask_predict_rows, attr_col};

            % Protecao: se nao houver linhas suficientes, mantem o pre-preenchimento.
            if isempty(X_p) || isempty(Y_p)
                continue;
            end

            X_p_1 = [ones(size(X_p, 1), 1), X_p];
            coefs = X_p_1 \ Y_p;

            X_missing = tabCaseLib{mask_attr_rows, predict_cols};
            X_missing_1 = [ones(size(X_missing, 1), 1), X_missing];
            Y_estim = X_missing_1 * coefs;

            % Categoricos codificados devem continuar inteiros e dentro do intervalo real.
            if any(categorical_attr_col == attr_col)
                valores_validos = tabCaseLib.(attr_col)(~mask_nans(:, idx_attr_col));
                min_val = min(valores_validos);
                max_val = max(valores_validos);
                Y_estim = max(min(round(Y_estim), max_val), min_val);
            end

            tabCaseLib.(attr_col)(mask_attr_rows) = Y_estim;
        end

        tabCaseLib_new = tabCaseLib{:, attr_cols};
        delta_curr = max(max(abs(tabCaseLib_new - tabCaseLib_old)));
        delta_reg(iter) = delta_curr;

        fprintf('         MICE iter %i -> Delta: %.6f\n', iter, delta_curr);
    end

    % Plot de convergencia MICE sem toolboxes extra.
    if iter > 0
        fig = figure('Name', 'Convergencia MICE', 'Visible', 'off');
        plot(1:iter, delta_reg, '-o', 'LineWidth', 2);
        xlabel('Iteracao');
        ylabel('Variacao');
        title('Convergencia MICE para valores em falta');
        set(gca, 'YScale', 'log');
        grid on;
        saveas(fig, 'Convergencia MICE.jpg');
        close(fig);
    end

    % OUTPUT 2 - dataset com NaNs substituidos por MICE
    tabCaseLib_mice = tabCaseLib;

    tabCaseLib_dict = dictionary(["Median", "MICE"], {tabCaseLib_median, tabCaseLib_mice});
end
