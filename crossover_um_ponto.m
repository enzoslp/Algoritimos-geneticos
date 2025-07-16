function [filho1, filho2] = crossover_um_ponto(pai1, pai2, num_genes)
    % Realiza o crossover de um ponto.
    
    % --- CORREÇÃO DEFINITIVA ---
    % Se há menos de 2 genes, o crossover é impossível.
    if num_genes < 2
        filho1 = pai1;
        filho2 = pai2;
        return; % Retorna os pais como filhos para evitar o erro.
    end
    % --- FIM DA CORREÇÃO ---
    
    ponto_corte = randi(num_genes - 1);
    filho1 = [pai1(1:ponto_corte), pai2(ponto_corte+1:end)];
    filho2 = [pai2(1:ponto_corte), pai1(ponto_corte+1:end)];
end