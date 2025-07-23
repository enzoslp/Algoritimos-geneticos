function idx_selecionado = selecao_torneio(fitness_total, tam_torneio)
    % Seleciona 'tam_torneio' indivíduos aleatoriamente da população (Um
    % número inteiro que define quantos indivíduos irão competir)
    indices_populacao = 1:length(fitness_total); % Cria um vetor com todos os índices possíveis, de 1 até o tamanho da população
    indices_torneio = randsample(indices_populacao, tam_torneio); % Seleciona os participantes do torneio
    
    % Encontra o melhor (menor fitness/custo) entre os selecionados
    fitness_torneio = fitness_total(indices_torneio);

    %A função min é aplicada ao pequeno vetor de fitness dos competidores. Como nosso fitness é um custo, o indivíduo com o menor valor é o vencedor
    [~, idx_vencedor_local] = min(fitness_torneio);% Posição local do vencedor 
    
    % O índice de um único indivíduo, o vencedor do torneio, que foi selecionado para reprodução
    idx_selecionado = indices_torneio(idx_vencedor_local);
end