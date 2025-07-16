function plano_otimizado = funcao_poda(plano_bruto, barras, ramos_base, S_base, penal_corte)
    plano_otimizado = plano_bruto;
    custo_atual = funcao_fitness_DC(plano_otimizado, barras, ramos_base, S_base, penal_corte);
    idx_candidatos = find(plano_otimizado > 0);
    if isempty(idx_candidatos), return; end
    custos_circuitos = ramos_base(idx_candidatos, 7);
    [~, ordem_poda] = sort(custos_circuitos, 'descend');
    idx_candidatos_ordenados = idx_candidatos(ordem_poda);
    
    for i = 1:length(idx_candidatos_ordenados)
        k = idx_candidatos_ordenados(i);
        while plano_otimizado(k) > 0
            plano_teste = plano_otimizado;
            plano_teste(k) = plano_teste(k) - 1;
            custo_teste = funcao_fitness_DC(plano_teste, barras, ramos_base, S_base, penal_corte);
            if custo_teste <= custo_atual
                plano_otimizado = plano_teste;
                custo_atual = custo_teste;
            else
                break;
            end
        end
    end
end