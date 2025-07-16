function pool_de_pais = selecao_roleta(populacao, custo_pop)
    % Implementa a seleção proporcional ao fitness pelo método da roleta.
    tam_pop = size(populacao, 1);

    % Converte custo (menor=melhor) em fitness (maior=melhor)
    fitness_para_roleta = 1 ./ (1 + custo_pop);
    
    soma_total_fitness = sum(fitness_para_roleta);
    if soma_total_fitness == 0
        prob_selecao = ones(tam_pop, 1) / tam_pop;
    else
        prob_selecao = fitness_para_roleta / soma_total_fitness; % Calcula o "tamanho da fatia" de cada indivíduo na roleta. A soma de todos os elementos deste vetor será 1.
    end
    
    prob_acumulada = cumsum(prob_selecao);% Se prob_selecao for [0.1, 0.5, 0.4], prob_acumulada será [0.1, 0.6, 1.0]. Isso significa que o primeiro indivíduo ocupa o intervalo [0, 0.1], o segundo ocupa (0.1, 0.6], e o terceiro ocupa (0.6, 1.0].
    
    pool_de_pais = zeros(size(populacao));
    for i = 1:tam_pop
        ponto_sorteado = rand();
        idx_selecionado = find(ponto_sorteado <= prob_acumulada, 1, 'first');% encontra o primeiro índice no vetor prob_acumulada cujo valor é maior ou igual ao ponto_sorteado. Isso identifica eficientemente em qual "fatia" o ponto sorteado caiu, selecionando o indivíduo correspondente.
        if isempty(idx_selecionado)
            idx_selecionado = tam_pop;
        end
        pool_de_pais(i, :) = populacao(idx_selecionado, :); %indivíduo vencedor do sorteio é copiado 
    end
end