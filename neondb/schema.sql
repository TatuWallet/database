-- =====================================================================
-- CriptoFinance: schema (public)
-- Gerado a partir do pg_dump do Neon (PostgreSQL 18).
-- Não inclui RLS, policies nem grants: ver bd/policy.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------
CREATE TYPE public.tipo_transacao_enum      AS ENUM ('compra', 'venda', 'transferencia');
CREATE TYPE public.tipo_movimentacao_enum   AS ENUM ('deposito', 'saque');
CREATE TYPE public.status_movimentacao_enum AS ENUM ('pendente', 'concluido', 'cancelado');

-- ---------------------------------------------------------------------
-- usuario
-- ---------------------------------------------------------------------
CREATE TABLE public.usuario (
    id             uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
    nome           varchar(100) NOT NULL,
    email          varchar(255) NOT NULL UNIQUE,
    data_cadastro  timestamptz  NOT NULL DEFAULT now(),
    ativo          boolean      NOT NULL DEFAULT true,
    username       varchar(50)
);

CREATE UNIQUE INDEX usuario_username_key
    ON public.usuario (lower(username)) WHERE username IS NOT NULL;

-- ---------------------------------------------------------------------
-- criptomoeda
-- ---------------------------------------------------------------------
CREATE TABLE public.criptomoeda (
    id                 bigint       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome               varchar(100) NOT NULL UNIQUE,
    simbolo            varchar(10)  NOT NULL UNIQUE,
    decimais           smallint     NOT NULL DEFAULT 18,
    endereco_contrato  varchar(42),               -- NULL = moeda nativa (ETH)
    ativa              boolean      NOT NULL DEFAULT true
);

-- ---------------------------------------------------------------------
-- carteira
-- ---------------------------------------------------------------------
CREATE TABLE public.carteira (
    id            integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome          varchar(100)  NOT NULL,
    saldo_fiat    numeric(20,2) NOT NULL DEFAULT 1000.00 CHECK (saldo_fiat >= 0),
    id_usuario    uuid          NOT NULL REFERENCES public.usuario(id) ON DELETE RESTRICT,
    endereco      varchar(42)   NOT NULL UNIQUE,
    data_criacao  timestamptz   NOT NULL DEFAULT now(),
    tipo          varchar(20)   NOT NULL DEFAULT 'SELF_CUSTODY'
                  CHECK (tipo IN ('SELF_CUSTODY', 'IMPORTADA', 'WATCH_ONLY'))
);

-- ---------------------------------------------------------------------
-- transacao
-- ---------------------------------------------------------------------
CREATE TABLE public.transacao (
    id                   bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo                 public.tipo_transacao_enum NOT NULL,
    valor_unitario       numeric      NOT NULL,
    id_cripto            bigint       NOT NULL REFERENCES public.criptomoeda(id),
    id_carteira_origem   integer      NOT NULL REFERENCES public.carteira(id),
    id_carteira_destino  integer      REFERENCES public.carteira(id),
    hash                 varchar(66)  UNIQUE,               -- NULL até ser enviada
    valor_wei            numeric(78,0) NOT NULL CHECK (valor_wei >= 0),
    nonce                bigint       CHECK (nonce IS NULL OR nonce >= 0),
    gas_price_wei        numeric(78,0),
    gas_limit            numeric(78,0),
    gas_usado            numeric(78,0),
    block_number         bigint,
    erro                 text,
    criada_em            timestamptz  NOT NULL DEFAULT now(),
    minerada_em          timestamptz,
    status               varchar(20)  NOT NULL DEFAULT 'PENDENTE'
                         CHECK (status IN ('PENDENTE', 'MINERADA', 'FALHA'))
);

CREATE INDEX idx_transacao_origem  ON public.transacao (id_carteira_origem);
CREATE INDEX idx_transacao_destino ON public.transacao (id_carteira_destino);
CREATE INDEX idx_transacao_status  ON public.transacao (status);

-- ---------------------------------------------------------------------
-- saldo (um saldo atual por carteira e criptomoeda)
-- ---------------------------------------------------------------------
CREATE TABLE public.saldo (
    id              bigint        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_carteira     integer       NOT NULL REFERENCES public.carteira(id),
    id_cripto       bigint        NOT NULL REFERENCES public.criptomoeda(id),
    quantidade_wei  numeric(78,0) NOT NULL DEFAULT 0 CHECK (quantidade_wei >= 0),
    atualizado_em   timestamptz   NOT NULL DEFAULT now(),
    CONSTRAINT uk_saldo UNIQUE (id_carteira, id_cripto)
);

-- ---------------------------------------------------------------------
-- preco_historico
-- ---------------------------------------------------------------------
CREATE TABLE public.preco_historico (
    id         bigint        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cripto  bigint        NOT NULL REFERENCES public.criptomoeda(id),
    preco_brl  numeric(20,8) NOT NULL,
    preco_usd  numeric(20,8),
    momento    timestamptz   NOT NULL DEFAULT now(),
    CONSTRAINT preco_historico_preco_check
        CHECK (preco_brl > 0 AND (preco_usd IS NULL OR preco_usd > 0)),
    CONSTRAINT uk_preco UNIQUE (id_cripto, momento)
);

-- ---------------------------------------------------------------------
-- movimentacao_fiat (depósito/saque em reais numa carteira)
-- ---------------------------------------------------------------------
CREATE TABLE public.movimentacao_fiat (
    id             integer       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_carteira    integer       NOT NULL REFERENCES public.carteira(id),
    tipo           public.tipo_movimentacao_enum NOT NULL,
    valor_fiat     numeric(20,2) NOT NULL CHECK (valor_fiat > 0),
    status         public.status_movimentacao_enum NOT NULL DEFAULT 'pendente',
    metodo         varchar(100)  NOT NULL,
    data           timestamptz   NOT NULL DEFAULT now(),
    moeda_fiat     char(3)       NOT NULL DEFAULT 'BRL',
    id_transacao   integer       REFERENCES public.transacao(id),
    cotacao_usada  numeric(20,8) CHECK (cotacao_usada IS NULL OR cotacao_usada > 0),
    -- ou tem transação e cotação, ou não tem nenhuma das duas
    CONSTRAINT movimentacao_fiat_conversao_check
        CHECK ((id_transacao IS NULL) = (cotacao_usada IS NULL))
);

CREATE INDEX idx_movfiat_carteira ON public.movimentacao_fiat (id_carteira);
CREATE INDEX idx_movfiat_status   ON public.movimentacao_fiat (status);
CREATE UNIQUE INDEX movimentacao_fiat_transacao_key
    ON public.movimentacao_fiat (id_transacao) WHERE id_transacao IS NOT NULL;