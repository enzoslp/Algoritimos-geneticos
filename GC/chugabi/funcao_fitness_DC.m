function [custo_total, corte_pu, fluxos_pu] = funcao_fitness_DC(plano_expansao, barras, ramos_base, S_base, penal_corte)
% Esta função é o "Calculador Universal" do Fluxo de Potência DC.
% VERSÃO FINAL: A montagem das matrizes foi reestruturada para espelhar
% implementações clássicas e garantir máxima estabilidade numérica no solver.

    % --- Extração de Dados e Validação ---
    n_bar = size(barras, 1);
    g_max = barras(:, 3);
    d_mw = barras(:, 4);
    idx_slack = find(barras(:, 2) == 3);
    
    n_ram = size(ramos_base, 1);
    de = ramos_base(:, 1);
    para = ramos_base(:, 2);
    n_ini = ramos_base(:, 3);
    f_max_circ = ramos_base(:, 6);
    c_circ = ramos_base(:, 7);
    x = ramos_base(:, 5);
    
    if isrow(plano_expansao)
        plano_expansao = plano_expansao';
    end

    % --- Conversão para p.u. ---
    g_max_pu = g_max / S_base;
    d_pu = d_mw / S_base;
    f_max_c_pu = f_max_circ / S_base;
    y_pu = 1 ./ x;
    
    % --- Montagem do Problema de Otimização (Estilo Clássico) ---
    n_vars = n_ram + (3*n_bar);
    f_obj = [zeros(1, n_ram + 2*n_bar), ones(1, n_bar) * penal_corte];
    
    % --- Restrições de Igualdade (Aeq*x = beq) ---
    
    % Bloco 1: 1ª Lei de Kirchhoff (Balanço Nodal)
    S = zeros(n_bar, n_ram);
    for k = 1:n_ram
        S(de(k), k) = -1; 
        S(para(k), k) = 1;
    end
    Aeq1 = [S, eye(n_bar), zeros(n_bar, n_bar), eye(n_bar)];
    beq1 = d_pu;
    
    % Bloco 2: 2ª Lei de Kirchhoff (Equação do Fluxo DC)
    Aeq2 = zeros(n_ram, n_vars);
    for k = 1:n_ram
        y_tot = y_pu(k) * (n_ini(k) + plano_expansao(k));
        Aeq2(k, k) = 1; % Coeficiente para f_k
        Aeq2(k, n_ram + n_bar + de(k)) = -y_tot; % Coeficiente para theta_de
        Aeq2(k, n_ram + n_bar + para(k)) = y_tot; % Coeficiente para theta_para
    end
    beq2 = zeros(n_ram, 1);
    
    % Junta os dois blocos de equações de igualdade
    A_eq = [Aeq1; Aeq2];
    b_eq = [beq1; beq2];

    % --- Restrições de Desigualdade (A*x <= b) ---
    A_ineq = [eye(n_ram), zeros(n_ram, 3*n_bar); -eye(n_ram), zeros(n_ram, 3*n_bar)];
    f_max_pu = (n_ini + plano_expansao) .* f_max_c_pu;
    b_ineq = [f_max_pu; f_max_pu];
    
    % --- Limites das Variáveis (lb <= x <= ub) ---
    lb = [-inf(n_ram, 1); zeros(n_bar, 1); -inf(n_bar, 1); zeros(n_bar, 1)];
    ub = [inf(n_ram, 1); g_max_pu; inf(n_bar, 1); d_pu];
    idx_th_slack = n_ram + n_bar + idx_slack;
    lb(idx_th_slack) = 0;
    ub(idx_th_slack) = 0;
    
    % --- Execução do Solver ---
    opcoes = optimoptions('linprog', 'Display', 'off');
    [sol, ~, exitflag] = linprog(f_obj, A_ineq, b_ineq, A_eq, b_eq, lb, ub, opcoes);
    
    % --- Cálculo dos Resultados de Saída ---
    if exitflag == 1
        r_pu = sol(n_ram+2*n_bar+1 : end);
        c_inv = sum(c_circ .* plano_expansao); 
        c_op = sum(r_pu * penal_corte);
        
        custo_total = c_inv + c_op;
        corte_pu = sum(r_pu);
        fluxos_pu = sol(1:n_ram);
    else
        custo_total = inf;
        corte_pu = inf;
        fluxos_pu = [];
    end
end