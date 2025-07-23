function [plano_reparado, cc_reparado] = funcao_reparo_inviabilidade(plano_bruto, dados_barras, dados_ramos, Sb, alpha, limites_max, cc_novo)
%funcao_reparo_inviabilidade Tenta tornar um plano factível (sem corte de carga).
%   Utiliza a lógica do indicador de sensibilidade do Mínimo Corte de Carga
%   para adicionar iterativamente os circuitos mais eficazes.
    
    plano_reparado = plano_bruto;
    max_tentativas_reparo = 20; % Limite de segurança para evitar laços infinitos
    tentativa = 1;
    circuitos_adicionados = []; % Armazena o índice dos circuitos adicionados
    custo_total = 0;

    % fprintf('  Verificando viabilidade do descendente...');

    while tentativa <= max_tentativas_reparo
        % fprintf('Corte de carga atual: %.4f \n', custo_corte);
        % fprintf('\nIteração %d:\n', tentativa);

    % Exibe a configuração atual do sistema 
    % fprintf('Configuração atual do sistema (nº de circuitos):\n');
    % tabela_config = table( ...
    %     compose('%d-%d', dados_ramos(:, 1), dados_ramos(:, 2)),plano_reparado', ...
    %     'VariableNames', {'Caminho', 'N_Circuitos'});
    % disp(tabela_config);

        % Avalia o plano atual para verificar se há corte de carga
        [~, ~, custo_corte, thetas, pi_vals] = funcao_fitness_DC(plano_reparado, dados_barras, dados_ramos, Sb, alpha);

        % Se não há corte de carga, o reparo está completo e a função termina.
        if custo_corte < 1e-2
            if tentativa > 1

                cc_reparado=custo_corte; 
                fprintf(' -> Plano reparado com sucesso após %d adições.\n', tentativa-1);
                % add_plano_reparado= find(plano_reparado > 0);
                % fprintf('Configuração atual do sistema (nº de circuitos):\n');
                % tabela_config = table( ...
                %     compose('%d-%d', dados_ramos(add_plano_reparado, 1), dados_ramos(add_plano_reparado, 2)),plano_reparado(add_plano_reparado)', ...
                %     'VariableNames', {'Caminho', 'N_Circuitos'});
                % disp(tabela_config);
            else
                fprintf(' Plano já é factível.\n');
            end
            return; 
        end

        fprintf('->Iteração %d:\n', tentativa)
        % Se chegou aqui, há corte de carga e o reparo continua.
        % if tentativa == 1
             fprintf('     -> Corte de carga detectado (%.4f). \n', custo_corte);
        % end

        % ETAPA 2: Calcula os indicadores de sensibilidade (lógica do Mínimo Corte de Carga)
        num_variaveis = size(dados_ramos, 1);
        indicadores = zeros(num_variaveis, 1);
        de = dados_ramos(:, 1);
        para = dados_ramos(:, 2);
        custo = dados_ramos(:, 7);

        for i = 1:num_variaveis
            delta_theta = thetas(de(i)) - thetas(para(i));
            delta_pi = pi_vals(de(i)) - pi_vals(para(i));
            % SI = -(d_theta * d_pi). Um valor positivo alto indica um bom candidato.

            if custo > 0
                indicadores(i) = -delta_theta * delta_pi / custo(i);
            else
                indicadores(i) = -inf; % Evitar divisão por zero
            end

            
        end
        % fprintf('Indicadores de Sensibilidade (SI_mcc) calculados:\n');
        %     tabela_si = table( ...
        %         compose('%d-%d', dados_ramos(:, 1), dados_ramos(:, 2)), indicadores, 'VariableNames', {'Caminho', 'SI_mcc'});
        %        disp(tabela_si);
        % ETAPA 3: Adiciona o circuito mais promissor
        % Ignora caminhos que já atingiram o limite máximo de circuitos
        indicadores(plano_reparado >= limites_max) = -Inf; % Usa transposto para consistência
        
        [valor_max_si, idx_melhor_circuito] = max(indicadores);

        
        if isinf(valor_max_si)
             fprintf('          Reparo falhou: não há mais circuitos válidos para adicionar.\n');
             cc_reparado = 0;
             return;
        end

        % Adiciona o circuito mais promissor ao plano
        plano_reparado(idx_melhor_circuito) = plano_reparado(idx_melhor_circuito) + 1;
        circuitos_adicionados = [circuitos_adicionados; idx_melhor_circuito]; % Registra a adição

        custo_adicao = dados_ramos(idx_melhor_circuito, 7);
        custo_total = custo_total + custo_adicao;

        fprintf('          Adicionando 1 circuito ao ramo %d-%d para reduzir o corte de carga (Custo: %.2f). Custo total: %.2f.\n', ...
            de(idx_melhor_circuito), para(idx_melhor_circuito), custo_adicao, custo_total);
        
        tentativa = tentativa + 1;
        % [~, ~, custo_corte, thetas, pi_vals] = funcao_fitness_DC(plano_reparado, dados_barras, dados_ramos, Sb, alpha);
    end
    
    if tentativa > max_tentativas_reparo
        fprintf('          Reparo interrompido: limite de tentativas atingido.\n');
        cc_reparado=0;
    end
    
end