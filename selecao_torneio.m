function idx_selecionado = selecao_torneio(fitness_total, tam_torneio)
    % Seleciona 'tam_torneio' indivíduos aleatoriamente da população
    indices_populacao = 1:length(fitness_total);
    indices_torneio = randsample(indices_populacao, tam_torneio);
    
    % Encontra o melhor (menor fitness/custo) entre os selecionados
    fitness_torneio = fitness_total(indices_torneio);
    [~, idx_vencedor_local] = min(fitness_torneio);
    
    % Retorna o índice do vencedor na população original
    idx_selecionado = indices_torneio(idx_vencedor_local);
end