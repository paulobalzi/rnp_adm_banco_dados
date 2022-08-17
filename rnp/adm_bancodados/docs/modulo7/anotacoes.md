# Modulo 7 - Desempenho – Tópicos sobre aplicação

__tasg__
> Tuning; Bloqueios; Deadlock; Índices; Índices Compostos; Índices Parciais; Índices com Expressões; Operadores de Classes; Planos de Execução; Index Scan e Seq Scan.

## Introdução ao tuning

tuning é um conhecimento empírico que deve ser testado em cada situação. 

> Uma das poucas afirmações que podemos fazer nesta área sem gerar qualquer controvérsia é a de que o banco de dados deve ser instalado em um servidor dedicado.

__ciclo de Tuning__

~~~text

infraestrutura          --------------
(hardware e software)                |
   /\                                |
   |                                \/
   |                               Configuração
   |                               PostgreSQL e SO
Aplicação                             |
(Queries) <----------------------------
~~~

Situações mais frequentemente:

1. modo como a aplicação usa o banco, na qualidade de suas queries, da eficiência do modelo, na quantidade de dados retornados ou ainda na quantidade de dados processados de forma intermediária. 
__Solução: criação de índices__
2. Depois de analisada a aplicação e o uso que se está fazendo do banco, pode ser necessário analisar a configuração do PostgreSQL e do Sistema Operacional.
    - analisar se a memória para ordenação é suficiente
    - o percentual de acerto no shared buffer
    - os parâmetros de custo do Otimizador
    - se o vacuum e estatísticas estão sendo realizados com a frequência necessária
3. Verificamos se a memória está corretamente dimensionada, a velocidade e organização dos discos, o poder de processamento, o filesystem e o uso de mais servidores com replicação. __Ou seja, olha-se para infraestrutura de hardware e software.__

__Lentidão generalizada__

> Um problema comum é o excesso de conexões com o banco, resultando em excesso de processos

Para manipular milhares de conexões, você deve usar um __software de pooling__ – ou agregador de conexões.
Devemos verificar as configurações de pool. Por vezes o número mínimo de conexões, o máximo e o incremento são  superdimensionados. 
__O mínimo normalmente não é o grande vilão__, pois é alocado quando a aplicação entra no ar. __O incremento é o número de conexões a serem criadas quando faltarem conexões livres__. Ou seja, quando todas as conexões existentes estiverem alocadas, não será criada apenas uma conexão adicional, mas sim a quantidade de conexões indicada no parâmetro relacionado ao incremento.
Um __número muito alto__ para o __máximo de conexões__ que podem ser criadas pode comprometer a performance do sistema como um todo.

## Agregador de Conexões (Connection Pool)

Um software de pool para PostgreSQL é o __pgbouncer__. Ele é open source, de fácil instalação, leve e absurdamente eficiente.

### Instalação a partir dos fontes

~~~bash
sudo yum install libevent-devel openssl-devel
cd /usr/local/src/
sudo wget https://www.pgbouncer.org/downloads/files/1.15.0/pgbouncer-1.15.0.tar.gz
sudo tar -xvf pgbouncer-1.15.0.tar.gz
cd pgbouncer-1.15.0/
./configure --prefix=/usr/local
make
sudo make install
~~~

O seguinte é tratar da sua configuração:

~~~bash
sudo mkdir /db/pgbouncer
sudo chown postgres /db/pgbouncer/

(com o usuário postgres)

$ vi /db/pgbouncer/pgbouncer.ini
[databases]
curso = host=127.0.0.1 dbname=curso

[pgbouncer]
pool_mode = transaction
listen_port = 6543
listen_addr = 127.0.0.1
auth_type = md5
auth_file = /db/pgbouncer/users.txt
logfile = /db/pgbouncer/pgbouncer.log
pidfile = /db/pgbouncer/pgbouncer.pid
admin_users = postgres
stats_users = stat_collector
~~~

Executando pgbouncer
~~~bash
pgbouncer -d /db/pgbouncer/pgbouncer.ini
~~~

Use o psql para conectar na porta do pool
~~~bash
psql -p 6543 -d curso
~~~

