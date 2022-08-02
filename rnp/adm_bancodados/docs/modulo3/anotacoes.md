# Módulo 3 - Organização lógica e física dos dados

tags
~~~text
PGDATA; Catálogo; Instância; Schemas; Tablespaces; TOAST e metadados; Estrutura de iretórios e arquivos.
~~~

## Estrutura de diretórios e arquivos do PostgreSQL

Por padrão, o PostgreSQL organiza os dados e informações de controle sob o pgdata (Exemplo: /db/data)
- Todos os dados
- WAL (log de transações)
- Arquivos de configuração
- Log de erros

O que pode ser feito:
- base de dados podem ser armazenadas em outros locais através do uso de tablespaces
- WAL pode ser armazenado fora do PGDATA (uso de links simbólicos)
- arquivos de _logs de erros_ fora do PGDATA (configuração no arquivo postgresql.conf)
- arquivos de _configuração de segrança_ fora do PGDATA (configuração no arquivo postgresql.conf)

__o PGDATA sempre será a pasta principal do PostgreSQL__

### Exemplo de estrutura de diretórios do PostgreSQL

~~~text
/db/
└── data
    ├── base
    ├── current_logfiles
    ├── global
    ├── log
    ├── pg_commit_ts
    ├── pg_dynshmem
    ├── pg_hba.conf
    ├── pg_ident.conf
    ├── pg_logical
    ├── pg_multixact
    ├── pg_notify
    ├── pg_replslot
    ├── pg_serial
    ├── pg_snapshots
    ├── pg_stat
    ├── pg_stat_tmp
    ├── pg_subtrans
    ├── pg_tblspc
    ├── pg_twophase
    ├── PG_VERSION
    ├── pg_wal
    ├── pg_xact
    ├── postgresql.auto.conf
    ├── postgresql.conf
    ├── postmaster.opts
    └── serverlog
~~~
