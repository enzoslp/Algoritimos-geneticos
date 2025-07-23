function individuo_mutado = mutacao(individuo, taxa_mutacao, limites_max)
    % individuo_mutado = individuo;
    % for i = 1:length(individuo)
    %     if rand < taxa_mutacao
    %         individuo_mutado(i) = randi([0, limites_max(i)]);
    %     end
    % end
    %mutacao_incremental Aplica uma mutação que faz pequenas alterações.
%   Em vez de sortear um novo valor do zero, esta função adiciona ou
%   subtrai 1 do valor atual do gene, respeitando os limites.

    individuo_mutado = individuo;
    for i = 1:length(individuo)
        % O gatilho de probabilidade continua o mesmo
        if rand < taxa_mutacao

            valor_atual = individuo(i);

            % Sorteia a direção da mutação: aumentar ou diminuir
            if rand < 0.5
                % Tenta AUMENTAR o valor do gene
                novo_valor = valor_atual + 1;
            else
                % Tenta DIMINUIR o valor do gene
                novo_valor = valor_atual - 1;
            end

            % --- Verificação de Limites ---
            % Garante que o novo valor não ultrapasse os limites válidos
            if novo_valor > limites_max(i)
                novo_valor = 0; % Limita ao teto
            elseif novo_valor < 0
                novo_valor = limites_max(i); % Limita ao piso
            end

            individuo_mutado(i) = novo_valor;
        end
    end
end