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
base, global, pg_wal, log, pg_tblspc, diretórios de controle de transação, 
diretórios de controle de replicação e outras funções
~~~

### Base

Diretório onde estão localizados os __arquivos de dados__. Dentro existe um subdiretório para cada base.

~~~text
base/
├── 1
├── 12661
└── 12662
~~~

Os números indicam o _OID_ da base, que pode ser obtido consultando a tabela do catálago _pg\_database_

~~~sql
postgres=# select oid, datname from pg_database;

  oid  |  datname  
-------+-----------
 12662 | postgres
     1 | template1
 12661 | template0
(3 rows)
~~~

- Dentro do diretório de cada base estão os arquivos das tabelas e índices
- Cada tabela ou índice possui um ou mais arquivos. 
- Uma tabela terá inicialmente um arquivo, cujo nome é o atributo filenode que pode ser obtido nas tabelas de catálogo. 
- O tamanho máximo do arquivo é 1GB. 
- Ao alcançar o limite de 1GB, serão criados mais arquivos, cada um com o nome filenode.N, onde N é um incremental.

Para descobrir o nome dos arquivos das tabelas, consulte o filenode com o seguinte comando:

~~~sql
curso=> SELECT relfilenode FROM pg_class WHERE relname=’grupos’
curso=> SELECT pg_relation_filepath(oid) FROM pg_class WHERE relname=’grupos’
~~~

Além dos arquivos de dados, existem arquivos com os seguintes sufixos:
- _fsm: para o Free Space Map, indicando onde há espaço livre nas páginas das tabelas.
- _vm: para o Visibility Map, que indica as páginas que não precisam passar por vacuum.
- _init: para unlogged tables.
- arquivos temporários: cujo nome tem o formato tNNN_filenode, onde NNN é o PID do processo backend que está usando o arquivo.

### global

O diretório global contém os dados das tabelas que valem para toda a instância e são visíveis de qualquer base. 
São tabelas do catálogo de dados como, por exemplo, _pg_databases_.


### pg_wal

Contém as logs de transação do banco e os arquivos de WAL, que são arquivos contendo os registros das transações efetuadas.

__Características dos arquivos de logs__
- 16MB de tamanho
- O nome é uma sequência numérica hexadecimal
- Após checkpoints e arquivamento, os arquivos são reciclados.

~~~text
postgres@debian10:~$ ls -lah /db/data/pg_wal/
total 17M
drwx------  3 postgres postgres 4.0K Jul 28 02:23 .
drwx------ 20 postgres postgres 4.0K Aug  2 02:08 ..
-rw-------  1 postgres postgres  16M Aug  2 02:13 000000010000000000000001
drwx------  2 postgres postgres 4.0K Jul 28 02:23 archive_status
~~~

O diretório __archive_ status__ contém informações de controle sobre quais arquivos já foram arquivados.

### log

Pode existir ainda o diretório “log”, dependendo de suas configurações, que contém os logs de
erro e atividade. Antes da versão 10, esse diretório era chamado pg_log.

Se for habilitada a coleta de log com o parâmetro logging_collector, o diretório padrão será esse;
porém, diferentemente dos pg_wal (antigo pg_xlog) e pg_xact (antigo pg_clog), este pode ser
alterado. Os nomes dos arquivos dependem também das configurações escolhidas.


### pg_tblspc


### diretórios de controle de transação

Diretórios que contêm arquivos de controle de status de transações diversas

- pgdata/pg_xact (chamado pg_clog antes da versão 10).
- pgdata/pg_serial.
- pgdata/pg_multixact.
- pgdata/pg_subtrans.
- pgdata/pg_twophase.
- pgdata/commit_ts.

### diretórios de controle de replicação e outras funções

Diretórios contendo, por exemplo, informações para controle de replicação e estatísticas, entre outras funções:

 - pgdata/dynshmem.
 - pgdata/pg_logical.
 - pgdata/pg_notify.
 - pgdata/replslot.
 - pgdata/pg_stat.
 - pgdata/pg_stat_tmp.


## Organização geral

### Base de dados

> Uma base de dados é uma coleção de objetos como tabelas, visões e funções

- Um servidor pode ter diversas bases.
- Toda conexão é feita em uma base.
- Não se pode acessar objetos de outra base.
- Bases são fisicamente separadas.
- Toda base possui um owner com controle total nela.

Quando uma instância é iniciada, com o initdb, três bases são criadas:

- __template0__: usado para recuperação pelo próprio Postgres, não é alterado.
- __template1__: por padrão, serve de modelo para novos bancos criados.
- __postgres__: base criada para conectar-se por padrão, não sendo necessária para o funcionamento do PostgreSQL

> Toda base possui um dono que, caso não seja informado no momento da criação, será o usuário que está executando o comando. Apenas superusuários ou quem possui a role CREATEDB podem criar novas bases

#### Criação de base de dados

~~~sql
postgres=# CREATE DATABASE rh OWNER postgres ENCODING ‘UTF-8’ TABLESPACE = tbs_disco2;
~~~

ou 

~~~bash
$ createdb rh -O postgres -E UTF-8 -D tbs_disco2
~~~

- OWNER: o usuário dono da base pode criar schemas e objetos, e dar permissões.
- TEMPLATE: a base modelo a partir da qual a nova base será copiada.
- ENCODING: que define o conjunto de caracteres a ser utilizado.
- TABLESPACE: que define o tablespace padrão onde serão criados os objetos na base.

#### Exclusão de bases de dados

~~~sql
postgres=# DROP DATABASE curso;
~~~

ou

~~~bash
$ dropdb curso;
~~~

### Schemas

> Bases podem ser organizadas em schemas, que são apenas uma divisão lógica para os objetos do banco, sendo permitido 
acesso cruzado entre objetos de diferentes schemas.

- podem existir objetos com o mesmo nome em schemas diferentes.
- Quando referenciamos ou criamos um objeto sem informar o nome completo, costuma-se entender que ele está ou será 
criado no schema __public__
- O __search_path__ é um parâmetro que define justamente a ordem e quais schemas serão varridos quando um objeto for 
referenciado sem o nome completo.

~~~sql
postgres=# show search_path;
   search_path   
-----------------
 "$user", public
(1 row)
~~~

__$user__ significa o nome do próprio usuário conectado

No exemplo `curso=# SELECT * FROM grupos;`, o postgresql fará o procedimento abaixo
1. procurar uma tabela/visão de nome "grupos" no schema "aluno"
2. caso não encontre, irá procurar no schema public
3. caso negativo, erro.

> Uma prática comum é criar um schema para todos os objetos da aplicação e definir a variável search_path 
para esse schema. 

> O parâmetro search_path pode ser definido para uma sessão apenas, para um usuário ou para uma base.

#### Criação/Exclusão de schema

~~~sql
curso=# CREATE SCHEMA auditoria;
-- definindo dono do schema
curso=# CREATE SCHEMA auditoria AUTHORIZATION aluno;
--  escluindo
curso=# DROP SCHEMA auditoria CASCADE;
~~~

PAREI PAGINA pg_toast 





