%--------------------------------------------------------------------------
% ALGORITMO GENÉTICO CHU-BEALEY (MESTRE) - VERSÃO FINAL E CORRIGIDA
%--------------------------------------------------------------------------
%% 0. INICIALIZAÇÃO E CONFIGURAÇÃO
clc;
clear;
close all;

% --- Parâmetros do Algoritmo ---
tam_pop           = 250;    % Tamanho da população
num_iteracoes     = 500;    % Critério de parada: número de indivíduos a serem criados
taxa_cross        = 0.8;    % Probabilidade de crossover (alta)
taxa_mut          = 0.05;    % Probabilidade de um descendente sofrer mutação (relativamente alta)
tam_torneio       = 3;      % Número de indivíduos na seleção por torneio
S_base            = 100;    % Potência base (MVA)
penal_corte       = 10e3;   % Penalidade por corte de carga

%% 1. CARREGAMENTO DOS DADOS DO SISTEMA
fprintf('Carregando dados do sistema...\n');
% DADOS DAS BARRAS


% Sistema_006_110
% Sistema_006_200
% Sistema_024
 Sistema_046
% Sistema_Colombiano_Estatico

barras = dados_barras;
ramos = dados_ramos;
% --- Extração de Parâmetros Iniciais ---
ni = ramos(:,1);                                                        
nj = ramos(:,2);                                                        
n_ram = size(ramos, 1);                                                 
S_base = 100;                                                           
penal_corte = 10e3;                                                     
n_total_max = ramos(:, 8); 
n_ini = ramos(:, 3); 
n_max_add = n_total_max - n_ini; 
% --- Variáveis para guardar o melhor resultado durante a evolução ---
melhor_solucao_global = zeros(n_ram, 1); 
melhor_custo_global = inf;                                              
% historico_custo = zeros(n_ger, 1);                                      

%% 1. GERAR A POPULAÇÃO INICIAL
fprintf('Gerando a população inicial...\n');                            
pop = zeros(tam_pop, n_ram); 
 for j = 1:n_ram 
     pop(:, j) = randi([0, n_max_add(j)], tam_pop, 1);
 end
% solucao_semente = cria_solucao_inicial(barras, ramos, S_base, penal_corte);
% pop(1, :) = solucao_semente;
% fprintf('Solução inteligente injetada na população inicial.\n');

%% 2. AVALIAÇÃO DA POPULAÇÃO INICIAL
fprintf('Avaliando a população inicial...\n');
custo_pop = zeros(tam_pop, 1);
anfitness_pop = zeros(tam_pop, 1);
for i = 1:tam_pop
    [custo_total, corte_pu] = funcao_fitness_DC(pop(i, :), barras, ramos, S_base, penal_corte);
    custo_pop(i) = custo_total - (corte_pu * penal_corte);
    anfitness_pop(i) = corte_pu;
end

