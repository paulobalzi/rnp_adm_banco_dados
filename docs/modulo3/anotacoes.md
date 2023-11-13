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
--  excluindo
curso=# DROP SCHEMA auditoria CASCADE;
~~~

#### Schemas pg_toast e pg_temp

São schemas criados pelo próprio PostgreSQL

Esses schemas poderão ter nomes como _pg_toast_, _pg_temp_N_ e _pg_toast_temp_N_
onde _N_ é um número inteiro

- pg_temp: identifica schemas utilizados para armazenar tabelas temporárias
- pg_toast / pg_toast_temp: armazenar tabelas que fazem uso do TOAST

## TOAST (The oversized attribute Storage Technique)

> Um recurso do PostgreSQL para tratar campos grandes

O PostgreSQL trabalha com páginas de dados de _8KB_ e não permite que um registro seja maior do que uma página.
Quando um campo tipo texto recebe uma valor maior do que 8KB, internamente é criada uma tabela chamada TOAST, que
criará registros auxiliares para armazenar o conteudo do campo.

> PostgreSQL compacta os dados armazenados em tabelas TOAST

## Tablespaces

São locais no sistema de arquivos onde o PostgreSQL, pode armazenar os arquivos de dados.

- é um diretório (file systemas)
- permite utilizar outros discos
  - expandir o espaço atual
  - questões de desempenho

Vantagem: Desempenho - possibilidade de dividir a carga entre mais discos, num problema de I/O.

Listar os tablespaces no servidor

~~~sql
postgres=# \db
~~~

Temos 2 (dois) tablespaces predefinidos
1. pg_default: aponta para o diretório __PGDATA/base__ (template default)
2. pg_global: aponta para o diretório __PGDATA/global__, que contém objetos que são compartilhados entre todas as bases

### Criação e Uso de Tablespaces

Para criar tablespace
1. diretório deve existir e estar vazio
2. ter o postgres como dono

> SOMENTE __SUPERUSUÁRIOS__ PODEM CRIAR TABLESPACES

Exemplo de usos

~~~sql
postgres=# create tablespace tbs_arquivo location '/disco/data'
curso=# create table registro (login varchar(20), datahora timestamp) tablespace tbs_arquivo
curso=# create index idx_data on compras(data) tablespace tbs_indices
postgres=# create database vendas tablespace tbs_dados;
curso=# alter index idx_data set tablespace tbs_dados;
postgres=# dorp tablespace tbs_arquivo;
~~~

~~~text
é possível definir os parâmetros de "custo", "seq_page", "random_page_cost", usados pelo otimizador de queries em um
tablespace específico
~~~

### Tablespace para tabelas temporárias

Quando são criadas tabelas temporárias ou uma query precisa ordenar grande quantidade de dados, essas operações armazenam
os dados de acordo com as configuração temp_tablespaces.
Esse parâmetro é uma lista de tablespaces qeu serão usados para manipulação de dados temporários. Se houver mais de um
tablespace, o POstgreSQL seleciona aleatoriamente.
Quando o parâmetro está __vazio__, é usado o tablespace padrão da base.

## Catálogo de Sistema do PostgreSQL

> pg_database, pg_namespace, pg_class, pg_proc, pr_roles, pg_view, pg_indexes, pg_stats, pg_availabe_extensions,
Views estatísticas

O catálogo de sistema ou dicionário de dados, contém as informações das bases e objetos criados no banco. São armazenados
em tabelas (objetos internos) e constituindo um meta modelo.
É uma rica fonte de informação e controle do SGBD.

#### __pg_database__

Contém informações das bases de dados do servidor. Ela é global, existe uma para toda instância.

| datname |Nome da base de dados |
|---|---|
| dattablespace |Tablespace default da base de dados |
| datacl |Privilégios da base de dados |

#### __pg_database__

Contém informações dos schemas da base atual.

|nspname| Nome do schema|
|---|---|
|nspowner| ID do dono do schema|
|nspacl| Privilégios do schema|

#### __pg_class__

A pg_class talvez seja a mais __importante tabela do catálogo__. Ela contém informações de tabelas, views, sequences,
índices e toast tables. Esses objetos são genericamente chamados de relações.

|relname| Nome da tabela ou visão ou índice|
|---|---|
|relnamespace| ID do schema da tabela|
|relowner| ID do dono da tabela|
|reltablespace| ID do tablespace que a tabela está armazenada. 0 se default da base|
|reltuples| Estimativa do número de registros|
|relhasindex| Indica se a tabela possui índices|
|relkind| Tipo do objeto: r = tabela, i = índice, S = sequência, v = visão, c = tipo composto, t = tabela TOAST, f = foreign table|
|relacl| Privilégios da tabela|
|relrowsecurity| Indica se a tabela está com a segurança por registro (RLS) ativada|
|relispartition| Indica se a tabela é uma partição|

