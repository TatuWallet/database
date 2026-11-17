-- Lê a transação se a carteira de origem ou de destino for do usuário.
-- Escrita não é liberada: transações são criadas pelo backend.
ALTER TABLE public.transacao ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS transacao_select ON public.transacao;

CREATE POLICY transacao_select ON public.transacao
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.carteira c
    WHERE c.id_usuario::text = (SELECT auth.user_id())
      AND c.id = ANY (ARRAY[transacao.id_carteira_origem, transacao.id_carteira_destino])
  ));