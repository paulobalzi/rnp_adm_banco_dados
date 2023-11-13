# Módulo 6 - Manutenção do banco de dados

tags
> Vacuum; Autovacuum; Analyze; Amostra Estatística; Reindex; Bloated Index; Cluster e Dead Tuples

## VACUUM

o PostgreSQL garante o Isolamento entre as transações através do __MVCC__ (Multi-Version Concurrency Control). Esse mecanismo cria versões dos registros entre as transações, cuja origem são operações de __DELETE, UPDATE e ROLLBACK__. Essas versões, quando não são mais necessárias a nenhuma transação, são chamadas __dead tuples__, e limpá-las é a função do VACUUM.

O vacuum somente __marca as áreas como livres__ atualizando informações no __Free Space Map__ (FSM), liberando espaço na tabela ou índice __para uso futuro__. Essa operação __não__ devolverá espaço para o Sistema Operacional, a não ser que as páginas ao final da tabela fiquem vazias.

### VACCUM FULL

O Vaccum Full é como uma __defragmentação__, deslocando as páginas de dados vazias e __liberando o espaço para o Sistema Operacional__. É uma operação custosa e precisa de um lock exclusivo na tabela. `deve-se evitar o vaccum full`.

~~~text
uso: sql VACCUM ou vaccumdb
~~~

Opções do comando Vaccum:
- __FULL__: vaccum full
- __verbose__: exibe uma saída detalhada
- __analyza__: executa também atualização das estatísticas

~~~sql
curso=# VACUUM;

$ vacuumdb -d curso
~~~

||Comando SQL|Utilitário|
|--|--|--
|Executar um Vacuum Full|VACUUM FULL;|vacuumdb -f -d curso|
|Vacuum com Saída Detalhada|VACUUM VERBOSE;|vacuumdb -v -d curso|
|Com Atualização de Estatísticas|VACUUM ANALYZE;|vacuumdb -z -d curso|
|Todas as Bases do Servidor (possível apenas pelo utilitário)||vacuumdb –a|
|Uma Tabela Específica|VACUUM grupos;|vacuumdb -t grupos -d curso|

o vacuum com atualização de estatísticas em todas as bases do servido

~~~bash
$ vaccumdb -avz
// ou
curso\=# vaccum analyze verbose
~~~

Executar um vacuum com diversos processos paralelamente, operando em várias tabelas simultaneamente. Usar o parâmetro -j e informar o número de processos paralelos.

~~~bash
$ vacuumdb –j 8 curso
~~~

Executar vacuum com paralelismo sobre os índices de uma tabela

~~~sql
curso=\# VACUUM (PARALLEL 4) auditoria;

consolidado=\# VACUUM (PARALLEL 4, VERBOSE) auditoria;
~~~

## ANALYZE

Executa apenas o trabalho da coleta das estatísticas sem executar o vacuum.

Comando que atualizará as estatísticas de todas as tabelas da base

~~~sql
curso=\# ANALYZE VERBOSE;
-- para uma tabela específica
curso =\# ANALYZE VERBOSE times;
-- para uma coluna ou lista de colunas
curso=\# ANALYZE VERBOSE times(nome);
~~~

O Analyze coleta estatísticas sobre o conteúdo da tabela e __armazena na pg_statistic__. Essas informações são usadas pelo __Otimizador__ para escolher os __melhores Planos de Execução__ para uma query. Essas estatísticas incluem os valores mais frequentes, a frequência desses valores, percentual de valores nulos.

> Sempre que houver uma grande carga de dados, seja atualização ou inserção, ou mesmo exclusão, é importante executar uma atualização das estatísticas

Para não deixar o banco indisponível, é possível realizar as estatísticas em fases

~~~bash
$ vacuumdb --analyze-in-stages
~~~

## AMOSTRA ESTATÍSTICA

A análise estatística é feita sobre uma amostra dos dados de cada tabela. O tamanho dessa amostra é determinado pelo parâmetro __default_statistics_target__. `O valor padrão é 100`.

É possível aumentar o valor da amostra analisada, mas isso __aumentará__ também o tempo e o espaço consumido pela coleta de estatísticas.

Em vez de  alterar o postgresql.conf globalmente, pode-se __alterar esse parâmetro por coluna e por tabela__. Assim, se estiver analisando uma query em particular, ou se existirem tabelas grandes muito utilizadas em um sistema, é uma boa ideia incrementá-lo para as __colunas muito utilizadas__ em cláusulas WHERE, ORDER BY e GROUP BY.

