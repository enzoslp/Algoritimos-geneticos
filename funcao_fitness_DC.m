function [FO, custo_invest, custo_corte, thetas, pi_vals] = funcao_fitness_DC(Nij, dados_barras, dados_ramos, Sb, alpha)

%% Versao original
 % Dados Barras
    % LenB = size(dados_barras,1); % Número de barras
    % g_max = dados_barras(:,3).'; % Capacidade máxima de geração (MW)
    % d = dados_barras(:,4).';     % Demanda (MW)
    % idx_slack = find(dados_barras(:,2) == 3); % Localiza a barra slack
    % 
    % % Dados Linhas
    % LenL = size(dados_ramos,1);   % Número de ramos (caminhos)
    % from = dados_ramos(:,1).';    % Barra "De"
    % to = dados_ramos(:,2).';      % Barra "Para"
    % N_ini = dados_ramos(:,3).';   % Número de circuitos iniciais
    % fmax = dados_ramos(:,6).';    % Limite de fluxo por circuito (MW)
    % c = dados_ramos(:,7);       % Custo por circuito
    % %N_max = dados_ramos(:,8).';   %Numero maximo de circuitos finais
    % y = 1./dados_ramos(:,5).';    % Susceptância por circuito (1/x)
    % 
    % g_max = g_max/Sb;
    % d = d/Sb;
    % fmax = fmax/Sb; 
    % 
    % % --- Função Objetivo ---
    % % min alpha*sum(ri). O custo do investimento (c'*Nij) é adicionado
    % % no final, pois Nij é um dado de entrada e não uma variável.
    % f = [zeros(1, LenL), zeros(1, LenB), zeros(1, LenB), alpha*ones(1, LenB)];
    % 
    % % --- Restrições de Igualdade (Aeq*x = beq) ---
    % % 1ª Lei de Kirchhoff: S*f + g + r = d
    % S = zeros(LenB, LenL);
    % for k = 1:LenL
    %     i = dados_ramos(k,1); % sender
    %     j = dados_ramos(k,2); % receiver
    %     S(i,k) = -1; % Fluxo saindo da barra
    %     S(j,k) = 1; % Fluxo entrando na barra
    % end
    % 
    % Aeq1 = [S, eye(LenB), zeros(LenB, LenB), eye(LenB)];
    % beq1 = d';
    % 
    % % 2ª Lei de Kirchhoff: fij - y_total * (thi - thj) = 0
    % Aeq2 = zeros(LenL, LenL + 3*LenB);
    % beq2 = zeros(LenL, 1);
    % 
    % for k = 1:LenL
    %     Aeq2(k, k) = 1; % Coeficiente para fij
    %     % Coeficientes para os ângulos θi e θj
    %     y_total = y(k) * (N_ini(k) + Nij(k));
    %     Aeq2(k, LenL+LenB+from(k)) = -y_total;
    %     Aeq2(k, LenL+LenB+to(k))   =  y_total;
    % end
    % 
    % Aeq = [Aeq1; Aeq2];
    % beq = [beq1; beq2];
    % 
    % % --- Restrições de Desigualdade (A*x <= b) ---
    % % Limites de fluxo: |fij| <= fmax_total
    % 
    % % fij <= (N_ini + Nij)*fmax
    % A1 = [eye(LenL), zeros(LenL, LenB), zeros(LenL, LenB), zeros(LenL, LenB)];
    % 
    % % -fij <= (N_ini + Nij)*fmax
    % A2 = [-eye(LenL), zeros(LenL, LenB), zeros(LenL, LenB), zeros(LenL, LenB)];
    % 
    % A = [A1; A2];
    % 
    % fmax_total = (N_ini' + Nij').*fmax';
    % b = [fmax_total; fmax_total];
    % 
    % % --- Limites das Variáveis (lb <= x <= ub) ---
    % % g >=0 e r >= 0
    % lb = [-Inf*ones(1, LenL), zeros(1, LenB), -Inf*ones(1, LenB), zeros(1, LenB)];
    % % g <= g_max e r <= d
    % ub = [Inf*ones(1, LenL), g_max, Inf*ones(1, LenB), d];
    % 
    % % --- Implementação da Barra de Referência (Slack) ---
    % % Localiza a posição da variável theta_slack no vetor 'x'
    % idx_theta_slack = LenL + LenB + idx_slack;
    % % Força o ângulo a ser zero, definindo seus limites inferior e superior como 0
    % lb(idx_theta_slack) = 0;
    % ub(idx_theta_slack) = 0;
    % 
    % %% linprog
    % options = optimoptions('linprog', 'Display', 'off', 'Algorithm', 'dual-simplex');
    % [x, ~, exitflag, ~, lambda] = linprog(f, A, b, Aeq, beq, lb, ub, options); % Captura o 'lambda'
    % 
    % % --- Cálculo e atribuição das 5 saídas ---
    % if exitflag == 1
    %     ri = x(LenL+2*LenB+1 : end);
    %     custo_invest = sum(c' .* Nij);
    %     custo_corte = alpha * sum(ri);
    %     FO = custo_invest + custo_corte;
    % 
    %     % Saídas adicionais
    %     thetas = x(LenL+LenB+1 : LenL+2*LenB);
    %     pi_vals = lambda.eqlin;
    % else
    %     % Retorna valores de falha para todas as saídas
    %     custo_invest = Inf; custo_corte = Inf; FO = Inf;
    %     thetas = zeros(LenB,1); pi_vals = zeros(LenB,1);
    % end

 %% Versao MCC
 %FUNCAO_FITNESS_DC Avalia um plano de expansão (Nij) e retorna os custos.
%   VERSÃO REATORADA: Segue a filosofia do modelo agregado (compacto),
%   similar à função 'resolverPLCorteCarga', para maior eficiência e
%   padronização do código.

    % %% 1. Extração de Dados e Parâmetros
    % % --- Dados das Barras ---
    num_barras = size(dados_barras, 1);
    idx_slack = find(dados_barras(:, 2) == 3);
    g_max_mw = dados_barras(:, 3);
    d_mw = dados_barras(:, 4);

    % Encontra os índices de barras com geradores e cargas
    geradores_idx = find(g_max_mw > 0);
    num_geradores = length(geradores_idx);
    cargas_idx = find(d_mw > 0);
    num_cargas = length(cargas_idx);

    % --- Dados dos Ramos ---
    num_ramos = size(dados_ramos, 1);
    from = dados_ramos(:, 1);
    to = dados_ramos(:, 2);
    n_ini = dados_ramos(:, 3);
    x_pu = dados_ramos(:, 5);
    fmax_mw = dados_ramos(:, 6);
    custo_circ = dados_ramos(:, 7);

    if isrow(Nij), Nij = Nij'; end % Garante que Nij seja vetor coluna

    %% 2. Montagem do Problema de Programação Linear (Modelo Agregado)
    % As variáveis de decisão (x) são apenas [thetas; g; r]
    num_vars = num_barras + num_geradores + num_cargas;

    % --- 2.1 Função Objetivo (min f'*x): min (alpha * sum(r)) ---
    % O custo de investimento é somado no final, pois não é uma variável
    f_obj = [zeros(num_barras + num_geradores, 1); alpha * ones(num_cargas, 1)];

    % --- 2.2 Restrições de Igualdade (Aeq*x = beq): B*theta + G*g + R*r = d ---
    B = zeros(num_barras, num_barras);
    y_pu = 1 ./ x_pu;
    n_final = n_ini + Nij;
    gamma_ficticia = 1e-5;
    for i = 1:num_ramos
        % A susceptância total é a dos circuitos reais + a fictícia.
        gamma = (n_final(i) * y_pu(i)) + gamma_ficticia;

        B(from(i), to(i)) = B(from(i), to(i)) - gamma;
        B(to(i), from(i)) = B(to(i), from(i)) - gamma;
        B(from(i), from(i)) = B(from(i), from(i)) + gamma;
        B(to(i), to(i)) = B(to(i), to(i)) + gamma;
    end
    G = zeros(num_barras, num_geradores);
    for i=1:num_geradores, G(geradores_idx(i), i) = 1; end
    R = zeros(num_barras, num_cargas);
    for i=1:num_cargas, R(cargas_idx(i), i) = 1; end
    Aeq = [B, G, R];
    beq = d_mw / Sb;

    % --- 2.3 Restrições de Desigualdade (A*x <= b): |theta_i - theta_j| <= phi_max ---
    A_ineq = []; b_ineq = [];
    for i = 1:num_ramos
        phi_max_unitario = fmax_mw(i) / (Sb * y_pu(i));

        % --- PONTO 2: FOLGA OPERACIONAL (Capacidade Angular Elevada) ---
        if n_final(i) == 0
            % Se não há circuitos reais, é um ramo FICTÍCIO.
            % A sua capacidade angular deve ser muito maior para não restringir o sistema.
            phi_max_total = phi_max_unitario * 10; % Fator de multiplicação
        else
            % Se há circuitos reais, a capacidade é a soma das capacidades individuais.
            phi_max_total = phi_max_unitario;
        end

        restricao = zeros(1, num_vars); % num_vars precisa ser definido antes
        restricao(from(i)) = 1; 
        restricao(to(i)) = -1;
        A_ineq = [A_ineq; restricao; -restricao];
        b_ineq = [b_ineq; phi_max_total; phi_max_total];
    end

    % --- 2.4 Limites das Variáveis (Bounds) ---
    lb = -inf(num_vars, 1);
    ub = inf(num_vars, 1);
    lb(idx_slack) = 0; ub(idx_slack) = 0; % Fixa o ângulo da barra slack

    g_vars_offset = num_barras;
    lb(g_vars_offset+1 : g_vars_offset+num_geradores) = 0;
    ub(g_vars_offset+1 : g_vars_offset+num_geradores) = g_max_mw(geradores_idx) / Sb;

    r_vars_offset = num_barras + num_geradores;
    lb(r_vars_offset+1 : end) = 0;
    ub(r_vars_offset+1 : end) = d_mw(cargas_idx) / Sb;

    %% 3. Execução do Solver e Extração dos Resultados
    options = optimoptions('linprog', 'Display', 'none');
    [x, ~, exitflag, ~, lambda] = linprog(f_obj, A_ineq, b_ineq, Aeq, beq, lb, ub, options);

    if exitflag == 1
        thetas = x(1:num_barras);
        r_vars = x(r_vars_offset+1 : end);
        pi_vals = lambda.eqlin;

        custo_invest = sum(custo_circ .* Nij);
        custo_corte = sum(r_vars) * alpha; % Custo do corte já penalizado
        FO = custo_invest + custo_corte;
    else
        custo_invest = Inf; custo_corte = Inf; FO = Inf;
        thetas = zeros(num_barras,1); pi_vals = zeros(num_barras,1);
    end
end