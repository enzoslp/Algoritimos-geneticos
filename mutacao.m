function individuo_mutado = mutacao(individuo, taxa_mutacao, limites_max)
    individuo_mutado = individuo;
    for i = 1:length(individuo)
        if rand < taxa_mutacao
            individuo_mutado(i) = randi([0, limites_max(i)]);
        end
    end
end