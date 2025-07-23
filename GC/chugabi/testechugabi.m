% =========================================================================
% ALGORITMO GENÉTICO DE CHU-BEASLEY - VERSÃO FINAL OTIMIZADA E MODULAR
%
% Descrição: Versão refatorada que mantém a estrutura do usuário, mas
% modulariza os operadores genéticos e corrige a lógica de mutação e
% inicialização para melhor desempenho.
% =========================================================================

%% 0. INICIALIZAÇÃO E CONFIGURAÇÃO
clc;
clear;
close all;

%% 1. PARÂMETROS DO ALGORITMO
fprintf('Configurando os parâmetros do Algoritmo Genético...\n');
tam_pop           = 50;
num_iteracoes     = 100;
taxa_cross        = 0.8;
taxa_mut          = 0.05;
tam_torneio       = 3;
S_base            = 100;
penal_corte       = 10e3;

%% 2. CARREGAMENTO DOS DADOS DO SISTEMA
fprintf('Carregando dados do sistema...\n');
% Os dados são mantidos diretamente no script, como solicitado.
% DADOS DAS BARRAS
% DADOS DAS BARRAS

% Sistema_006_110
% Sistema_006_200
% Sistema_024
% Sistema_046
 Sistema_Colombiano_Estatico

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

%% 3. GERAÇÃO E AVALIAÇÃO DA POPULAÇÃO INICIAL
fprintf('Gerando e avaliando a população inicial...\n');
pop = zeros(tam_pop, n_ram);
custo_pop = zeros(tam_pop, 1);
anfitness_pop = zeros(tam_pop, 1);

% --- ALTERAÇÃO: Inicialização aleatória reativada ---
% Começar com uma população de zeros limita severamente a exploração.
% A geração aleatória é crucial para a diversidade inicial.
for j = 1:n_ram
    pop(:, j) = randi([0, n_max_add(j)], tam_pop, 1);
end

parfor i = 1:tam_pop
    [custo_total, corte_pu] = funcao_fitness_DC(pop(i, :), barras, ramos, S_base, penal_corte);
    custo_pop(i) = custo_total - (corte_pu * penal_corte); % Custo de investimento
    anfitness_pop(i) = corte_pu; % Inviabilidade (corte de carga)
end

%% 4. LOOP EVOLUTIVO PRINCIPAL
fprintf('Iniciando o processo evolutivo...\n');
[melhor_custo_global, idx_melhor] = min(custo_pop + anfitness_pop * penal_corte);
melhor_solucao_global = pop(idx_melhor, :);
historico_custo = zeros(num_iteracoes, 1);

for iteracao = 1:num_iteracoes
    fprintf('Iteração %d de %d...\n', iteracao, num_iteracoes);
    
    % --- 4.1 SELEÇÃO, CROSSOVER, MUTAÇÃO E PODA ---
    % Seleção por Torneio
    idx_pai1 = selecao_torneio(custo_pop, anfitness_pop, tam_torneio);
    idx_pai2 = selecao_torneio(custo_pop, anfitness_pop, tam_torneio);
    pai1 = pop(idx_pai1, :);
    pai2 = pop(idx_pai2, :);
    
    % Crossover e seleção do melhor filho
    [filho1, filho2] = crossover_um_ponto(pai1, pai2, n_ram);
    [custo1, ~] = funcao_fitness_DC(filho1, barras, ramos, S_base, penal_corte);
    [custo2, ~] = funcao_fitness_DC(filho2, barras, ramos, S_base, penal_corte);
    if custo1 <= custo2, descendente = filho1; else, descendente = filho2; end
    
    % Mutação (com lógica corrigida)
    descendente = mutacao(descendente, taxa_mut, n_max_add);
    
    % Melhoramento Local (Poda)
    descendente = funcao_poda(descendente, barras, ramos, S_base, penal_corte);
    
    % --- 4.2 AVALIAÇÃO E CRITÉRIO DE ACEITAÇÃO ---
    [custo_desc, anfitness_desc] = funcao_fitness_DC(descendente, barras, ramos, S_base, penal_corte);
    fitness_desc = custo_desc - (anfitness_desc * penal_corte);
    
    % Encontra o pior indivíduo para possível substituição
    [pior_anfitness, idx_pior_anfitness] = max(anfitness_pop);
    
    aceito = false;
    if anfitness_desc < pior_anfitness
        pop(idx_pior_anfitness, :) = descendente;
        custo_pop(idx_pior_anfitness) = fitness_desc;
        anfitness_pop(idx_pior_anfitness) = anfitness_desc;
        aceito = true;
    elseif abs(anfitness_desc - pior_anfitness) < 1e-6
        idx_viaveis = find(anfitness_pop < 1e-6);
        if isempty(idx_viaveis) && anfitness_desc < 1e-6
             pop(idx_pior_anfitness, :) = descendente;
             custo_pop(idx_pior_anfitness) = fitness_desc;
             anfitness_pop(idx_pior_anfitness) = anfitness_desc;
             aceito = true;
        elseif ~isempty(idx_viaveis)
            [pior_fitness_viavel, idx_local] = max(custo_pop(idx_viaveis));
            idx_pior_viavel = idx_viaveis(idx_local);
            if fitness_desc < pior_fitness_viavel
                pop(idx_pior_viavel, :) = descendente;
                custo_pop(idx_pior_viavel) = fitness_desc;
                anfitness_pop(idx_pior_viavel) = anfitness_desc;
                aceito = true;
            end
        end
    end

    % --- 4.3 ATUALIZAÇÃO DO MELHOR GLOBAL (INCUMBENTE) ---
    if aceito && anfitness_desc < 1e-6 && fitness_desc < melhor_custo_global
        melhor_custo_global = fitness_desc;
        melhor_solucao_global = descendente;
        fprintf('  -> Novo melhor custo global encontrado: %.2f\n', melhor_custo_global);
    end
    
    historico_custo(iteracao) = melhor_custo_global;
end

%% 5. RESULTADOS FINAIS
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



function idx_selecionado = selecao_torneio(custo_pop, anfitness_pop, tam_torneio)
    % Seleciona o melhor de um grupo aleatório (torneio).
    % O critério é a menor inviabilidade (anfitness), com o menor custo como desempate.
    idx_competidores = randi(length(custo_pop), tam_torneio, 1);
    
    custos_competidores = custo_pop(idx_competidores);
    anfitness_competidores = anfitness_pop(idx_competidores);
    
    % Combina anfitness e custo para encontrar o melhor
    score_competidores = anfitness_competidores + custos_competidores / 1e7; % Desempate pelo custo
    [~, idx_vencedor_local] = min(score_competidores);
    
    idx_selecionado = idx_competidores(idx_vencedor_local);
end

function [filho1, filho2] = crossover_um_ponto(pai1, pai2, n_ram)
    % Realiza o crossover de um ponto de forma robusta.
    if n_ram < 2
        filho1 = pai1;
        filho2 = pai2;
        return;
    end
    ponto_corte = randi(n_ram - 1);
    filho1 = [pai1(1:ponto_corte), pai2(ponto_corte+1:end)];
    filho2 = [pai2(1:ponto_corte), pai1(ponto_corte+1:end)];
end

function individuo_mutado = mutacao(individuo, taxa_mutacao, n_max_add)
    % Aplica mutação com a taxa correta, gene a gene.
    individuo_mutado = individuo;
    for j = 1:length(individuo)
        if rand() < taxa_mutacao
            individuo_mutado(j) = randi([0, n_max_add(j)]);
        end
    end
end