%% INÍCIO DO LOOP DAS GERAÇÕES (ITERAÇÕES)
for iteracao = 1:num_iteracoes
    fprintf('Iteração %d de %d...\n', iteracao, num_iteracoes);
    
    %% 3. SELEÇÃO (POR TORNEIO)
    idx_competidores = randi(tam_pop, tam_torneio, 1);
    [~, idx_vencedor_local] = min(custo_pop(idx_competidores));
    idx_pai1 = idx_competidores(idx_vencedor_local);
    idx_competidores = randi(tam_pop, tam_torneio, 1);
    [~, idx_vencedor_local] = min(custo_pop(idx_competidores));
    idx_pai2 = idx_competidores(idx_vencedor_local);
    pai1 = pop(idx_pai1, :);
    pai2 = pop(idx_pai2, :);

    %% 4. RECOMBINAÇÃO (CROSSOVER)
    filho1 = pai1;
    filho2 = pai2;
    if rand() < taxa_cross
        ponto_corte = randi(n_ram - 1);
        filho1 = [pai1(1:ponto_corte), pai2(ponto_corte+1:end)];
        filho2 = [pai2(1:ponto_corte), pai1(ponto_corte+1:end)];
    end
    
    custo_filho1 = funcao_fitness_DC(filho1, barras, ramos, S_base, penal_corte);
    custo_filho2 = funcao_fitness_DC(filho2, barras, ramos, S_base, penal_corte);
    if custo_filho1 <= custo_filho2
        descendente = filho1;
    else
        descendente = filho2;
    end
    
    %% 5. MUTAÇÃO
    if rand() < taxa_mut
        for j = 1:n_ram
            if rand() < taxa_mut
                descendente(j) = randi([0, n_max_add(j)]);
            end
        end
    end
    
    %% 6. MELHORAMENTO LOCAL (PODA)
    descendente_melhorado = funcao_poda(descendente, barras, ramos, S_base, penal_corte);
    
    [custo_desc, anfitness_desc] = funcao_fitness_DC(descendente_melhorado, barras, ramos, S_base, penal_corte);
    fitness_desc = custo_desc - (anfitness_desc * penal_corte);
    
    %% 7. CRITÉRIO DE ACEITAÇÃO E ATUALIZAÇÃO DA POPULAÇÃO
    [pior_anfitness, idx_pior_anfitness] = max(anfitness_pop);
    aceito = false;
    
    if anfitness_desc > 1e-6
        if anfitness_desc < pior_anfitness
            pop(idx_pior_anfitness, :) = descendente_melhorado;
            custo_pop(idx_pior_anfitness) = fitness_desc;
            anfitness_pop(idx_pior_anfitness) = anfitness_desc;
            aceito = true;
        end
    else 
        idx_viaveis = find(anfitness_pop < 1e-6);
        if isempty(idx_viaveis)
             pop(idx_pior_anfitness, :) = descendente_melhorado;
             custo_pop(idx_pior_anfitness) = fitness_desc;
             anfitness_pop(idx_pior_anfitness) = anfitness_desc;
             aceito = true;
        else
            [pior_fitness_viavel, idx_local] = max(custo_pop(idx_viaveis));
            idx_pior_viavel = idx_viaveis(idx_local);
            
            if fitness_desc < pior_fitness_viavel
                pop(idx_pior_viavel, :) = descendente_melhorado;
                custo_pop(idx_pior_viavel) = fitness_desc;
                anfitness_pop(idx_pior_viavel) = anfitness_desc;
                aceito = true;
            end
        end
    end

    if aceito && anfitness_desc < 1e-6 && fitness_desc < melhor_custo_global
        melhor_custo_global = fitness_desc;
        melhor_solucao_global = descendente_melhorado;
        fprintf('  -> Novo melhor custo global encontrado: %.2f\n', melhor_custo_global);
    end
    
    custos_viaveis = custo_pop(anfitness_pop < 1e-6);
    if ~isempty(custos_viaveis)
        historico_custo(iteracao) = min(custos_viaveis);
    elseif melhor_custo_global ~= inf
        historico_custo(iteracao) = melhor_custo_global;
    else
        historico_custo(iteracao) = min(custo_pop);
    end
end

%% RESULTADOS FINAIS
fprintf('\n\nOtimização Genética Concluída!\n');
fprintf('====================================================\n');
fprintf('Melhor Custo Total Encontrado: %.2f\n', melhor_custo_global);
fprintf('Melhor Plano de Expansão:\n');

if isrow(melhor_solucao_global)
    melhor_solucao_global = melhor_solucao_global';
end
tabela_final = table(ni, nj, melhor_solucao_global, 'VariableNames', {'De', 'Para', 'Circuitos_Adicionados'});
disp(tabela_final);

figure('Name', 'Convergência do Algoritmo Genético');
plot(1:num_iteracoes, historico_custo, 'LineWidth', 2);
title('Evolução do Melhor Custo Viável por Geração');
xlabel('Iteração');
ylabel('Custo de Investimento');
grid on;