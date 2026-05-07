function show_missing_summary(T, numericVars, categoricalVars, targetVar)

    disp("Missing nos inputs:");
    disp(sum(ismissing(T(:, [numericVars categoricalVars]))));

    disp("Missing no target:");
    disp(sum(ismissing(T(:, {targetVar}))));
end




% disp(predictedClasses(1:10))
% disp(bestSimilarities(1:10))
% disp(sum(ismissing(engineData.class_cat)))
