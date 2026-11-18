-- Lê e cria apenas movimentações das próprias carteiras.
-- status e data ficam com o DEFAULT do banco.
ALTER TABLE public.movimentacao_fiat ENABLE ROW LEVEL SECURITY;

CREATE POLICY movimentacao_fiat_select ON public.movimentacao_fiat
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.carteira c
    WHERE c.id = movimentacao_fiat.id_carteira
      AND c.id_usuario::text = (SELECT auth.user_id())
  ));

CREATE POLICY movimentacao_fiat_insert ON public.movimentacao_fiat
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.carteira c
    WHERE c.id = movimentacao_fiat.id_carteira
      AND c.id_usuario::text = (SELECT auth.user_id())
  ));