> Com o pgbouncer, é possível atender a mil ou mais conexões de clientes através de um número significativamente menor de conexões diretas com o banco. Isso poderá trazer ganhos de desempenho notáveis.

__Importante__
~~~text
como nada é perfeito, o pgbouncer possui um contratempo. Como ele precisa autenticar os usuários, é preciso indicar um arquivo
com usuários e senhas válidos. Até a versão 8.3, o próprio PostgreSQL mantinha tal arquivo, que era utilizado pelo pgbouncer. A
partir do PostgreSQL 9.0, esse arquivo foi descontinuado e atualmente é necessário gerá-lo “manualmente”. Não é complicado gerar
o conteúdo para o arquivo através de comandos SQL lendo o catálogo, inclusive protegendo as respectivas senhas de forma a que não 
fiquem expostas (são encriptadas).
~~~

## Processos com queries lentas ou muito executadas

### Volume de dados manipulados

- verificar a quantidade de registros retornados da query
- uuário vai consultar os dados na primeira ou segunda tela para logo em seguida passar para outra atividade, descartando o grande volume de dados excedente que foi processado e trafegado na rede
- query deve ser reescrita para ser mais restritiva.
    - incluindo mais condições na cláusula WHERE da query
- fazer uso das cláusulas OFFSET e LIMIT, resultando no tráfego apenas dos dados que realmente serão sendo exibidos para o usuário.
~~~sql
curso=# SELECT generate_series(1,30) OFFSET 10 LIMIT 10;
~~~
- se for uma query complexa, com diversos joins, subqueries e condições, é possível que o resultado final seja pequeno, mas com milhões de registros sendo comparados nas junções de tabelas.
    - solução: tentar tornar a query mais restritiva, diminua a quantidade de registros a serem ordenados e comparados
- quantidade e os tipos de colunas podem influenciar o desempenho de uma query
    - é reescrever a query e adaptar a aplicação para retornar um número mais enxuto de colunas

> __Importante__: não é recomendável o armazenamento de arquivos no banco de dados.

> Apesar da vantagem da integridade referencial, bancos de dados não são pensados, configurados e previamente ajustados para trafegar e armazenar __grandes unidades de dados armazenados em arquivos__. Tipicamente, bancos são voltados para sistemas __transacionais, OLTP, para manipular registros pequenos, de um tamanho médio empiricamente levantado próximo de 8kB__.

### Relatórios e Integrações

Um erro muito comum é __criar relatórios para usuários__, às vezes fechamentos mensais ou até anuais, e __disponibilizar__ um __link no sistema__ para o usuário gerá-lo a qualquer instante. 

> Relatórios devem ser pré-processados, agendados para executar à noite e de madrugada, e apresentar o resultado para o usuário  pela manhã.

Se ainda assim existem consultas pesadas que precisem ser executadas a qualquer momento, ou relatórios que não podem ter seus horários de execução restringidos, considere usar Replicação para criar servidores slaves, onde essas consultas poderão ser executadas sem prejudicar as operações normais do sistema

### Visões materializadas

Para aqueles casos de queries muito pesadas citadas anteriormente, como os relatórios, em que não se é possível restringir os dados, uma alternativa quando a informação não precisa ser a mais atualizada pode ser o uso de __visões materializadas__

As visões materializadas são criadas de forma similar a uma visão tradicional, __baseada em uma query__, porém elas __persistem os dados resultantes__. Podemos atualizar os dados da visão com um comando simples de __refresh__, e é __possível criar índices__ em uma visão materializada.

Criando uma visão materializada
~~~sql
bench=# CREATE MATERIALIZED VIEW mv_saldopositivo
        AS SELECT aid,a.bid,abalance,tid,tbalance
        FROM pgbench_accounts a 
        JOIN pgbench_tellers t ON a.bid = t.bid
        WHERE abalance > 0;
-- atualizar os dados
bench=# REFRESH MATERIALIZED VIEW mv_saldopositivo;
~~~

> o refresh causa o bloqueio das visões materializadas. Usando-se a opção CONCURRENTLY, é possível permitir que a visão seja acessada para leitura enquanto é atualizada. Esta atualização também pode causar a geração de grande quantidade de arquivos de WAL.

