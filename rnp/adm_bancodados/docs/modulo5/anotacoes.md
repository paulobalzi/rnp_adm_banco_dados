# MODULO 05 - MONITORAMENTO DE AMBIENTE

tags
> top; tps; vmstat; iostat; pg_activity; pg_stat_activity; pg_locks e pg_Badger.

Exemplo: problema de lentidão

1. consultar o _load_ (comandos topo ou htop)
2. Carga maior que o normal. Pode ser um processo sobrecarregando a CPU ou um execesso de processos.
3. Verificar memória (free ou top)
4. Pode estar ocorrendo swap. Verificar com o _sar_ ou _vmsat_
5. Gargalo de I/O. Verificar com o _top_ ou _iostat_
6. No caso do Banco de Dados, suspeitar se há processos bloqueados. Utilizar o _pg_activity_ e _pgAdmin_.
Ou consultar tabelas do catálogo que mostrem o status dos processos e os locks envolvidos
7. Uma transação aberta há muito tempo. Verificar pela view do catálogo pg_stat_activity ou pg_activity
8. Processo demorado, geração de muitos arquivos temporários. Consultar o log do PostgreSQL
9. Erro de SO. Consultar o syslog

O correto é fazer um levantamento do que é considerado normal (load):
- número de transações por segundo
- operações de I/O por segundo
- números de processos
- tempo máximo de queries
- tipos de queries
- etc

> Ferramentas de monitoramento: Nagios, Cacti, Zabbix

> Ferramentas PostgreSQL: pg_Fouine e pg_Badger

## MONITORANDO PELO SISTEMA OPERACIONAL

Em função da arquitetura do PostgreSQL, que trata cada conexão por um processo do SO, podemos monitorar a saúde do banco  monitorando os processos do SO pertencentes ao PostgreSQL. 
Exemplos de utilitários e ferramentas utilizadas para isso são:
- __top__
- __Vmstat__
- __Iostat__
- __sar e Ksar__

### TOP

Para monitorar processos no Linux. O top é um utilitário básico na administração de servidores

~~~bash
$ top -u postgres -c
~~~

Com o comando __top__ podemos verificar:
- O load médio dos últimos 1 minuto, 5 minutos e 15 minutos
- Processos em execução
- Percentual de CPU para processos %system, %user e esperando I/O (wa)
- Número total de processos
- Total de memória usada, livre, em cache ou em swap

~~~bash
Tasks:  85 total,   1 running,  84 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni, 96.7 id,  3.3 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :    987.4 total,    552.2 free,     59.3 used,    375.9 buff/cache
MiB Swap:   1953.0 total,   1953.0 free,      0.0 used.    764.7 avail Mem 

 PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
1161 postgres  20   0    8492   5132   3548 S   0.0   0.5   0:00.09 -bash
1169 postgres  20   0  242832  21436  20880 S   0.0   2.1   0:00.04 /usr/local/pgsql/bin/postgres
1170 postgres  20   0   14880   2564   2040 S   0.0   0.3   0:00.00 postgres: logger
1172 postgres  20   0  242832   2660   2092 S   0.0   0.3   0:00.00 postgres: checkpointer
1173 postgres  20   0  242832   2660   2092 S   0.0   0.3   0:00.02 postgres: background writer
1174 postgres  20   0  242832  10404   9820 S   0.0   1.0   0:00.01 postgres: walwriter
1175 postgres  20   0  243380   5428   4632 S   0.0   0.5   0:00.00 postgres: autovacuum launcher
1176 postgres  20   0   14964   2548   1980 S   0.0   0.3   0:00.00 postgres: stats collector
1177 postgres  20   0  243260   5232   4440 S   0.0   0.5   0:00.00 postgres: logical replication launcher
1183 postgres  20   0   11092   3652   3088 R   0.0   0.4   0:00.02 top -u postgres -c
~~~

Merece destaque a __coluna S__, que representa o estado do processo. O __valor “D”__ indica que o processo está bloqueado, geralmente aguardando operações de disco. Deve-se acompanhar se está ocorrendo com muita frequência ou por muito tempo.

### VMSTAT

Ela mostra diversas informações dos recursos por linha em intervalos de tempo passado como argumento na chamada.

~~~bash
$ vmstat 1

procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
1  0      0 565172  38052 346984    0    0     0     0   21   33  0  0 100  0  0
0  0      0 565172  38052 346984    0    0     0     0   29   52  0  0 100  0  0
0  0      0 565172  38052 346984    0    0     0     0   20   31  0  0 100  0  0
0  0      0 565172  38052 346984    0    0     0     0   18   29  0  0 100  0  0
0  0      0 565172  38052 346984    0    0     0     0   24   38  0  0 100  0  0
0  0      0 565172  38052 346984    0    0     0     0   22   35  0  0 100  0  0
~~~

Na primeira parte, procs, o vmstat mostra os números de processos. A coluna “r” são processos na fila prontos para executar, e “b” são processos bloqueados aguardando operações de I/O (que estariam com status D no top).

Na seção memory, existem as colunas semelhantes como vimos com top: swap, livre e caches (buffer e cache). A diferença na análise com a vmstat é entender as tendências. Podemos ver no top que há, por exemplo, 100MB usados de swap. Mas com a vmstat podemos acompanhar esse número mudando, para mais ou para menos, para nos indicar uma tendência no diagnóstico de um problema.

A seção swap mostra as colunas swap in (si), que são dados saindo de disco para memória, e swap out (so), que são as páginas da memória sendo escritas no disco. Em uma situação considerada normal, o Swap nunca deve acontecer, com ambas as colunas sempre “zeradas”. Qualquer anormalidade demanda a verificação do uso de memória pelos processos, podendo ser também originada por parâmetros de configuração mal ajustados ou pela necessidade do aumento de memória física.

> Na vmstat, o ponto de vista é sempre da memória principal, então IN significa “entrando na memória”, e OUT, “saindo”.

A seção io tem a mesma estrutura da seção swap, porém em relação a operações normais de I/O. A coluna blocks in (bi) indica dados lidos do disco para memória, enquanto a blocks out (bo) indica dados sendo escritos no disco.

As informações de memória, swap e I/O estão em blocos, por padrão de 1024 bytes. Use o parâmetro -Sm para ver os dados de memória em MBytes (não altera o formato de swap e io).

Na seção system, são exibidos o número de interrupções e trocas de contexto no processador. Servidores atuais, multiprocessados e multicore podem exibir números bem altos para troca de contexto; e altos para interrupções devido à grade atividade de rede.

Em cpu, temos os percentuais de processador para processos de usuários (us), do kernel (si), não ocupado (id) e aguardando operações de I/O (wa). Um I/O wait alto é um alerta, indicando que algum gargalo de disco está ocorrendo. Percentuais de cpu para system também devem ser observados, pois se estiverem fora de um padrão comumente visto podem indicar a necessidade de se monitorar os serviços do kernel.

### IOSTAT

Ferramenta para analisar situações de tráfego de I/O

~~~bash
-- atualizar os dados a cada 5 segundos
$ iostat -m 5

