-- Cada usuário vê e edita só o próprio registro (id = sub do JWT).
ALTER TABLE public.usuario ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS usuario_select ON public.usuario;
DROP POLICY IF EXISTS usuario_insert ON public.usuario;
DROP POLICY IF EXISTS usuario_update ON public.usuario;

CREATE POLICY usuario_select ON public.usuario
  FOR SELECT TO authenticated
  USING (id::text = (SELECT auth.user_id()));

CREATE POLICY usuario_insert ON public.usuario
  FOR INSERT TO authenticated
  WITH CHECK (id::text = (SELECT auth.user_id()));

CREATE POLICY usuario_update ON public.usuario
  FOR UPDATE TO authenticated
  USING      (id::text = (SELECT auth.user_id()))
  WITH CHECK (id::text = (SELECT auth.user_id()));