### Colunas pré-calculadas

> Generated Columns: colunas calculadas baseadas no valor de outras colunas do mesmo registro.

Ex: coluna calculada chamada valor total que seria já o resultado dos três campos, persistidos
~~~sql
CREATE TABLE notafiscal ( … ,
        valor numeric,
        desconto numeric,
        perc_imposto numeric,
        total numeric GENERATED ALWAYS AS (valor-desconto+(valor-desconto)*perc_imposto) STORED)
~~~

### Desempenho de escrita

Em casos de problemas de desempenho para escrita de dados, algumas dicas são:

Usar COPY ao invés de INSERT.
~~~sql
curso=\# COPY cidades FROM ‘/curso/cidades.txt’;
~~~

Usar transações agrupando diversos comandos de escrita.
~~~sql
curso=\# BEGIN;
curso=\# INSERT INTO cidades(nome) VALUES(‘São Paulo’);
curso=\# INSERT INTO cidades(nome) VALUES(‘Rio de Janeiro’);
...
curso=\# INSERT INTO cidades(nome) VALUES(‘Curitiba’);
curso=\# COMMIT;
~~~

Usar INSERT de múltiplos registros.
~~~sql
curso=\# INSERT INTO cidades(nome) VALUES(‘Brasilia’),(‘Belo Horizonte’),...,(‘Porto Alegre’);
~~~

Desligar triggers temporariamente.
~~~sql
curso=\# ALTER TABLE jogos DISABLE TRIGGER ALL;
~~~

Apagar índices, carregar dados e recriar índices. Usar tabelas UNLOGGED, carregar os dados e mudar para LOGGED.
~~~sql
curso=\# CREATE UNLOGGED TABLE historico(...);
-- carga dos dados
curso=# ALTER TABLE TABLE historico SET LOGGED;
~~~

> No momento de transformação de uma tabela unlogged em logged, uma grande quantidade de WAL é gerada e ocorre um lock exclusivo na tabela.

### Bloqueios

O PostgreSQL controla a concorrência e __garante o Isolamento__ (o “I” das propriedades ACID) com um mecanismo chamado __Multi-Version Concurrency Control (MVCC)__. Devido ao MVCC, problemas de bloqueios – ou locks – no PostgreSQL são pequenos. Esse mecanismo __basicamente cria versões dos registros que podem estar sendo manipulados simultaneamente por transações diferentes__, cada uma tendo uma visão dos dados, chamada __snapshot__.

> no PostgreSQL uma __leitura nunca bloqueia uma escrita__ e uma __escrita nunca bloqueia uma leitura__.

> __locks não são um problema__. Problema é a transação não liberar o lock!

A solução é sempre fazer __a transação o mais curta possível__. Deve ser encontrado o motivo pelo qual a transação está demorando, providenciando a reescrita desta se necessário.

Podemos localizar os locks através do __pg_activity, do pgAdmin e da tabela do catálogo pg_locks__. É possível também rastrear queries envolvidas em longas esperas por locks ligando o __parâmetro log_lock_waits__

~~~text
log_lock_waits = on
~~~

Estado do processo em __IDLE IN TRANSACTION__. Processos nesse estado por longo tempo são o problema a ser resolvido, mas é um comportamento que varia de aplicação para aplicação

Além dos problemas com locks relacionados a escritas de dados como UPDATE e DELETE, há as situações menos comuns e mais fáceis de identificar envolvendo DDL. Comandos como ALTER TABLE e CREATE INDEX também bloquearão escritas de dados.

Outra situação que pode ocorrer são bloqueios gerados por causa do __autovacuum__.

Se uma tabela passar por uma grande alteração de dados, ela é grande candidata a sofrer autovacuum, potencialmente gerando problemas de performance.

__deadlock__. Processo obteve um registro e está esperando o do outro ser liberado, o que nunca acontecerá.

O PostgreSQL detecta deadlocks, verificando a ocorrência deles em um intervalo de tempo definido pelo parâmetro __deadlock_timeout__, por padrão a cada 1 segundo. Se um deadlock for identificado, o o PostgreSQL escolherá um dos processos como “vítima” e a respectiva operação será abortada

