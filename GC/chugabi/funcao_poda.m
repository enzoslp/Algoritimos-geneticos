function plano_otimizado = funcao_poda(plano_bruto, barras, ramos_base, S_base, penal_corte)
% Esta função recebe um plano de expansão "bruto" e o otimiza.
% VERSÃO DEFINITIVA: Implementa a poda sequencial agressiva, focando em
% remover o máximo de circuitos de cada ramo candidato, um por vez,
% começando pelos mais caros.

    % --- Inicialização ---
    plano_otimizado = plano_bruto; % Começa com a solução encontrada pelo AG.
    if isrow(plano_otimizado)
        plano_otimizado = plano_otimizado'; % Garante que seja um vetor coluna.
    end

    % Calcula o custo inicial do plano, que será nossa referência para melhorias.
    custo_atual = funcao_fitness_DC(plano_otimizado, barras, ramos_base, S_base, penal_corte);
    
    fprintf('Iniciando procedimento de poda. Custo inicial para refinar: %.2f\n', custo_atual);
    
    % --- ETAPA 1: Criar a lista de candidatos à poda ---
    % Identifica os ramos onde circuitos foram adicionados.
    idx_candidatos = find(plano_otimizado > 0);
    
    if isempty(idx_candidatos)
        fprintf('Poda não aplicável. Nenhum circuito foi adicionado na solução bruta.\n');
        return; % Retorna o plano original se não houver o que podar.
    end
    
    % Ordena os candidatos pelo seu CUSTO, do mais caro para o mais barato.
    custos_circuitos = ramos_base(idx_candidatos, 7);
    [~, ordem_poda] = sort(custos_circuitos, 'descend');
    idx_candidatos_ordenados = idx_candidatos(ordem_poda);
    
    fprintf('Iniciando teste de remoção para %d caminhos...\n', length(idx_candidatos_ordenados));

    % --- ETAPA 2: Laço de Remoção Sequencial ---
    % Itera sobre os candidatos, do mais caro para o mais barato.
    for i = 1:length(idx_candidatos_ordenados)
        k = idx_candidatos_ordenados(i); % Pega o índice do ramo atual.
        
        % Tenta remover circuitos DESTE MESMO RAMO 'k' repetidamente.
        while plano_otimizado(k) > 0
            
            % Cria uma configuração de teste com um circuito a menos.
            plano_teste = plano_otimizado;
            plano_teste(k) = plano_teste(k) - 1;
            
            % Avalia o custo da configuração de teste.
            custo_teste = funcao_fitness_DC(plano_teste, barras, ramos_base, S_base, penal_corte);
            
            % CRITÉRIO DE ACEITAÇÃO: A remoção é aceita se o custo não piorar.
            if custo_teste <= custo_atual
                % Sucesso! Atualiza o plano e o custo de referência.
                plano_otimizado = plano_teste;
                custo_atual = custo_teste;
                fprintf('   -> Sucesso! Removido 1 circuito do ramo %d. Novo custo: %.2f\n', k, custo_atual);
            else
                % Falha. A remoção piorou o custo.
                fprintf('   -> Rejeitado. Remover circuito do ramo %d piora o custo.\n', k);
                % Se remover um circuito já piora, não adianta tentar remover mais deste mesmo ramo.
                break; % Interrompe o 'while' e passa para o PRÓXIMO RAMO no loop 'for'.
            end
        end
    end
    
    fprintf('Poda concluída.\n');
end