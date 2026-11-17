-- Somente leitura, apenas dos saldos das carteiras do usuário.
ALTER TABLE public.saldo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS saldo_select ON public.saldo;

CREATE POLICY saldo_select ON public.saldo
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.carteira c
    WHERE c.id = saldo.id_carteira
      AND c.id_usuario::text = (SELECT auth.user_id())
  ));