Caso estejam ocorrendo muitos locks e deadlocks, seu valor (__deadlock_timeout__) pode ser baixado para ajudar na depuração do problema, mas isso tem um preço, já que o algoritmo de busca por deadlocks é relativamente custoso.

### Tuning de queries

Para entender como o banco está processando a consulta, devemos ver o Plano de Execução escolhido pelo SGBD para resolver aquela query. Para fazermos isso, usamos o comando __EXPLAIN__.

~~~sql
bench=\# EXPLAIN
    select * from pgbench_accounts a
    inner join pgbench_branches b on a.bid =b.bid
    inner join pgbench_tellers t on t.bid =b.bid
    where  a.bid=56
~~~

O EXPLAIN nos mostra o Plano de Execução da query e os custos estimados. Cada linha no plano com um __->__ indica uma operação. As demais são informações adicionais. O primeiro nó indica o custo total da query

~~~text
Sort (cost=0.00..296417.62 rows=1013330 width=813)

cost=0.00..296417.62 
    - Custo total estimado da query
    - Custo inicial estimado para retornar o primeiro registro
rows=1013330 
    - Número de registros estimados
width=813
    - Tamanho estimado de cada registro
~~~

Todas as informações do EXPLAIN sem parâmetros são estimativas. Para obter o tempo real, ele deve executar a query de fato, através do comando __EXPLAIN ANALYZE__:

~~~sql
bench=\# EXPLAIN (ANALYZE)
    select * from pgbench_accounts a
    inner join pgbench_branches b on a.bid =b.bid
    inner join pgbench_tellers t on t.bid =b.bid
    where  a.bid=56
~~~

Podemos ver informações de tempo. No primeiro nó temos o tempo de execução, aproximadamente 44s, e o número de registros real: 1 milhão. O atributo loops indica o número de vezes em que a operação foi executada. Em alguns nós, como alguns joins, será maior que 1, e o número de registros e o tempo são mostrados por iteração, devendo-se multiplicar tais valores pela quantidade de loops para chegar ao valor total.

Para somente analisar queries que alteram dados, você pode fazer o seguinte:
~~~sql
BEGIN TRANSACTION;
    EXPLAIN ANALYZE UPDATE …
ROLLBACK;
~~~

Outro parâmetro útil do EXPLAIN é o __BUFFERS__, que mostra a __quantidade de blocos, 8kB__ por padrão, encontrados no __shared buffers__ ou que foram lidos do disco ou, ainda, de arquivos temporários que foram necessários ser gravados em disco

~~~sql
bench=\# EXPLAIN (ANALYZE, BUFFERS)
    select * from pgbench_accounts a
    inner join pgbench_branches b on a.bid =b.bid
    inner join pgbench_tellers t on t.bid =b.bid
    where  a.bid=56
~~~

A saída mostra os dados __shared hit__ e __read__.

## Indices

Nos exemplos com o EXPLAIN, vimos nos planos de execução várias operações de SEQ SCAN. Essa operação varre a tabela toda e é executada quando não há um índice que atenda a consulta, ou porque o Otimizador acredita que terá de ler quase toda a tabela de qualquer jeito, sendo um overhead desnecessário tentar usar um índice

> Índices são estruturas de dados paralelas às tabelas que têm a função de tornar o acesso aos dados mais rápido. 

Em um acesso a dados sem índices, é necessário percorrer todo um conjunto de dados para verificar se uma condição é satisfeita. Índices são estruturados de forma a serem necessárias menos comparações para localizar um dado ou determinar que ele não existe.

Existem vários tipos de índices, __sendo o mais comum o BTree__, baseado em uma __estrutura em árvore__. No PostgreSQL é o tipo padrão, e se não informado no comando CREATE INDEX, ele será assumido.

__Índices e constraints são coisas distintas__. Índices, como foi dito, são estruturas de dados, ocupam espaço em disco e têm função de melhoria de desempenho. __Constraints__ são regras, restrições impostas aos dados. 

A confusão nasce porque as __constraints do tipo PRIMARY KEY e UNIQUE de fato criam índices implicitamente__ para garantir as propriedades das constraints. `O problema reside com as FOREIGN KEY`. Para uma FK, o PostgreSQL não cria índices automaticamente

