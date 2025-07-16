clc; 
clear all; 
close all;

%% 1. PARÂMETROS DO ALGORITMO
tam_populacao     = 100;  % Tamanho da população
num_geracoes      = 200;  % Número de gerações
taxa_crossover    = 0.8;  % Probabilidade de crossover 
taxa_mutacao      = 0.05; % Probabilidade de mutação
elitismo          = true; % Preserva o melhor indivíduo da geração anterior

%% 2. DADOS DO SISTEMA ELÉTRICO
% Sistema_006_110
% Sistema_006_200
% Sistema_024
% Sistema_046
 Sistema_Colombiano_Estatico

num_variaveis = size(dados_ramos, 1);
limites_max   = dados_ramos(:, 8).';
Sb = 100;
alpha = 10e3;

%% 3. GERAÇÃO DA POPULAÇÃO INICIAL
populacao = zeros(tam_populacao, num_variaveis);
for i = 1:tam_populacao
    for j = 1:num_variaveis
        populacao(i, j) = randi([0, limites_max(j)]);
    end
end
                       
%% 4. LOOP EVOLUTIVO PRINCIPAL
fprintf('Iniciando o processo evolutivo\n');
melhor_custo_global = inf;
melhor_solucao_global = zeros(1, num_variaveis);
historico_custo = zeros(num_geracoes, 1);  

for g = 1:num_geracoes
    fprintf('Analisando Geração %d de %d...\n', g, num_geracoes);
    
    % --- 4.1 Avaliação da População ---
    custo_pop = zeros(tam_populacao, 1);
    parfor i = 1:tam_populacao
        % A função de fitness é a mesma para ambos os algoritmos
        [custo_pop(i), ~, ~] = funcao_fitness_DC(populacao(i, :), dados_barras, dados_ramos, Sb, alpha);
    end
    
    % --- 4.2 Rastreamento do Melhor Indivíduo ---
    [custo_min_geracao, idx_melhor] = min(custo_pop);
    if custo_min_geracao < melhor_custo_global
        melhor_custo_global = custo_min_geracao;
        melhor_solucao_global = populacao(idx_melhor, :);
        fprintf('  -> Novo melhor custo global encontrado: %.2f\n', melhor_custo_global);
    end
    historico_custo(g) = melhor_custo_global;
    
    % --- 4.3 Seleção (Roleta) ---
    % A lógica da roleta agora está encapsulada em sua própria função
    pool_de_pais = selecao_roleta(populacao, custo_pop);
    
    % --- 4.4 Recombinação (Crossover) ---
    nova_pop_filhos = zeros(size(populacao));
    for k = 1:2:tam_populacao
        idx_pai1 = randi(tam_populacao);
        idx_pai2 = randi(tam_populacao);
        pai1 = pool_de_pais(idx_pai1, :);
        pai2 = pool_de_pais(idx_pai2, :);
        
        if rand() < taxa_crossover
            [filho1, filho2] = crossover_um_ponto(pai1, pai2, num_variaveis);
        else
            filho1 = pai1;
            filho2 = pai2;
        end
        nova_pop_filhos(k, :) = filho1;
        nova_pop_filhos(k+1, :) = filho2;
    end
    
    % --- 4.5 Mutação ---
    for i = 1:tam_populacao
        nova_pop_filhos(i, :) = mutacao(nova_pop_filhos(i, :), taxa_mutacao, limites_max);
    end
    
    % --- 4.6 Elitismo ---
    if elitismo
        % Garante que o melhor indivíduo da geração anterior sobreviva,
        % substituindo um indivíduo aleatório da nova geração.
        idx_substituto = randi(tam_populacao);
        nova_pop_filhos(idx_substituto, :) = populacao(idx_melhor, :);
    end
    
    % A nova população substitui a antiga
    populacao = nova_pop_filhos;
end 

%% 5. FASE DE REFINAMENTO (PODA)
fprintf('\nOtimização Genética Concluída\n');
fprintf('Refinando a melhor solução encontrada com o procedimento de poda...\n');
plano_final_otimizado = funcao_poda(melhor_solucao_global, dados_barras, dados_ramos, Sb, alpha);
[custo_final_real, ~, ~]  = funcao_fitness_DC(plano_final_otimizado, dados_barras, dados_ramos, Sb, alpha);

%% 6. RESULTADOS FINAIS
fprintf('\n=============== RESULTADOS FINAIS ===============\n');
fprintf('\nMelhor Solução encontrada pelo AG (Antes do Refinamento):\n');
fprintf(' > Fitness (FO): %.4f\n', melhor_custo_global);
fprintf(' > Plano de Expansão (Nij):\n');

%disp(melhor_solucao_global);

tabela_final_global = table(dados_ramos(:,1), dados_ramos(:,2), melhor_solucao_global', 'VariableNames', {'De', 'Para', 'Circuitos_Adicionados'}); % Cria a tabela com a solução final.
disp(tabela_final_global); % Exibe a tabela de resultados.

fprintf('\nMelhor Solução APÓS FASE DE REFINAMENTO:\n');
fprintf(' > Fitness (FO): %.4f\n', custo_final_real);
fprintf(' > Plano de Expansão (Nij):\n');

%disp(solucao_refinada);
%tabela_final_refinada = table(dados_ramos(:,1), dados_ramos(:,2), solucao_refinada', 'VariableNames', {'De', 'Para', 'Circuitos_Adicionados'}); % Cria a tabela com a solução final.
%disp(tabela_final_refinada);
% Exibe a tabela de resultados.
sol= find(plano_final_otimizado>0);
tabela_adicionados= table(dados_ramos(sol,1), dados_ramos(sol,2), plano_final_otimizado(sol)', 'VariableNames', {'De', 'Para', 'Circuitos_Adicionados'});
disp(tabela_adicionados);