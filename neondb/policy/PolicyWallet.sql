-- Só as carteiras do próprio usuário.
ALTER TABLE public.carteira ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS carteira_select ON public.carteira;
DROP POLICY IF EXISTS carteira_insert ON public.carteira;
DROP POLICY IF EXISTS carteira_update ON public.carteira;

CREATE POLICY carteira_select ON public.carteira
  FOR SELECT TO authenticated
  USING (id_usuario::text = (SELECT auth.user_id()));

CREATE POLICY carteira_insert ON public.carteira
  FOR INSERT TO authenticated
  WITH CHECK (id_usuario::text = (SELECT auth.user_id()));

CREATE POLICY carteira_update ON public.carteira
  FOR UPDATE TO authenticated
  USING      (id_usuario::text = (SELECT auth.user_id()))
  WITH CHECK (id_usuario::text = (SELECT auth.user_id()));

-- As policies de outras tabelas consultam carteira por id_usuario.
CREATE INDEX IF NOT EXISTS idx_carteira_usuario ON public.carteira (id_usuario);