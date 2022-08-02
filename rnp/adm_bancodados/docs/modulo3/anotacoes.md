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

## Arquivos de Configuração

1. __postgresql.conf__: Arquvivo principal de configuração do banco
2. __postgresql.auto.conf__: parâmetros alterados pelo comando `ALTER SYSTEM`, serão incluídos neste arquivo.
3. __pg_hba.conf__: controle de autenticação
4. __pg_ident.conf__: mapear usuários do SO para usuários do banco de dados em determinados métodos de autenticação
5. __postmaster.pid__: arquivo contendo o PID do processo principal em execução. Impede a execução duplicada do PostgreSQL
6. __postmaster.opts__: contém a linha de comando com todos os parâmetros usado para iniciar o serviço do PostgreSQL. Usado pelo pg_ctl para fazer o restart
7. __PG_VERSION__: contém a versão do PostgreSQL

## DIRETÓRIOS

~~~text
base, global, pg_wal, log, pg_tblspc, diretórios de controle de transação, diretórios de controle de replicação e outras funções
~~~

### Base