postgres@debian10:~$ iostat -m 5
Linux 4.19.0-21-amd64 (debian10.localdomain) 	08/09/2022 	_x86_64_	(1 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.14    0.01    0.32    2.47    0.00   97.06

Device             tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
sda              14.80         0.25         0.02        344         24

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.00    0.00    0.00    0.00    0.00  100.00

Device             tps    MB_read/s    MB_wrtn/s    MB_read    MB_wrtn
sda               0.00         0.00         0.00          0          0
~~~

O iostat exibe um cabeçalho com os dados já conhecidos de CPU e uma linha por device com as estatísticas de I/O. A primeira coluna é a tps, também conhecida como IOPS, que é o número de operações de I/O por segundo. Em seguida, exibe duas colunas com MB lidos e escritos por segundo, em média. As últimas duas colunas exibem a quantidade de dados em MB lidos e escritos desde a amostra anterior, no exemplo, a cada 5 segundos.

Repare que a primeira amostra exibe valores altíssimos porque ela conta o total de dados lidos e escritos desde o boot do sistema.

__Modo extendido__

~~~bash
postgres@debian10:~$ iostat -m 5 -x
Linux 4.19.0-21-amd64 (debian10.localdomain) 	08/09/2022 	_x86_64_	(1 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.12    0.01    0.28    2.19    0.00   97.40

Device            r/s     w/s     rMB/s     wMB/s   rrqm/s   wrqm/s  %rrqm  %wrqm r_await w_await aqu-sz rareq-sz wareq-sz  vctm  %util 
sda             11.40    1.70      0.22      0.02     0.39     2.05   3.31  54.72   11.41    1.64   0.13    19.47     9.46   2.05   2.69

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.00    0.00    0.20    0.20    0.00   99.60

Device            r/s     w/s     rMB/s     wMB/s   rrqm/s   wrqm/s  %rrqm  %wrqm r_await w_await aqu-sz rareq-sz wareq-sz  svctm  %util
sda              0.00    0.20      0.00      0.00     0.00     0.00   0.00   0.00    0.00    2.00   0.00     0.00     4.00   0.00   0.00
~~~

Duas colunas merecem consideração na forma estendida: await e %util. A primeira é o tempo médio, em milissegundos, que as requisições de I/O levam para serem servidas (tempo na fila e de execução). A outra, %util, mostra um percentual de tempo de CPU em que requisições foram solicitadas ao device. Apesar de esse número não ser acurado para arrays de discos, storages e discos SSD, um percentual próximo de 100% é certamente um indicador de saturação.

### SAR E KSAR

O __sar__ é uma ferramenta para reportar dados de CPU, memória, paginação, swap, I/O, huge pages, rede e mais.
Necessário ativar a coleta no arquivo de configuração. `/etc/default/sysstat`.

__ksar__, gerar gráficos sob demanda das estatísticas geradas pelo sar.

## MONITORANDO O POSTGRESQL

> pg_activity, pgAdmin, Nagios, Cacti, Zabbix.

### PG_ACTIVITY

Ferramenta para analisar processos específico para o PostgreSQL. Cruza informações de recursoso do SO com dados do banco sobre o processo, como qual a query em execução, há quanto tempo, se está bloqueada por outros processos e outras informações.

Características:
- considera o tempo em execução da query e não do processo (útil para o dba)
- apresenta cada processo na cor verde
- Se a query está em execução há mais de __0,5s__, é exibida em amarelo
- Vermelho se e estive em execução há mais de __1s__
- exibe: base, usuário, carga de leitura (READ/s) e escrita (WRITE/s) em disco
- Indica se o processo está bloqueado por outro (W) ou 
- se o processo está bloqueado aguardando operações de disco (IOW)

Acima dos processos, nos dados gerais no topo, é exibido o Transactions Per Second (TPS), que são operações no banco por segundo. Essa informação é uma boa métrica para acompanharmos o tamanho do ambiente. Ela indica qualquer comando disparado contra o banco, incluindo selects.

É possível alternar entre a exibição da query completa, identada ou apenas um pedaço inicial __pressionando a tecla “v”__

### PGADMIN4

### PGWATCH

Uma ferramenta de monitoramento exclusiva para PostgreSQ.

O PGWatch possui muitos painéis com informações estatísticas, entre eles:
- top queries
- DDL
- Informações de índices (não usados, duplicados e inválidos)
- Locks
- Estatísticas do pgBouncer ou pgPool
- Replicação
- E muitos outros

> __OBS__: pode ser utilizado com o grafana

### NAGIOS

O Nagios é open source e uma das ferramentas mais usadas para monitoramento de serviços e infraestrutura de TI.

O nagios trabalha basicamente alertando quando um indicador passa de determinado limite. É possível ter dois limites:
 - __warning__: normalmente é representado em amarelo na interface.
 - __critical__: normalmente em vermelho.

Podemos utilizar o Nagios para monitorar __dados internos do PostgreSQL através de plugins__, sendo o mais conhecido deles para o PostgreSQL o __check_postgres.pl__. Alguns exemplos de acompanhamentos permitidos pelo check_postgres são tabelas ou índices bloated (“inchados”), tempo de execução de queries, número de arquivos de WAL, taxa de acerto no cache ou diferença de atualização das réplicas.

Exemplos (check_postgres.pl):

- dispara um alerta como crítico se o tempo de replicação entre o servidor e a réplica for maior que 1 minuto

~~~bash
$ check_postgres.pl --action=hot_standby_delay --dbhost=pg01,pg02 –critical=’1 min’
~~~

- se alguma tabela da base “curso” não sofreu autovacuum nos últimos 3 dias para gerar um warning e 7 dias para critical:

~~~bash
$ check_postgres.pl --action=last_autovacuum –H pg01 –db curso –warning=’3d’ -- critical=’7d’
~~~

> __OBS__: o script check_postgres.pl pode ser usado de forma independente

### CACTI

É uma ferramenta para geração de gráficos, e não de emissão de alertas. Sua utilidade está em auxiliar na análise de dados históricos para diagnóstico de problemas ou para identificação dos padrões normais de uso dos recursos.
Outra utilidade é para planejamento de crescimento com base na análise, por exemplo, do histórico de percentual de uso de CPU ou uso de espaço em disco.

### ZABBIX

Ferramenta open source de monitoramento. Une funcionalidades de alertas do Nagios e plotagem de gráficos do Cacti. O Zabbix é mais flexível que o Nagios no gerenciamento de alertas, possibilitando ter mais níveis de estado para um alerta do que somente warning e critical.

#### PG_MONZ

E um template que adiciona o poder de monitorar diversos recursos internos ao banco de dados no Zabbix, como informações de transações e conteúdo das logs.

## MONITORANDO O POSTGRESQL PELO CATÁLOGO

Destacamos

> pg_stat_activity, pg_locks, pg_stat_database, pg_stat_user_tables

### PG_STAT_ACTIVITY

A pg_stat_activity é considerada extremamente útil por exibir uma fotografia do que os usuários estão executando em um determinado momento.

Características:
- contém mais informações, como a hora de início da transação.
- podemos manipulá-la com SELECT para listarmos apenas o que desejamos analisar

|||
|--|--|
|datid|ID da base de dados|
|datname|Nome da base de dados|
|pid|ID do processo|
|usesysid|ID do usuário|
|usename|Login do usuário|
|application_name|Nome da aplicação|
|client_addr|IP do cliente. Se for nulo, é local ou processo utilitário como o vacum|
|client_hostname|Nome da máquina cliente|
|client_port|Porta TCP do cliente|
|backend_start|Hora de início do processo. Pouco útil quando usado com pools|
|xact_start|Hora de início da transação. Null se não há transação ativa|
|query_start|Hora de início de execução da query atual ou início de execução da última query se state for diferente de ACTIVE|
|state_change|Hora da última mudança de estado|
|wait_event|Nome do evento/lock causando espera. Se o processo não estiver bloqueado, então NULL|
|wait_event_type|Tipo do evento causando espera. Classifica em mais alto nível os eventos de espera|
|state|active: a query está em execução no momento  <br>idle: não há query em execução <br>idle in transaction: há uma transação aberta, mas sem query executando no momento <br>idle in transaction(aborted): igual a idle in transaction, mas alguma query causou um erro|
|query|Query atual ou a última, se state for diferente de active|

Exemplos de uso da pg_stat_activity:

- buscando listar todos os processos da base curso que estão bloqueados há mais de 1h:
~~~sql
postgres=\# SELECT pid, usename, query_start 
    FROM pg_stat_activity 
    WHERE datname=’curso’ AND 
        wait_event is not null AND 
        (state_change + interval ‘1 hour’) < now();
~~~

- matar todos os processos que estão rodando há mais de 1h, mas não estão bloqueados

~~~sql
postgres=\# SELECT pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE datname=’curso’
    AND NOT wait_event is null
    AND (query_start + interval ‘1 hour’) < now();
~~~

### PG_LOCKS

A visão pg_locks contém informações dos locks mantidos por transações, explícitas ou implícitas, abertas no servidor.

|||
|--|--|
|Locktype|Tipo de objeto alvo do lock. Por exemplo: relation (tabela), tuple (registro), transactionid (transação)|
|Database|Base de dados|
|Relation|Relação (Tabela/Índice/Sequence…) alvo do lock, se aplicável|
|Transactionid|ID da transação alvo. Caso o lock seja para aguardar uma transação|
|Pid|Processo solicitante do lock|
|Mode|Modo de lock. Por exemplo: accessShareLock(SELECT), ExclusiveLock, RowExclusiveLock|
|Granted|Indica se o lock foi adquirido ou está sendo aguardado|

Em algumas situações mais complexas, pode ser necessário depurar o conteúdo da tabela pg_locks para identificar quem é o processo raiz que gerou uma cascata de locks. A seguinte query usa pg_locks e pg_stat_activity para listar processos aguardando locks de outros processos:

~~~sql
postgres=\# SELECT 
                waiting_stm.query as waiting_query,
                waiting.pid as waiting_pid,
                blocker.relation:;regclass as blocker_table
                blocker_stm.query as blocker_pid
                blocker.granted as blocker_granted
            FROM pg_locks as waiting,
                    pg_locks as blocker,
                    gg_stat_activity as waiting_stm,
                    pg_stat_activity as blocker_stm
            WHERE waiting_stm.pid = waiting.pid
                AND (
                        (waiting."database" = blocker."database" AND waiting.relation = blocker.relation) 
                        OR waiting.transactionid = blocker.transactionid
                    )
                AND blocker_Stm.pid = blocker.pid 
                AND NOT waiting.granted
                AND waiting.pid <> blocker.pid
            ORDER BY waiting_pid;
~~~

> A partir da versão 9.6, existe a função __pg_blocking_pids(int)__, que exibe quais outros processos estão bloqueando um processo informado.

~~~sql
postgres=\# select pg_blocking_pids(12939);
~~~

### PG_STAT_DATABASE

O primeiro exemplo consulta a view pg_stat_database e gera, como resultado, o número de transações totais, o transaction per second (TPS) médio e o percentual de acerto no cache para cada base do servidor:

~~~sql
postgres=\# SELECT datname,
                (xact_rollback + xact_commit) as total_transacoes,
                ((xact_rollback + xact_commit)/ EXTRACT(EPOCH FROM (now() - stats_reset))) as tps,
                CASE WHEN blks_hit = 0 THEN 0
                    ELSE ((blks_hit / (blks_read + blks_hit)::float) * 100)
                END as cache_hit
            FROM pg_stat_database
            WHERE datname NOT LIKE ‘template_’;
~~~

### PG_STAT_USER_TABLES

Nessa consulta, a view pg_stat_user_tables. O resultado obtido traz todas as tabelas e calcula o percentual de index scan em cada uma:

~~~sql
curso=\# SELECT schemaname, relname, seq_scan, idx_scan, ((idx_scan::float / (idx_scan + seq_scan)) * 100) as percentual_idxscan
        FROM pg_stat_user_tables
        WHERE (idx_scan + seq_scan) > 0
        ORDER BY percentual_idxscan;
~~~

### PG_DATABASE

Para listar todas as bases e seus respectivos tamanhos, ordenado da maior para menor:

~~~sql
postgres=\# SELECT pg_database.datname, 
                pg_size_pretty(pg_database_size(datname)) as tamanho
            FROM pg_database
            ORDER BY 1;
~~~

### PG_CLASS C

Um exemplo que lista os objetos, tabelas e índices que contêm mais dados no Shared Buffer, ou seja, que estão tirando maior proveito do cache, é:

~~~sql
postgres=\# SELECT n.nspname || ‘.’ || c.relname as objeto,
                pg_size_pretty(count(*) * 8192) as tamanho
            FROM pg_class c
            INNER JOIN pg_buffercache b ON b.relfilenode = c.relfilenode
            INNER JOIN pg_database d ON b.reldatabase = d.oid
            AND d.datname = current_database()
            INNER JOIN pg_namespace n ON c.relnamespace = n.oid
            GROUP BY n.nspname || ‘.’ || c.relname
            ORDER BY 2 DESC;
~~~

### PG_STAT_USER_INDEXES

Listar todos os índices por tabela, com quantidade de scans nos índices, ajuda a decidir a relevância e utilidade dos índices existentes. Essa informação pode ser obtida através da seguinte consulta:

~~~sql
postgres=\# SELECT r.relname as tabela, c.relname as indice,
            idx_scan as qtd_leituras
            FROM pg_stat_user_indexes i JOIN pg_class r ON i.relid=r.oid
            JOIN pg_class c ON i.indexrelid=c.oid
            JOIN pg_namespace nsp ON r.relnamespace=nsp.oid WHERE nspname NOT LIKE ‘pg_%’
            ORDER BY 1,2 DESC;
~~~

## MONITORANDO ESPAÇO EM DISCO

Funções úteis para consultarmos o consumo de espaço por tabelas, índices e bases inteiras

|funções|descrição|
|--|--|
|pg_database_size|(nome)Tamanho da base de dados|
|pg_relation_size|(nome)Tamanho somente da tabela, sem índices e toasts|
|pg_table_size|(nome)Tamanho de tabela e toasts, sem índices|
|pg_indexes_size|(nome)Tamanho dos índices de uma tabela|
|pg_tablespace_size|(nome)Tamanho de um tablespace|
|pg_total_relation_size|(nome)Tamanho total, incluindo tabela, índices e toasts|
|pg_size_pretty|(bigint)Converte de bytes para formato legível (MB, GB, TB etc)|

A seguinte consulta mostra os tamanhos da tabela, índices, tabela e toasts, além de tamanho total para todas as tabelas ordenadas pelo tamanho total  decrescente, destacando no início as maiores tabelas:

~~~sql
curso=\# SELECT schemaname || '.' || relname as tabela,
            pg_size_pretty(pg_relation_size(schemaname || '.' || relname)) as tam_tabela,
            pg_size_pretty(pg_table_size(schemaname || '.' || relname)) as tam_tabela_toast,
            pg_size_pretty(pg_indexes_size(schemaname || '.' || relname)) as tam_indices,
            pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) as tam_total_tabela,
        FROM pg_stat_user_tables
        ORDER BY pg_total_relation_size(schemaname || '.' || relname) DESC;
~~~

## CONFIGURANDO O LOG PARA MONITORAMENTO

O log do PostgreSQL é bastante flexível e possui uma série de recursos configuráveis. Podemos registrar:
- Queries
- Arquivos temporários
- Conexões/desconexões
- Checkpoints
- Espera por Locks
- Deadlocks
- entre outros

Parâmetros que devem ser considerados:

1. log_destination

Indica onde a log será gerada. Por padrão para a saída de erro stderr. Para armazenar os arquivos com logging_collector, esse valor deve ser stderr ou csvlog. Com o valor syslog, podemos também usar o recurso de log do Sistema Operacional, porém alguns tipos de mensagens não são registrados nesse modo

2. log_line_prefix

É o formato de um prefixo para cada linha a ser registrada. Existem diversas informações que podem ser adicionadas a esse prefixo, como a hora (%t), o usuário (%u) e o id do processo (%p). Porém, para usarmos ferramentas de relatórios de queries, como pgFouine e pgBadger, devemos utilizar alguns padrões nesse prefixo.

~~~text
log_line_prefix = ‘%t [%p]: [%l-1] user=%u,db=%d ‘
~~~

3. log_filename

Define o formato do nome de arquivo. O valor padrão inclui data e hora da criação do arquivo. Esse formato, além de identificar o arquivo no tempo, impede que este seja sobrescrito.

~~~text
log_filename = ‘postgresql-%Y-%m-%d_%H%M%S.log’

irá resultar no arquivo: postgresql-2014-01-22_000000.log
~~~

4. log_rotation_age

Define o intervalo de tempo no qual o arquivo de log será rotacionado. __O padrão é de um dia__.

5. log_rotation_size

Define o tamanho máximo a partir do qual o arquivo de log será rotacionado.

6. log_statement

Indica quais tipos de queries devem ser registradas, admitindo os seguintes valores:
- none: valor padrão – não registra nada.
- ddl: comandos DDL, de criação/alteração/exclusão de objetos do banco.
- mod: comandos DDL mais qualquer comando que modifique dados.
- all: registra todas as queries.

7. log_min_duration_statement

Indica um valor em milissegundos acima do qual serão registradas todas as queries cuja duração for maior do que tal valor. __O valor padrão é -1__, indicando que nada deve ser registrado. __O valor 0__ registra todas as queries independentemente do tempo de duração de cada uma delas. 
Toda query registrada terá sua duração também informada no log.

## GERAÇÃO DE RELATÓRIOS COM BASE NO LOG – PGBADGER

O pgBadger é um analisador de logs do PostgreSQL, escrito em perl e disponibilizado como open source, fazendo o parser dos arquivos de log e gerando relatórios html. (_Mais rápido, mais atualizado, mais funcionalidades que o pgFouine_)

Rankings de Queries:
- Queries mais lentas
- Queries mais tomaram tempo total (duração x nr execuções)
- Queries mais frequentes
- Query normalizada e exemplos
- Tempo Total, número de Execuções e Tempo Médio

> A seção mais útil é a que mostra as queries que tomaram mais tempo no total de suas execuções – seção “Queries that took up most time (N)” –, já que ao  analisar uma query não devemos considerar somente seu tempo de execução, mas __também a quantidade de vezes em que essa é executada__.

Para usar o pgBadger, é necessário configurar as opções de log do PostgreSQL como vimos anteriormente, para que as linhas nos arquivos tenham um determinado prefixo necessário para o processamento correto dos dados.

Instalação:

~~~bash
$ cd /usr/local/src/
$ sudo tar xzf pgbadger-11.4.tar.gz
$ cd pgbadger-11.4/
$ sudo perl Makefile.PL
$ make
$ sudo make install
~~~

Com o usuário postgres, basta executar o pgBadger passando os arquivos de log que deseja processar como parâmetro:

~~~bash
$ pgbadger -f stderr /db/data/log/*.log -o relatorio.html
~~~

Esse exemplo vai ler todos os arquivos com extensão .log no diretório log e vai gerar um arquivo de saída chamado relatorio.html. Você pode informar um arquivo de log, uma lista de arquivos ou até um arquivo compactado contendo um ou mais arquivos de log.

## EXTENSÃO PG_STAT_STATEMENTS

Extensão do PostgreSQL para capturar queries em tempo real. Cria uma visão pg_stat_ staments contendo:
 - queries mais executadas
 - Número de execuções
 - Tempo total
 - Quantidade de registros envolvidos
 - Volume de dados (através de números de blocos processados)

Essa extensão cria uma visão que contém as queries mais executadas e dados dessas queries, como o número de execuções, o tempo total, a quantidade de registros envolvidos e volume de dados através de números de blocos processados.

Essa extensão precisa de algumas configurações no postgresql.conf, tais como configurar o carregamento de uma biblioteca, demandando um restart do banco para começar a funcionar

Outro parâmetro que precisa ser configurado é a __quantidade de queries__ que deve ser mantida pela view, através de __pg_stat_statements.max__, cujo valor padrão é 1000. O parâmetro __pg_stat_statements.track__ indica se deve-se registrar todas as queries (all) e não considerar queries internas à funções (top) ou nenhum registro (none).

Exemplo de configuração no postgresql.conf:

~~~text
shared_preload_libraries = ‘pg_stat_statements’
pg_stat_statements.track = all
pg_stat_statements.max = 5000
~~~

Depois de reiniciar o PostgreSQL e criar a extensão em alguma base, a view já pode ser acessada, conforme o exemplo a seguir.

~~~sql 
postgres=\# SELECT query, calls, total_exec_time, shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit
            FROM pg_stat_statements
            ORDER BY total_exec_time
            DESC LIMIT 10;
~~~

## PGBENCH

O pgbench é uma extensão do PostgreSQL usada para fazer testes de benchmark e avaliar o desempenho dos recursos e do banco.

O teste do pgBench é uma transação simples, com __updates, inserts e selects executadas diversas vezes__, possivelmente simulando diversos clientes e conexões, e no final fornece a taxa de transações em TPS – transações por segundo.

O pgBench possui duas operações básicas:
- Criar e popular uma base
- Executar queries contra essa base e medir o número de transações

## ROLES PARA MONITORAMENTO

As Default Roles são papéis especiais embutidos no SGBD utilizados para funções especificas, como monitoramento. Por exemplo, a nova role pg_monitor permite fornecer acesso a configurações, views e funções para monitoramento de recursos.

## RESUMO

Monitorando pelo Sistema Operacional:
1. Usar o top para uma visão geral dos processos. Além das informações gerais, a coluna S (status), com valor D, deve ser observada, além do iowait (wa).
2. A vmstat é uma excelente ferramenta para observar o comportamento das métricas, processos esperando disco (b), comportamento da memória e ocorrências de swap que devem ser monitoradas.
3. A iostat exibe as estatísticas por device. Analisar o tempo para atendimento de requisições de I/O (await) e a saturação do disco ou canal (%util).

Monitorando pelo PostgreSQL:
1. Torne o pg_activity sua ferramenta padrão. Com o tempo, você conhecerá quais são as queries normais e as problemáticas que merecem atenção, detectará rapidamente processos bloqueados ou com transações muito longas. Atenção às colunas W (waiting) e IOW (aguardando disco), e aos tempos de execução: amarelo > 0,5 e vermelho > 1s.
2. O pgAdmin pode ajudar a detectar quem está bloqueando os outros processos mais facilmente.
3. Monitore seus PostgreSQL com o Nagios, Cacti e Zabbix, ou outra ferramenta de alertas, dados históricos e gráficos. Elas são a base para atendimento rápido e planejamento do ambiente.
4. Analise as visões estatísticas do catálogo para monitorar a atividade do banco, crie seus scripts para avaliar situações rotineiras.
5. Use o pgBadger automatizado para gerar relatórios diários do uso do banco e top queries. Priorize a melhoria das queries em “Time consuming queries”.
6. Use a extensão pg_stat_statements para ver as top queries em tempo real.
