
tabledf = readtable('../dataset_TP_num.xlsx');
arr_subsets_cols = table2array(readtable('lista_subsets.xlsx'));

%PARTE 1 - determina quantos valores em falta existem em cada coluna
col_name = tabledf.Properties.VariableNames;
col_num_nans = sum(ismissing(tabledf));
dic_num_nans = dictionary(col_name, col_num_nans);

total_nans = 0;
new_total_nans = 1;
iter = 0;
offset = 0;
while new_total_nans > 0 && iter < 4

    iter = iter + 1;
    fprintf("Iteraçao = %i, offset = %i\n", iter, offset);

    total_nans = new_total_nans;

    for i = 1:length(arr_subsets_cols)
    
        subset_cols = arr_subsets_cols(i,:);
        subset_cols(subset_cols == "") = []; %remove posiçoes do subset_cols "vazias"
       
        dataset_cols_all = tabledf.Properties.VariableNames; %todas as colunas do dataset
        dataset_cols_missing = setdiff(subset_cols, dataset_cols_all); %verifica diferença entre conjuntos
        if ~isempty(dataset_cols_missing) %verifica se as colunas colocadas no excel estao bem inseridas e existem
            error('Erro: Colunas em falta: %s', strjoin(cols_missing, ', '));
        end
    
        target_col = subset_cols(1);
        predict_cols = subset_cols(2: end-iter); %reduz numero de variaveis para reduzir prob de nan
        
        if dic_num_nans(target_col) == 0
            fprintf('a coluna %s ja está limpa. A saltar...\n', target_col{1});
            continue;
        end
    
        %linhas com nan no target - linhas a preencher!!!
        mask_target_nan = ismissing(tabledf.(target_col{1}));
    
        % precisamos de garantir que as colunas preditoras não tem nans nas linhas que vamos usar
        mask_predict_nan = any(ismissing(tabledf{:, predict_cols}), 2);
    
        % mascara do conjunto de treino (onde nao ha nans em qualquer linha)
        training_set_mask = ~mask_target_nan & ~mask_predict_nan;
    
        % mascara de previsao onde ha nans no target mas nao ha nans nas outras
        % colunas
        predict_set_mask = mask_target_nan & ~mask_predict_nan;
    
        % 4. Extrair as matrizes de dados para o modelo
        X_t = tabledf{training_set_mask, predict_cols};
        Y_t = tabledf{training_set_mask, target_col};
        
    
        % temos de acrescentar os 1's como no CBR para ter o b do y=mx+b
        X_t_1 = [ones(size(X_t, 1), 1), X_t];
    
        % coeficientes da reta de regressao (por via da regreçao ->  \ )
        coef = X_t_1 \ Y_t;
    
        %valores para previsao de nans no target
        X_new = tabledf{predict_set_mask, predict_cols};
    
        %adicionam-se 1's tb
        X_new_1 = [ones(size(X_new, 1), 1), X_new];
    
        % valores calculados para os nan
        Y_new = X_new_1 * coef;
        
        % atribuir os valores calculados aos nans
        tabledf.(target_col{1})(predict_set_mask) = Y_new;
        
        
    end
    
    new_total_nans = sum(sum(ismissing(tabledf)));
end


dic_num_nans = dictionary(col_name, sum(ismissing(tabledf)));

clc;
fprintf("\n\n***** NUMERO DE NaN POR COLUNA  *****\n\n")
disp(dic_num_nans);

writetable(tabledf, 'dataset_TP_num_preenchido.xlsx');