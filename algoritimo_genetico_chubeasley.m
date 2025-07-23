clc; 
clear all; 
close all;

%% PARÂMETROS DO ALGORITMO
fprintf('Configurando os parâmetros do Algoritmo Genético...\n');
tam_populacao     = 500;  % Tamanho da população 
num_iteracoes     = 2500; % Critério de parada: número de indivíduos a serem criados 
taxa_crossover    = 1;
taxa_mutacao      = 0.09;
tam_torneio       = 6;    % Parâmetro para a seleção por torneio
Sb = 100;
alpha = 10e3;

%% DADOS DO SISTEMA ELÉTRICO
% Sistema_006_110
% Sistema_006_200
% Sistema_024
% Sistema_046
 Sistema_Colombiano_Estatico

num_variaveis = size(dados_ramos, 1);
limites_max   = dados_ramos(:, 8).';

%% GERAÇÃO E AVALIAÇÃO DA POPULAÇÃO INICIAL
fprintf('Criando e avaliando a população inicial\n');
populacao = zeros(tam_populacao, num_variaveis);
custo_invest_pop = zeros(tam_populacao, 1);
custo_corte_pop  = zeros(tam_populacao, 1);
fitness_total_pop = zeros(tam_populacao, 1);

% Geração aleatória da população inicial
for i = 1:tam_populacao
    individuo_temp = zeros(1, num_variaveis);
    for j = 1:num_variaveis
        individuo_temp(j) = randi([0, limites_max(j)]);
    end
    populacao(i, :) = individuo_temp;
    
    % Avaliação da população inicial 
    [fo, ci, cc,~, ~] = funcao_fitness_DC(populacao(i,:), dados_barras, dados_ramos, Sb, alpha); %calcula o custo do investimento e custo por corte de carga
    
    % Atribuição aos vetores de slicing
    fitness_total_pop(i) = fo;
    custo_invest_pop(i) = ci;
    custo_corte_pop(i) = cc;
end

%% LOOP EVOLUTIVO PRINCIPAL (Modelo Chu-Beasley)
[melhor_custo_global, idx_melhor_inicial] = min(fitness_total_pop);
melhor_solucao_global = populacao(idx_melhor_inicial, :); % O melhor indivíduo é o incumbente
historico_custo = zeros(num_iteracoes, 1);

for iter = 1:num_iteracoes
fprintf('Analisando Iteração %d de %d...\n', iter, num_iteracoes);
    % Criação de um novo Descendente 
    
    % Seleção por Torneio entre individuos para encontrar dois melhores pais (menor custo) 
    idx_pai1 = selecao_torneio(fitness_total_pop, tam_torneio); 
    idx_pai2 = selecao_torneio(fitness_total_pop, tam_torneio);
    pai1 = populacao(idx_pai1, :);
    pai2 = populacao(idx_pai2, :);
    
    % Crossover para gerar dois filhos 
    [filho1, filho2] = crossover_um_ponto(pai1, pai2, num_variaveis);
    
    % Avalia os dois filhos e seleciona o melhor para ser o "Descendente" 
    [fo1, ~, ~] = funcao_fitness_DC(filho1, dados_barras, dados_ramos, Sb, alpha);
    [fo2, ~, ~] = funcao_fitness_DC(filho2, dados_barras, dados_ramos, Sb, alpha);
    
    if fo1 < fo2
        descendente = filho1;
    else
        descendente = filho2;
    end
    
    % Aplica mutação no descendente selecionado 
    descendente = mutacao(descendente, taxa_mutacao, limites_max);


    %%Rodar o DC aqui para ver se tem corte de carga, se tiver, elimina o
    %%corte de carga
    [~, ~, cc_novo, ~, ~] = funcao_fitness_DC(descendente, dados_barras, dados_ramos, Sb, alpha);
    
    if cc_novo>1e-2
        fprintf('  Corte de carga detectado (%.4f), iniciando algoritimo MCC\n', cc_novo);
        [descendente, cc_reparado] = funcao_reparo_inviabilidade(descendente, dados_barras, dados_ramos, Sb, alpha, limites_max, cc_novo);
    end
   
    % Melhoramento Local (Refinamento / Poda)
    % Conforme o modelo, o novo indivíduo passa por uma etapa de melhoramento 
    descendente = funcao_poda(descendente, dados_barras, dados_ramos, Sb, alpha);
    
    %Avalia o indivíduo final após todas as etapas
    [fo_novo, ci_novo, cc_novo] = funcao_fitness_DC(descendente, dados_barras, dados_ramos, Sb, alpha);
    
    %Critério de Aceitação de Chu-Beasley
    % O novo indivíduo deve ser diferente de todos na população atual, se
    % for igual é descartado e a iteraçao é perdida
    if ismember(descendente, populacao, 'rows')%Função retorna true se o descendente for um duplicado e false caso contrário. 
        
        %trata cada linha da matriz populacao como um único elemento e verificar se o vetor descendente é idêntico a alguma dessas linhas.
        continue; %interrompe imediatamente a iteração atual e salta para o início da próxima iteração 
         
        %Se o descendente gerado for duplicado, todo o resto dentro do laço (a parte que encontra o pior indivíduo e faz a substituição) é ignorado para esta iteração. 
        % O algoritmo "joga fora" o indivíduo repetido e começa um novo ciclo para gerar um novo descendente.

    end
    %populacao: matriz onde cada linha é um indivíduo da população atual.
    %descendente: indivíduo que queremos verificar 

    % Encontra o Pior Indivíduo na população atual   
    [~, idx_pior] = max(custo_corte_pop + custo_invest_pop / (alpha*100)); % Desempate pelo custo
    
    %Se for único, ele é comparado com o pior indivíduo da população atual
    % Aplica as regras de substituição 
    if (cc_novo < custo_corte_pop(idx_pior)) || ...
       (abs(cc_novo - custo_corte_pop(idx_pior)) < 1e-3 && fo_novo < fitness_total_pop(idx_pior)) 
        %%A sua "unfitness" (cc_novo) for menor que a do pior indivíduo, 
        % OU A "unfitness" for a mesma (idealmente, ambas zero) e o seu "fitness" (fo_novo) for melhor que o do pior indivíduo

        populacao(idx_pior, :) = descendente;
        custo_invest_pop(idx_pior) = ci_novo;
        custo_corte_pop(idx_pior) = cc_novo;
        fitness_total_pop(idx_pior) = fo_novo;
    end
    
    %Atualiza a melhor solução global encontrada 
    [melhor_custo_iter, idx_melhor_iter] = min(fitness_total_pop); % Após cada possível modificação na população, o código verifica qual é o melhor indivíduo atual.
    historico_custo(iter) = melhor_custo_iter;
    if melhor_custo_iter < melhor_custo_global
        melhor_custo_global = melhor_custo_iter;
        melhor_solucao_global = populacao(idx_melhor_iter, :);
        fprintf('  -> Novo melhor custo global encontrado: %.2f\n', melhor_custo_global);
    end
end

%% 5. RESULTADOS FINAIS
fprintf('\n=============== OTIMIZAÇÃO CONCLUÍDA ===============\n');
fprintf('\nMelhor Solução Final Encontrada (Incumbente):\n');
fprintf('  > Custo Total (FO): %.4f\n', melhor_custo_global);
fprintf('  > Plano de Expansão (Nij):\n');
sol_final= find(melhor_solucao_global > 0);
tabela_final = table(dados_ramos(sol_final,1), dados_ramos(sol_final,2), melhor_solucao_global(sol_final)', 'VariableNames', {'De', 'Para', 'Circuitos_Adicionados'});
disp(tabela_final); 