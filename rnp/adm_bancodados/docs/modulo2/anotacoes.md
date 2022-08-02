# MODULO 02 - OPERAÇÃO E CONFIGURAÇÃO

__tags__

~~~text
Superusuário; Área de Dados; Variáveis de Ambiente; Utilitários pg_ctl e initdb, 
PID e Sinais de Interrupção de Processos.
~~~

## Colocando o banco de dados em operação

__Passos__

1. Criar conta do superusuário.
2. Configurar variáveis de ambiente.
3. Inicializar área de dados.
4. Operações básicas do banco.
5. Configuração.

### 1. Criar conta do superusuário

Criar a conta sob a qual o serviço será executado e que será utilizada para administrá-lo.

~~~bash
$ sudo useradd --create-home --user-group --shell /bin/bash postgres

-- definir senha
$ sudo passwd postgres

-- permissão na pasta /db
$ sudo chown -R postgres /db
~~~

Parametros:
- --create-home: criação do diretório do usuário em home
- --shell: interpretador shell
- --user-group: criação de um grupo de mesmo nome

### 2. Configurar variáveis de ambiente

Deverá ser definido a localizlação dos  binários do PostgreSQL e a variável
__PGDATA__ que indica o diretório de dados do PostgreSQL.

~~~bash
$ su - postgres
$ vim ~/.bashrc
~~~

Adicionar no final do arquivo

~~~text
PATH=$PATH:/usr/local/pgsql/bin:$HOME/bin
PGDATA=/db/data/
export PATH PGDATA
export “PAGER=less -S”
~~~

Carregando as alterações
~~~bash
$ source ~/.bashrc
~~~

### 3. Inicializando a área de dados

Para que o PostgreSQL funcione, é necessário inicializar o diretório de dados, ou área de dados,
chamada também de cluster de bancos de dados. Essa área é o diretório que conterá, a princípio,
todos os dados do banco e toda a estrutura de diretórios, além de arquivos de configuração do
PostgreSQL.

Criação da área de dados na partição /db pode

~~~bash
$ initdb
~~~

Sem a definição da variável _PGDATA_, o comando poderia ser `$ initd -D /db/data`.
Opção para verificação de inconsistência: __--data-checksums__.

### 4. Operações básicas do banco

#### Inciando o PostgreSQL

Como o nome do executável principal é __postgres__, podemos iniciar o bancos assim:

~~~bash
postres -D /db/data
~~~

PGDATA definida
~~~bash
$ postgres

-- rodar em background
$ postgres &
~~~

Capturando saída padrão (stdout) e de erros (stderr)
~~~bash
$ postgres > /db/data/log/postgresql.log 2>&1 &
~~~

Com o utilitário pg_tcl (__recomendado__)
~~~bash
$ pg_ctl start
~~~
Necessário indicar no arquivo de configuração do PostgreSQL (__postgresql.conf__)
onde deverão ser armazenados os arquivos de log.

#### Execução automática (inicialização do SO)

~~~bash
$ cd path/to/postgresql-13.1/contrib/start-scripts/
$ sudo cp linux /etc/init.d/postgresql
$ sudo vi /etc/init.d/postgresql
$ sudo chmod +x /etc/init.d/postgresql
$ sudo update-rc.d postgresql defaults
~~~

#### Parando PostgreSQL

Obtendo o PID do processo postgreSQL
~~~bash
$ ps -ef f | grep postgres

--- ou consultar o arquivo postmaster.pid
cat /db/data/postmaster.pid
~~~

Utilizando o comando __kill__. Há 3 sinas possíveis para parar o serviço:

- __TERM__: modo smart. banco não aceitará novas conexões, mas aguarda as conexões 
existentes terminarem. `kill -TERM 815`
- __INT__: fast shutdown. banco não aceita novas conexões e enviará um sinal _TERM_
para todas as conexões existentes abortarem suas transações. Tbem aguardará as conexões
terminarem para parar o banco. `kill -INT 815`
- __QUIT__: immediate shutdown. Todas as conexções terminam imediatamente. Como consequência, 
o banco entrará em mode __recovery__ para desfazer as transações incompletas.`kill -QUIT 815`

Utilizando o utilitário __pg_ctl__

- __smart__: pg_ctl stop -ms
- __fast__: pg_ctl stop -mf
- __immediate__: pg_ctl stio -mi

#### Reiniciar/Recarregar o PostgreSQL

~~~bash
$ pg_ctl restart

-- recarregando parametros
$ pg_ctl reload
~~~

#### Processos PostgreSQL

Verificar se o PostgreSQL está executando
~~~bash
$ ps -ef f | grep postgres
-- ou
$ pg_ctl status
~~~

#### Interromper um processo PostgreSQL

~~~bash
$ pg_ctl kill TERM 1520
~~~
obs: pg_terminate_backend(pid). interromper o processo dentro do banco

#### Outros comandos

