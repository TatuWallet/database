// usuario
db.usuario.createIndex({ email: 1 }, { unique: true });
db.usuario.createIndex(
  { username: 1 },
  { unique: true, partialFilterExpression: { username: { $type: "string" } } }
);

// criptomoeda (o _id já é o símbolo)
db.criptomoeda.createIndex({ nome: 1 }, { unique: true });

// carteira: o mesmo endereço pode existir em redes diferentes
db.carteira.createIndex({ rede: 1, endereco: 1 }, { unique: true });
db.carteira.createIndex({ id_usuario: 1 });

// transacao: hash só existe depois de enviada, então o índice é parcial
db.transacao.createIndex(
  { hash: 1 },
  { unique: true, partialFilterExpression: { hash: { $type: "string" } } }
);
db.transacao.createIndex({ id_carteira_origem: 1, criada_em: -1 });
db.transacao.createIndex({ id_carteira_destino: 1, criada_em: -1 });
db.transacao.createIndex({ status: 1 });

// movimentacao_fiat: cada transação pertence a no máximo uma movimentação
db.movimentacao_fiat.createIndex({ id_transacao: 1 }, { unique: true });
db.movimentacao_fiat.createIndex({ id_carteira: 1, data: -1 });

// preco_historico: equivalente ao UNIQUE (id_cripto, momento) do SQL
db.preco_historico.createIndex({ id_cripto: 1, momento: -1 }, { unique: true });