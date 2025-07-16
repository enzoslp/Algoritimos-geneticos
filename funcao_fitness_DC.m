function [FO, custo_invest, custo_corte] = funcao_fitness_DC(Nij, dados_barras, dados_ramos, Sb, alpha)
 % Dados Barras
    LenB = size(dados_barras,1); % Número de barras
    g_max = dados_barras(:,3).'; % Capacidade máxima de geração (MW)
    d = dados_barras(:,4).';     % Demanda (MW)
    idx_slack = find(dados_barras(:,2) == 3); % Localiza a barra slack
    
    % Dados Linhas
    LenL = size(dados_ramos,1);   % Número de ramos (caminhos)
    from = dados_ramos(:,1).';    % Barra "De"
    to = dados_ramos(:,2).';      % Barra "Para"
    N_ini = dados_ramos(:,3).';   % Número de circuitos iniciais
    fmax = dados_ramos(:,6).';    % Limite de fluxo por circuito (MW)
    c = dados_ramos(:,7);       % Custo por circuito
    %N_max = dados_ramos(:,8).';   %Numero maximo de circuitos finais
    y = 1./dados_ramos(:,5).';    % Susceptância por circuito (1/x)

    g_max = g_max/Sb;
    d = d/Sb;
    fmax = fmax/Sb; 

    % --- Função Objetivo ---
    % min alpha*sum(ri). O custo do investimento (c'*Nij) é adicionado
    % no final, pois Nij é um dado de entrada e não uma variável.
    f = [zeros(1, LenL), zeros(1, LenB), zeros(1, LenB), alpha*ones(1, LenB)];

    % --- Restrições de Igualdade (Aeq*x = beq) ---
    % 1ª Lei de Kirchhoff: S*f + g + r = d
    S = zeros(LenB, LenL);
    for k = 1:LenL
        i = dados_ramos(k,1); % sender
        j = dados_ramos(k,2); % receiver
        S(i,k) = -1; % Fluxo saindo da barra
        S(j,k) = 1; % Fluxo entrando na barra
    end

    Aeq1 = [S, eye(LenB), zeros(LenB, LenB), eye(LenB)];
    beq1 = d';
    
    % 2ª Lei de Kirchhoff: fij - y_total * (thi - thj) = 0
    Aeq2 = zeros(LenL, LenL + 3*LenB);
    beq2 = zeros(LenL, 1);
    
    for k = 1:LenL
        Aeq2(k, k) = 1; % Coeficiente para fij
        % Coeficientes para os ângulos θi e θj
        y_total = y(k) * (N_ini(k) + Nij(k));
        Aeq2(k, LenL+LenB+from(k)) = -y_total;
        Aeq2(k, LenL+LenB+to(k))   =  y_total;
    end
    
    Aeq = [Aeq1; Aeq2];
    beq = [beq1; beq2];

    % --- Restrições de Desigualdade (A*x <= b) ---
    % Limites de fluxo: |fij| <= fmax_total

    % fij <= (N_ini + Nij)*fmax
    A1 = [eye(LenL), zeros(LenL, LenB), zeros(LenL, LenB), zeros(LenL, LenB)];
    
    % -fij <= (N_ini + Nij)*fmax
    A2 = [-eye(LenL), zeros(LenL, LenB), zeros(LenL, LenB), zeros(LenL, LenB)];

    A = [A1; A2];

    fmax_total = (N_ini' + Nij').*fmax';
    b = [fmax_total; fmax_total];

    % --- Limites das Variáveis (lb <= x <= ub) ---
    % g >=0 e r >= 0
    lb = [-Inf*ones(1, LenL), zeros(1, LenB), -Inf*ones(1, LenB), zeros(1, LenB)];
    % g <= g_max e r <= d
    ub = [Inf*ones(1, LenL), g_max, Inf*ones(1, LenB), d];

    % --- Implementação da Barra de Referência (Slack) ---
    % Localiza a posição da variável theta_slack no vetor 'x'
    idx_theta_slack = LenL + LenB + idx_slack;
    % Força o ângulo a ser zero, definindo seus limites inferior e superior como 0
    lb(idx_theta_slack) = 0;
    ub(idx_theta_slack) = 0;

    %% linprog
    options = optimoptions('linprog', 'Display', 'off');
    [x, ~, exitflag] = linprog(f, A, b, Aeq, beq, lb, ub, options);
    
    % --- Cálculo e atribuição das 3 saídas ---
    if exitflag == 1

        fij = x(1:LenL);
        g = x(LenL+1 : LenL+LenB);
        th = x(LenL+LenB+1 : LenL+2*LenB);
        ri = x(LenL+2*LenB+1 : end);        
        
        % SAÍDA 2: Custo de Investimento
        custo_invest = sum(c' .* Nij);
        
        % SAÍDA 3: Custo de Corte de Carga (Unfitness)
        custo_corte = alpha * sum(ri);
        
        % SAÍDA 1: Função Objetivo Total (Fitness Total)
        FO = custo_invest + custo_corte;
    else
        % Se a solução falhar, retorna valores de falha para todas as saídas
        custo_invest = Inf;
        custo_corte = Inf;
        FO = Inf;
    end
end