#### __pg_proc__

Contém informações das funções da base atual.

|proname| Nome da função|
|---|---|
|prolang| ID da linguagem da função|
|pronargs| Número de argumentos|
|prorettype| Tipo de retorno da função|
|proargnames| Array com nome dos argumentos|
|prosrc| Código da função, ou arquivo de biblioteca do SO etc|
|proacl| Privilégios da função|

#### __pr_roles__

Essa é uma visão que usa a tabela __pg_authid__. Contém informações das roles de usuários e grupos.
Os dados de roles são `globais à instância`.

|rolname| Nome do usuário ou grupo|
|---|---|
|rolsuper| Se é um superusuário|
|rolcreaterole| Se pode criar outras roles|
|rolcreatedb| Se pode criar bases de dados|
|rolcanlogin| Se pode conectar-se|
|rolvaliduntil| Data de expiração|

#### __pg_view__

Contém informações das visões da base atual.

|viewname| Nome da visão|
|---|---|
|schemaname| Nome do schema da visão|
|definition| Código da visão|

#### __pg_indexes__

Contém informações dos índices da base atual.

|schemaname| Schema da tabela e do índice|
|---|---|
|tablename| Nome da tabela cujo índice pertence|
|indexname| Nome do índice|
|definition| Código do índice|

#### __pg_stats__

Contém informações mais legíveis das estatísticas dos dados da base atual.

|schemaname| Nome do schema da tabela cuja coluna pertence|
|---|---|
|tablename| Nome da tabela cuja coluna pertence|
|Attname| Nome da coluna|
|null_frac| Percentual de valores nulos|
|avg_width| Tamanho médio dos dados da coluna, em bytes|
|n_distinct| Estimativa de valores distintos na coluna|
|most_common_vals| Valores mais comuns na coluna|
|Correlation| Indica um percentual de ordenação física dos dados em relação à ordem lógica|

#### __pg_availabe_extensions__

Lista as extensões disponíveis e instaladas com a versão.

|name| Nome da extensão|
|---|---|
|default_version| Versão padrão da extensão|
|installed_version| Se instalada, a versão da extensão (pode ser diferente do padrão)|

### __Views estatísticas__

O catálogo do PostgreSQL contém diversas visões estatísticas que fornecem informações que nos ajudam no monitoramento do
que está acontecendo no banco. Essas visões contêm dados acumulados sobre acessos a bases e objetos.
Entre essas visões, destacamos:

> pg_stat_activity, pg_locks, pg_stat_database, pg_stat_user_tables

#### __pg_stat_database__

Essa visão mantém informações estatísticas das bases de dados. Os números são acumulados desde o último reset de estatísticas.
As colunas xact_commit e xact_rollback, somadas, fornecem o número de transações ocorridas no banco.
Com o número de blocos lidos e o número de blocos encontrados, podemos calcular o percentual de acerto no cache do PostgreSQL.
As colunas temp_files e deadlock devem ser acompanhadas, já que números altos podem indicar problemas.

|Datname| Nome da base de dados|
|---|---|
|xact_commit| Número de transações confirmadas|
|xact_rollback| Número de transações desfeitas|
|blks_read| Número de blocos lidos do disco|
|blks_hit| Número de blocos encontrados no Shared Buffer cache|
|temp_files| Número de arquivos temporários|
|Deadlocks| Número de deadlocks|
|stats_reset| Data/hora em que as estatísticas foram reiniciada|

#### __pg_stat_user_tables__

Essa visão contém estatísticas de acesso para as tabelas da base atual, exceto para as tabelas de sistema (as tabelas do próprio catálogo).

|Schemaname| Nome do schema da tabela|
|---|---|
|Relname| Nome da tabela|
|seq_scan| Número de seqscans (varredura sequencial) ocorridos na tabela|
|idx_scan| Número de idxscans (varredura de índices) ocorridos nos índices da tabela|
|n_live_tup| Número estimado de registros|
|n_dead_tup| Número estimado de registros mortos (excluídos ou atualizados, mas ainda não removidos fisicamente)|
|last_vacuum / last_ autovacuum| Hora da última execução de um vacuum/autovacum|
|last_analyze / last_ autoanalyze| Hora da última execução de um analyze/auto analyze|

