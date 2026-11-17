-- Tabela: criptomoeda
-- Leitura liberada para qualquer usuário logado.
ALTER TABLE public.criptomoeda ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS criptomoeda_select ON public.criptomoeda;

CREATE POLICY criptomoeda_select ON public.criptomoeda
  FOR SELECT TO authenticated
  USING (true);