Exemplo:
- aumentar a amostra da coluna bid para 1000
~~~sql
bench=# ALTER TABLE pgbench_accounts ALTER COLUMN bid SET STATISTICS 1000;
~~~

## ESTATÍSTICAS ESTENDIDAS

Um tema mais avançado são as __estatísticas estendidas__ e o __conceito de correlação__. O otimizador analisa as estatísticas de ocorrências de valores de cada coluna __isoladamente__. Isso pode levar a ser escolhido um plano de execução não ótimo, quando há __relação de dependência entre as colunas__. É possível instruir o Otimizador da existência destas correlações com o comando
CREATE STATISTICS. 

~~~sql
Curso=# CREATE STATISTICS stats_localizacao (dependencies) ON cidade, estado FROM enderecos;
~~~

## AUTOVACUUM

- procedimento passou a ser executado de forma automática
- O autovacuum sempre executa o Analyze

Execução do autovaccum
1. processo inicial chamado Autovacuum Launcher
2. número pré-determinado de processos auxiliares chamados de Autovacuum Workers
3. A cada intervalo de tempo configurado, o Laucher chama um Worker (verificar uma base de dados)
4. O Worker verifica cada tabela e executa o vacum (acionando o analyze se necessário)
5. Se existem mais bases que o número configurado de Workers, as bases serão analisadas em sequência

## CONFIGURANDO O AUTOVACUUM

- parâmetro track_counts = true (valor padrão)
- autovacuum_max_workers = 3 (padrão) -> número de processos workers

Quando um Worker determinar que uma tabela precisa passar por um vacuum, ele executará até um __limite de custo__, medido em __operações de I/O__. Depois de atingir esse limite de operações, ele __“dormirá”__ por um determinado tempo antes de continuar o trabalho.

- autovacuum_vacuum_cost_limit = -1 (padrão), significando que ele usará o valor de vacuum_cost_limit, que por padrão é 200.
- autovacuum_vacuum_cost_delay = 20 ms (padrão), o tempo em que o Worker dorme quando atinge o limite de custo

> Sugestão: _autovacuum_cost_delay_ = 100ms, caso o autovacuum esteja atrapalhando o uso do banco, ou aumnetar __autovacuum_naptime__ = 1 (padrão), que é o intervalo que o __Launcher__ executa os __workers__ para cada base. Caso seja necessário baixar a frequência do autovacuum, __aumente o naptime com moderação__.

### CONFIGURAÇÕES POR TABELA

Se uma tabela precisar de configurações especiais de vacuum, como no caso de uma __tabela de log__, que é __muito escrita__, mas __não consultada__, pode-se __desabilitar o autovacuum__ nessa tabela e executá-lo manualmente quando necessário.

Desabilitar o autovacuum em uma determinada tabela:

~~~sql
bench=# ALTER TABLE contas SET (autovacuum_enabled = false);
~~~

Permitir que mais trabalho seja feito pelo autovacuum em uma tabela:

~~~sql
bench=# ALTER TABLE contas SET (autovacuum_vacuum_cost_limit = 1000);
~~~

### PROBLEMAS COM O AUTOVACUUM

Se o vacuum está demorando, é justamente porque ele tem muito trabalho a ser feito e está sendo pouco executado. `A solução não é parar de executá-lo, mas sim executá-lo com maior frequência`

### AUTOVACUUM EXECUTA MESMO DESLIGADO

O autovacuum pode rodar, __mesmo se desabilitado no postgresql.conf__, para evitar o problema conhecido como __Transaction ID Wraparound__, que é quando o contador de transações do PostgreSQL está chegando ao limite. Esse problema pode gerar perda de dados.

> Verifique se o parâmetro __maintenance_work_mem__ está muito __baixo__ comparado ao __tamanho das tabelas__ que precisam passar pelo vacuum. Lembre-se de que o vacuum/autovacuum pode alocar __no máximo maintenance_work_mem__ de memória para as operações. Ao atingir esse valor, o processo para e começa novamente.

> se há um __grande número de bases de dados no servidor__. Nesse caso, como uma base não pode ficar sem passar pelo autovacuum por mais do que o definido em __autovacuum_naptime__, se existirem 30 bases, um worker vai disparar no mínimo a cada 2s. Se há muitas bases, aumente o autovacuum_naptime.

### OUT OF MEMORY

Ao aumentar o parâmetro __maintenance_work_mem__, é preciso levar em consideração que __cada worker__ pode alocar até essa quantidade de memória para sua respectiva __execução__. Assim, considere __o número de workers e o tamanho da RAM disponível__ quando for atribuir o valor de maintenance_work_mem.