### Índices simples

No exemplo de plano de execução recém-mostrado, vemos um SEQ SCAN com um filter. Esse é o candidato perfeito para criarmos um índice

~~~sql
bench=# CREATE INDEX idx_accounts_bid ON pgbench_accounts(bid);
~~~

> Índices criam locks nas tabelas que podem bloquear escritas. Se for necessário criá-lo em horário de uso do sistema, pode-se usar CREATE INDEX CONCURRENTLY, que usará um mecanismo menos agressivo de locks, porém demorará mais para executar.

### Índices compostos

índices compostos, com múltiplas colunas

~~~sql
bench=\# CREATE INDEX idx_branch_bid_tbalance ON pgbench_tellers(bid,tbalance);
~~~

### Índices parciais

Índices parciais são __índices comuns__, podem ser __simples ou compostos__, que __possuem uma cláusula WHERE__. Eles se aplicam a um subconjunto dos dados e podem ser muito mais eficientes com cláusulas SQL que usem o mesmo critério.

~~~sql
bench=\# CREATE INDEX idx_accounts_bid_parcial ON pgbench_accounts(bid) WHERE abalance > 0;
~~~

Índices parciais são especialmente __úteis com colunas boolean__, sobre a qual índices BTree não são eficazes, em comparação com NULL.

### Índices com expressões

Um erro também comum é usar uma coluna indexada, porém ao escrever a query, aplicar alguma função ou expressão sobre a coluna

~~~sql
bench=# EXPLAIN select * from pgbench_accounts where coalesce(bid,0) = 56;
~~~

A coluna bid é indexada, mas quando foi aplicada uma função sobre ela, foi feito SEQ SCAN. Para usar um índice, nesse caso é necessário criar o índice com a função aplicada

~~~sql
bench=# CREATE INDEX idx_accounts_bid_coalesce ON pgbench_accounts( COALESCE(bid,0) );
~~~

### Covering Indexes

Como explicado anteriormente, os índices são estruturas de dados à parte da tabela. Existe uma operação interna do banco chamada __Index Only Scan__, que ocorre quando o dado sendo buscado está no índice e neste caso não é necessário acessar a tabela para retorná-lo – normalmente, isso é muito mais rápido.

Os covering indexes __permitem adicionar um campo no índice sem indexar por esse campo__, apenas para tornar possível __retorná-lo mais rapidamente usando um Index Only Scan__.


Para criar um índice covering, usa-se o atributo INCLUDE. No nosso exemplo, ele seria criado assim:
~~~sql
contabil=# CREATE INDEX ON notafiscal( numero ) INCLUDE valor;
~~~

### Tipos de Índices

O PostgreSQL suporta os seguintes tipos de índices: 
- BTREE (padrão)
- HASH
- GIST
- GIN
- BRIN

O tipo do índice a ser utilizado depende do tipo de operação de comparação a ser feita e dos tipos de dados. 
- BTREE é utilizado para as operações de igualdade (=) e comparações que dependem da ordenação dos dados (<,<=,>,>=). 
- HASH pode ser utilizado apenas para igualdade. 
- Índices GIST são apropriados para tipos geométricos
- GIN para arrays, ambos (gist e gin) podem ser utilizados com Text Search
- BRIN, trabalha com as mesmas operações que o BTREE, porém pode ser mais eficiente por ser muito menor, já que não guarda uma entrada para cada registro da tabela, mas apenas o menor e maior valor para o range de registros dentro de um bloco

### Funções e Store Procedures

O PostgreSQL implementa store procedures e funções. Uma grande característica do PostgreSQL é permitir a criação de funções e procedures em diversas linguagens. A principal delas é a pl/pgsql.

A diferença entre funções e procedures é que a primeira é atômica: sempre que se chama uma função se terá uma e somente uma transação. Já em uma procedure é possível usar os comandos COMMIT e ROLLBACK e ter controle transacional

Escrevendo funções e procedures, pode-se evitar:
1. o custo de IPC
2. comunicação entre processos
3. o custo do tráfego pela rede
4. custo do parse da query entre múltiplas chamadas