~~~bash
-- conectando
$ psql -h pg02 -p 5432 -d curso -U aluno

-- executando um script sql
$ psql -h pg02 -d curso < /tmp/arquivo.sql
~~~

#### Resumo

~~~text
Iniciar o banco                 $pg_ctl start
Parar o banco                   $pg_ctl stop -mf
Reiniciar o banco               $pg_ctl restart
Reconfigurar o banco            $pg_ctl reload
Verificar o status do banco     $pg_ctl status
Matar um processo               $pg_ctl kill TERM <pid>
Conectar no banco               $psql -h pg01 -d curso
~~~

#### Socket

~~~bash
$ sudo mkdir /var/run/postgresql/
$ sudo chown postgres /var/run/postgresql/
~~~

Edite o postgresql.conf e altere o parâmetro unix_socket_directory:
~~~text
unix_socket_directory = '/var/run/postgresql'
~~~

### 5. Configuração

O PostgreSQL possui diversos parâmetros que podem ser alterados para definir seu
comportamento, desde o uso de recursos como memória e controle de conexões até custos de
processamento de queries, além de muitos outros aspectos.

Parâmetros de Configuração:

- Controle de Recursos de Memória.
- Controle de Conexões.
- O quê, quando e como registrar.
- Custos de Queries.
- Replicação.
- Vacuum, Estatísticas.

Escopo dos parâmetros:

- Por sessão.
- Por usuário.
- Por Base de Dados.
- Global.

Podem ser alterados globalmente (permanente) editando o arquivo __postgresql.conf__,
ou através do comando `alter system`, refletindo as mudançãs nas sessões dali pra
frente. Também podem ser definidos para uma seção específica, um usuário ou base específica.
Podemos passar essas configurações por linha de comando na inicialização do servidor.

Exemplos:
- por sessão: `curso=> SET timezone = 'America/New_York';`
- por usuário: `postgres=# ALTER ROLE jsilva SET work_mem = ‘16MB’;`
- por base de dados: `postgres=# ALTER DATABASE curso SET work_mem = ’10MB’;`

#### Desfazendo uma configuração

~~~sql
postgres=# ALTER ROLE jsilva RESET work_mem;
postgres=# ALTER DATABASE curso RESET work_mem;
~~~

#### ALTER SYSTEM

Nas últimas versões do PostgreSQL, foi introduzido o comando ALTER SYSTEM, que nos permite
alterar um parâmetro de forma global sem termos de editar manualmente o arquivo de
configuração. O seguinte exemplo altera um parâmetro e recarrega as configurações direto no
banco:

~~~sql
postgres=# ALTER SYSTEM SET maintenance_work_mem = ‘64MB’;
postgres=# select pg_reload_conf();
~~~

#### Arquivo postgresql.conf - principais parâmentros

|Parâmentro|Descrição|Valor|
|---|---|---|
|listen_addresses|--|--|
|max_connections|--|--|
statement_timeoutTempo máximo de execução para um comando. Passado esse valor, o comando será cancelado|--|
|shared_buffers|Área da shared memory reservada ao PostgreSQL, é o cache de dados do banco|--|
|work_mem|Memória máxima por conexão para operações de ordenação|--|
|Ssl|Habilita conexões SSL|--|
|superuser_reserved_connections|Número de conexões, dentro de max_connections, reservada para o superusuário postgres|--|
|effective_cache_size|Estimativa do Otimizador sobre o tamanho do cache. É usada para decisões de escolha de planos de execução de queries.|--|
|logging_collector|Habilita a coleta de logs, interceptando a saída para stderr e enviando para arquivos|--|
|Datestyle|Formato de exibição de datas|--|
|lc_messages|Idioma das mensagens de erro|--|
|lc_monetary|Formato de moeda|--|
|lc_numeric|Formato numérico|--|
|lc_time|Formato de hora|--|

#### Consultando as configurações atuais

~~~sql
-- mostrar todos
curso=# SHOW ALL;
-- um parâmtero específico
curso=# SHOW max_connections;
~~~

#### Considerações sobre configurações do Sistema Operacional

Além das configurações do PostgreSQL, podem ser necessários ajustes nas configurações do
Sistema Operacional, principalmente relacionados a:
- Shared memory.
- Semáforos.
- Limites.

##### Shared Memory

~~~bash
-- consultar o valor
$ sysctl kernel.shmmmax
-- definir um valor
$ kernel.shmmax = 8589934592
~~~

##### Semáforos

~~~bash
$ sysctl kernel.sem
kernel.sem = 250 32000 32 128
~~~
temos:
- 250 = SEMMSL
- 32000 = __SEMMNS__ => número total de semáfaros
- 32 = SEMOPM
- 128 = __SEMMNI__ => número de conjunto de semáfaros

##### Limites

__mx user processes__ e __open files__

Para consultar o valor atual: `$ ulimit -n -u`

Para alterar, editar o arquivo __/etc/security/limits.conf__