### POUCA FREQUÊNCIA

Em grandes __servidores__ com __alta capacidade de processamento__ e de I/O, com sistemas igualmente grandes, o parâmetro __autovacuum_vacuum_cost_delay__ deve ter seu __valor padrão__ de 20ms __baixado para um intervalo menor__, de modo a permitir que o autovacuum dê conta de executar sua tarefa.

### FAZENDO MUITO I/O

Se o autovacuum parecer estar __consumindo muito recurso__, ocupando muita banda disponível de I/O, pode-se aumentar __autovacuum_vacuum_cost_delay__ para 100ms ou 200ms, buscando não atrapalhar as operações normais do banco.

### TRANSAÇÕES ETERNAS

Transações pode ficar abertas por dias. O vacuum __não poderá eliminar as dead tuples__ que ainda devem ser visíveis até essas __transações terminarem__, prejudicando assim sua operação. Verifique a idade das transações na __view pg_stat_activity__.

> Nota: apesar do vacuum existir essencialmente para eliminar dead tuples, gerada por deletes e updates, a __partir da versão 13__ poderá ser visto o autovacuum executando em tabelas que __sofrem somente inserção__, para atender situações especiais relacionadas à questão de __“transaction ID wraparound”__ e para ajudar na operação de __index-only scans__.

### REINDEX

O comando REINDEX pode ser __usado para reconstruir um índice__. Você pode desejar executar essa operação se suspeitar que um índice esteja __corrompido__, __“inchado”__ ou, ainda, se foi alterada alguma configuração de armazenamento do índice, como __FILLFACTOR__, e que não tenha ainda sido aplicada. O REINDEX faz o mesmo que um DROP seguido de um CREATE INDEX.

É possível também usar o REINDEX quando um índice que estava sendo criado com a opção __CONCURRENTLY__ __falhou__ no meio da operação.

As opções do comando REINDEX são:
- Reindexar um índice específico:
~~~sql
curso=\# REINDEX INDEX public.pgbench_branches_pkey;
~~~

- Reindexar todos os índices de uma tabela:
~~~sql
curso=\# REINDEX TABLE public.pgbench_branches;
~~~

- Reindexar todos os índices da base de dados:
~~~sql
curso=\# REINDEX DATABASE curso;
~~~

- Uma alternativa é a reconstrução dos índices do catálogo.
~~~sql
curso=\# REINDEX SYSTEM curso;
~~~

> Para __tabelas e índices__, deve-se informar o __esquema__, e para a __base__ é obrigatório informar o __nome da base e estar conectado a ela__

- Reindexação concorrente de um índice
~~~sql
curso=\# REINDEX TABLE CONCURRENTLY curso;
~~~

### “BLOATED INDEXES” (inchado)

Devemos comparar o tamanho do índice com o tamanho da tabela.

A seguinte query mostra o tamanho dos índices, de suas tabelas e a proporção entre eles.

~~~sql
bench=\# select nspname as schema, relname as index,
            round(100*pg_relation_size(indexrelid) / pg_relation_size(indrelid) / 100) as index_ratio,
            pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
            pg_size_pretty(pg_relation_size(indrelid)) as table_size
        from pg_index i
        left join pg_class C on (C.oid=i.indexrelid)
        left join pg_namespace N on (N.oid=C.indexrelid)
        where nspname not in ('pg_catalog'.'information_schema', 'pg_toast')
            and C.relkind = 'i'
            and pg_relation_size(indrelid) > 0;
~~~

### CLUSTER

O recurso de CLUSTER é uma possibilidade para __melhorar o desempenho de acesso a dados lidos de forma sequencial__.

~~~sql
\# cluster pgbench_accounts using idx_accounts_bid;
~~~

Essa é uma operação que usa __muito espaço em disco__, já que ela cria uma nova cópia da tabela inteira e seus índices de forma ordenada, e depois apaga a original. Em alguns casos, dependendo do método de ordenação escolhido, pode ser necessário alocar espaço equivalente a duas vezes o tamanho da tabela, mais seus índices. Essa operação usa bloqueios agressivos, exigindo um lock exclusivo na tabela toda.

Basicamente o `cluster`, organiza os registros da tabela. Exemplo

Ordem física dos registros
~~~text
+---------+---------+
|   100   |     54  |
+---------+---------+
|   34    |     6   |
+---------+---------+
|   57    |     19  |
+---------+---------+
|   2     |     45  |
+---------+---------+
|   87    |     65  |
+---------+---------+
~~~

Ordem física após o cluster
~~~text
+---------+---------+
|   2     |     54  |
+---------+---------+
|   6     |     57  |
+---------+---------+
|   19    |     65  |
+---------+---------+
|   34    |     89  |
+---------+---------+
|   45    |     100 |
+---------+---------+
~~~

> é uma operação que deve ser __reexecutada frequentemente__ para manter os novos dados também ordenados

executar o CLUSTER em todas as tabelas já clusterizadas da base,
~~~sql
# CLUSTER VERBOSE;
~~~

> em todas as operações de manutenção mostradas nesta sessão (VACUUM, REINDEX e CLUSTER), o parâmetro __maintenance_work_mem__ deve ser ajustado adequadamente.

## ATUALIZAÇÃO DE VERSÃO DO POSTGRESQL

### MINOR VERSION

atualização de __minor versions__( 13.0 para a 13.1), não há alteração do formato de armazenamento dos dados. Assim, a atualização pode ser feita apenas substituindo os executáveis do PostgreSQL sem qualquer alteração nos dados.

1. Copiando os arquivos da nova versão na instalação existente

~~~bash
$ pg_ctl stop -mf
$ rm -Rf /usr/local/pgsql
$ cp -r /diretorio_compilada_nova_versao/*  /usr/local/pgsql
$ pg_ctl start
~~~

2. Instalando/compilando uma nova versão
~~~bash
$ sudo tar -xvf postgresql-13.1.tar.gz
$ cd postgresql-13.1/
$ ./configure --prefix=/usr/local/pgsql-13.1
$ make
$ sudo make install

pg_ctl stop –mf
rm pgsql
ln -s /usr/local/pgsql-13.1 pgsql (link simbolico para a nova versão)
pg_ctl start
~~~

### MAJOR VERSION

Atualizações de __major versions__ (13.x para 14.x), podem trazer modificações no formato de armazenamento dos dados ou no catálogo de sistema. Nesse caso será necessário __fazer um dump__ de todos os dados e __restaurá-los__ na nova versão.

1. Substituição simples:
    - Fazer o dump de todo o servidor para um arquivo.
    - Desligar o PostgreSQL.
    - Apagar o diretório dos executáveis da versão antiga.
    - Instalar a nova versão no mesmo diretório.
    - Ligar a nova versão do PostgreSQL.
    - Restaurar o dump completo do servidor.

2. Duas instâncias em paralelo:
    - Instalar a nova versão em novos diretórios (executáveis e dados).
    - Configurar a nova versão em uma porta TCP diferente.
    - Ligar a nova versão do PostgreSQL.
    - Fazer o dump da versão antiga e o restore na versão nova ao mesmo tempo.
    - Desligar o PostgreSQL antigo.
    - Configurar a nova versão para a porta TCP original.

3. Novo servidor:
    - Instalar a nova versão do PostgreSQL em um novo servidor.
    - Fazer o dump da versão antiga e transferir o arquivo para o novo servidor ou fazer o dump  da versão antiga e o restore na versão nova ao mesmo tempo.
    - Direcionar a aplicação para o novo servidor.
    - Desligar o servidor antigo.

Uma alternativa para o dump/restore na atualização de major versions é o utilitário __pg_upgrade__:
- atualiza a versão do PostgreSQL in-loco, ou seja, atualizando os arquivos de dados diretamente.
- modo __“cópia”__ ou em modo __“link”__, ambos mais rápidos do que o dump/restore tradicional

## RESUMO

__Vacuum:__

- Mantenha o Autovacuum sempre habilitado.
- Agende um Vacuum uma vez por noite.
- Não use o Vacuum Full, a não ser em situação especial.
- Tabelas que estejam sofrendo muito autovacuum devem ter o parâmetro autovacuum_ vacuum_cost_limit aumentado.

__Estatísticas:__

- O Auto-Analyze é executado junto com o Autovacuum; por isso, mantenha-o habilitado.
- Na execução noturna do Vacuum, adicione a opção Analyze.
- Considere aumentar o tamanho da amostra estatística das principais tabelas.

__Problemas com Autovacuum:__

- Se existirem muitas bases, aumente autovacuum_naptime.
- Ao definir maintenance_work_mem, considere o número de workers e o tamanho da RAM.
- Em servidores de alto poder de processamento, pode-se baixar autovacuum_vacuum_cost_delay.