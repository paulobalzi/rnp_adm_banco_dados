# Modulo 8 - Desempenho: tópicos sobre configuração e infraestrutura

tags
> Full-Text Search; Indexadores de Documentos; Índices GIN; Operadores de Classe; Cluster; Particionamento; Memória de Ordenação; Escalabilidade; Filesystem e RAID.

## Busca em texto

### Like/ilike (case insensitive)

- gera problemas de desempenho em queries
- uma coluna do tipo texto que está sendo utilizado pelo comando like, pode estar indexada e não ser utilizado pelo 
comando. É preciso utilizar __um operador__ especial no momento da criaçãodo índice para que operações com LIKE possam aproveitá-lo.

Esse operador depende do tipo da coluna:

|||
|--|--|
|Varchar|varchar_pattern_ops|
|Char|bpchar_pattern_ops|
|Text|text_pattern_ops|

Criar um índice que possa ser pesquisado pelo LIKE

~~~sql
curso=\# CREATE INDEX idx_like ON times(nome varchar_pattern_ops);
~~~

Outro motivo para o PostgreSQL não utilizar os índices numa query com LIKE é se for usado % no início da string, significando que pode haver qualquer coisa antes. Por exemplo:

~~~sql
curso=\# SELECT * FROM times WHERE nome LIKE ‘%Herzegovina%’;
~~~

> Essa cláusula nunca usará índice, mesmo com o operador de classe sempre varrendo a tabela inteira.

### Full-Text Search - FTS

O FTS permite busca __por frases exatas__, uso de __operadores lógicos__ | (or), & (and) e ! (not), __ordenação por relevância__(ranking), destacar os termos pesquisados e diversas outras opções.

Para melhor desempenho e manutenção, fazemos uma preparação prévia:

1. necessário alterar a tabela para utilizar esse recurso, __inserindo uma coluna do tipo tsvector__:

~~~sql
curso=\# ALTER TABLE times ADD COLUMN historia_fts tsvector;
~~~

2. deve-se __copiar e converter o conteúdo da coluna que contém o texto original__ o qual desejamos fazer a busca para a nova coluna “vetorizada”

~~~sql
curso=\# UPDATE times SET historia_fts = to_tsvector(‘portuguese’, historia);
~~~

3. cria-se um __índice do tipo GIN ou GIST__ na coluna vetorizada:

~~~sql
curso=\# CREATE INDEX idx_historia_fts ON times USING GIN(historia_fts);
~~~

Desse ponto em diante, pode-se usar o FTS bastando aplicar, por exemplo, o operador @@ e a função ts_query:

~~~sql
-- buscando todos os registros que contenham as palavras “campo” e “mundo”
curso=\# SELECT nome, historia FROM times WHERE historia_fts @@ to_tsquery (‘portuguese’,’campo & mundo’);
~~~

> Quando criamos a coluna do tipo ts_vector e a carregamos através do update, fizemos isso apenas para os dados existentes. Para __novos dados inseridos__ ou atualizados, é necessário criar uma __trigger__ para alterar também a coluna vetorizada.

> Para se obter uma __taxa de relevância__ dos resultados obtidos, pode-se usar a função __ts_rank__; para fazer o __“highlight”__ do resultado, ou seja, destacar os critérios de busca, usa-se a função __ts_headline__.

Busca por frases onde a ordem e/ou distância entre os termos são importantes (__operador <->__)

~~~sql
-- retorna resultados apenas quando “copa” vem antes de “mundo”, e exatamente a duas posições de distância:
curso=# SELECT nome, historia FROM times WHERE historia_fts @@ to_tsquery(‘portuguese’,’copa <2> mundo’)
~~~

> __Dica__: a extensão pg_trgm adiciona recursos de busca em texto através do método __trigram__. Ele fornece funções e operadores, possibilitando criar índices que aceitam buscas com % no início do LIKE, além de também trabalhar com FTS. Porém, o __tamanho do índice pode ser desproporcionalmente grande__, e o custo de atualização bastante alto

### Softwares indexadores de documentos

Softwares específicos, como o __Lucene__ e __SOLR__ (ambos open source)

Esses softwares __leem os dados do banco periodicamente__ e __criam índices onde são feitas as buscas__. Como normalmente os conteúdos de documentos mudam pouco, essa estratégia é melhor do que acessar o banco a cada vez.

## Organização de tabelas grandes

### Cluster de tabela

Se tivermos uma tabela grande, muito usada, já indexada, e ainda assim com a necessidade de melhorar o acesso a ela, uma possibilidade é o comando __CLUSTER__. 
Essa operação vai ordenar os dados da tabela fisicamente segundo um índice que for informado. É especialmente útil quando são lidas faixas de dados em um intervalo. 

~~~sql
bench=# CLUSTER pgbench_accounts USING idx_accounts_bid;
~~~

### Particionamento de tabelas

Esse procedimento __divide uma tabela em outras menores__, __baseado em algum campo que você definir__, em geral um ID ou uma data. Isso pode trazer benefícios de desempenho, já que as __queries__ farão __varreduras__ em __tabelas menores ou índices menores__. No PostgreSQL, o particionamento é feito de forma declarativa, também chamada __nativa__, ou usando __herança de tabelas__.

![Tabela Particionada](images/tabela_particionada.png)

### Particionamento Declarativo

Forma mais simples de criar e gerenciar uma estrutura de tabelas particionadas. Ao contrário do particionamento através de herança, __não é necessário criar check constraints e triggers__ manualmente para tratar o direcionamento dos dados para as partições.

Como criar:
1. Criar uma tabela principal, que não terá dados, indicando que será particionável através do atributo __PARTITION BY__

~~~sql
curso=# CREATE TABLE item_financeiro (
            iditem int, data timestamp, descricao varchar(50), valor numeric(10,2)
        ) PARTITION BY RANGE (data);
~~~

2. Criar as tabelas de partições

~~~sql
curso=\# CREATE TABLE item_financeiro_2012 PARTITION OF item_financeiro 
            FOR VALUES FROM (‘2012-01-01’) TO (‘2013-01-01’);
curso=\# CREATE TABLE item_financeiro_2013 PARTITION OF item_financeiro 
            FOR VALUES FROM (‘2013-01-01’) TO (‘2014-01-01’);
curso=\# CREATE TABLE item_financeiro_2014 PARTITION OF item_financeiro 
            FOR VALUES FROM (‘2014-01-01’) TO (‘2015-01-01’);
~~~

3. Criar índices nas colunas chaves de particionamento (não obrigatório mas recomendado devido ao desempenho)

Criar o índice na tabela principal que estes serão automaticamente criados em todas as partições.

~~~sql
curso=# CREATE INDEX ON item_financeiro(data);
~~~

### Formas de particionamento

1. Particionamento RANGE, onde define-se uma faixa de valores com a sintaxe:

~~~text
... PARTITION OF tabela_principal FOR VALUES FROM v1 TO v2;
~~~

2. Usando o atributo __LIST__, cujos valores são explicitamente definidos:

~~~sql
CREATE TABLE tabela_pai (…) PARTITION BY LIST (campo);

CREATE TABLE tabela_filha1 PARTITION OF tabela_principal
    FOR VALUES IN (‘Novo’,’Em Atendimento’,’Em entrega’);

CREATE TABLE tabela_filha2 PARTITION OF tabela_principal
    FOR VALUES IN (‘Entregue’,’Cancelado’,’Devolvido’);
~~~

3. particionamento __por HASH__
Utilizado quando não temos uma chave natural para particionar os dados. Nesta forma de particionamento, é necessário definir um
__modulus (divisor)__ e um remainder (resto__). O Postgres vai gerar um valor hash para o campo chave escolhido e então dividirá esse hash pelo modulus e o registro será direcionado para a partição cujo resto seja igual.

~~~sql
CREATE TABLE tabela_pai (…) PARTITION BY HASH (campo);

CREATE TABLE tabela_filha1 PARTITION OF tabela_principal
    FOR VALUES WITH (modulus 3, remainder 0);

CREATE TABLE tabela_filha2 PARTITION OF tabela_principal
    FOR VALUES WITH (modulus 3, remainder1);

CREATE TABLE tabela_filha3 PARTITION OF tabela_principal
    FOR VALUES WITH (modulus 3, remainder 2);
~~~

### Múltiplos níveis

É possível também ter __múltiplos níveis de particionamento__. 
Por exemplo, uma tabela é particionada por ano e depois cada partição anual pode ser particionada por mês ou status. É possível ter formas diferentes entre os níveis. Por exemplo, o primeiro nível é particionado por RANGE, e o segundo LIST.

### Partição Default

Os dados que não se encaixam nas regras das demais partições são __direcionados__ para a __partição default__. Caso ela __não
exista__ e o valor não se enquadre nas demais, __um erro é gerado__.

Partições default podem ser criadas para as formas RANGE e LIST.

~~~sql
CREATE TABLE tabela_filha PARTITION OF tabela_principal DEFAULT;
~~~

> __OBS__: Apesar de parecer uma ótima ideia à primeira vista, precisar de uma partição default pode significar que você não modelou suas partições corretamente. Além disso, __depois de adicionar uma partição default__, você __não pode__ mais __adicionar partições para novos valores__: será necessário desanexar a partição default, criar a nova partição e mover os dados dela manualmente antes de poder adicionar uma partição default novamente.

### Particionamento por herança

1. Como no particionamento nativo, criar uma tabela principal, que não terá dados, porém sem o atributo PARTITION BY:

~~~sql
curso=\# CREATE TABLE item_financeiro (iditem int, data timestamp, descricao varchar(50), valor numeric(10,2));
~~~

2. Criar as tabelas filhas, herdando as colunas da tabela principal

~~~sql
curso=\# CREATE TABLE item_financeiro_2012 () INHERITS (item_financeiro);

curso=\# CREATE TABLE item_financeiro_2013 () INHERITS (item_financeiro);

curso=\# CREATE TABLE item_financeiro_2014 () INHERITS (item_financeiro);
~~~

3. Adicionar uma __CHECK__ constraint em cada tabela filha, ou partição, para aceitar dados apenas da faixa certa para a partição

~~~sql
curso=\# ALTER TABLE item_financeiro_2012 ADD CHECK (data >= ‘2012-01-01’ AND data < ‘2013-01-01’);
~~~

4. Criar uma trigger na tabela principal, que direciona os dados para as filhas.

~~~sql
curso=\#
CREATE OR REPLACE FUNCTION itemfinanceiro_insert_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.data >= ‘2012-01-01’ AND NEW.data < ‘2013-01-01’) THEN
        INSERT INTO item_financeiro_2012 VALUES (NEW.*);
    ELSIF (NEW.data >= ‘2013-01-01’ AND NEW.data < ‘2014-01-01’) THEN
        INSERT INTO item_financeiro_2013 VALUES (NEW.*);
    ELSIF (NEW.data >= ‘2014-01-01’ AND NEW.data < ‘2015-01-01’) THEN
        INSERT INTO item_financeiro_2014 VALUES (NEW.*);
    ELSE
        RAISE EXCEPTION ‘Data fora de intervalo válido’;
    END IF;

    RETURN NULL;
END;
$$
LANGUAGE plpgsql;
curso=\# CREATE TRIGGER t_itemfinanceiro_insert_trigger 
    BEFORE INSERT ON item_financeiro 
    FOR EACH ROW EXECUTE PROCEDURE itemfinanceiro_insert_trigger();
~~~

5. Criar os índices nas tabelas filhas:

~~~sql
curso=# CREATE INDEX idx_data_2012 ON item_financeiro_2012(data);
~~~

![Particionamento Herança](images/particionamento_heranca.png)

Podemos ver que foi necessário apenas acessar uma partição

### Expurgo de dados particionados

Outra grande vantagem do particionamento está no momento de __apagar dados antigos__.

Utilizando o método tradicional, usa-se um DELETE com uma cláusula WHERE que inclua os registros antigos. Em uma partição com milhões de registros, essa operação é lenta e gera grande quantidade de log de transação. 

Com o particionamento, é possível:
- simplesmente __apagar uma partição antiga com DROP__
- __desanexar__ uma partição do __modo declarativo__ com `ALTER TABLE master DETACH PARTITION partição` ou, 
- no __particionamento por herança__, usando `ALTER TABLE partição NO INHERIT master`

> Para o particionamento funcionar de forma eficiente, é necessário que o __parâmetro__ __constraint_exclusion__ esteja __habilitado__, podendo estar com o __valor “partition” ou “on”, mas não pode estar “off”__

## Procedimentos de manutenção

Destacar três que podem impactar significativamente o desempenho do banco:
- Vacuum
- Estatísticas
- Índices Inchados

### Vacuum

A operação de Vacuum pode afetar o desempenho das tabelas, especialmente se não estiver sendo executada periodicamente, ou sendo executada com pouca frequência.

> Ao analisar uma query específica, executar um __Vacuum manual__ nas tabelas envolvidas pode ajudar a resolver alguma questão relacionada a __dead tuples__

### Estatísticas

Uma query pode estar escolhendo um plano de execução ruim por falta de estatísticas ou por estatísticas insuficientes

> executar o ANALYZE nas tabelas envolvidas pode ajudar o Otimizador a escolher um plano de execução mais realista

### Índices inchados (Bloated indexes)

Bloated indexes ou índices inchados são índices com grande quantidade de dead tuples. Executar o comando __REINDEX__ para reconstrução de índices nessa situação é apenas mais um exemplo de como as atividades de manutenção podem ser importantes para preservar e garantir o desempenho do banco

## Configurações para desempenho

### work_mem

É a __quantidade de memória__ que um processo pode usar para operações envolvendo __ordenação e hash__ – como ORDER BY, DISTINCT, IN e alguns algoritmos de join escolhidos pelo Otimizador. Se a área necessária por uma query for maior do que o especificado através desse parâmetro, a operação será __feita em discos__, através da criação de __arquivos temporários__

Ao analisar uma query em particular executando o EXPLAIN (ANALYZE, BUFFERS), um resultado a ser observado é se há arquivos temporários sendo criados.

Se esse __parâmetro estiver muito baixo__, muitas queries podem ter de __ordenar em disco__, e isso causará grande impacto __negativo__ no tempo de __execução__ dessas __consultas__

Se esse valor for __muito alto__, centenas de queries simultâneas poderiam demandar memória, resultando na alocação de uma quantidade grande demais de memória, a ponto de até __esgotar a memória disponível__.

O valor __default__, __4MB__, é muito modesto para queries complexas. Dependendo da sua quantidade de memória física, pode-se __aumentá-lo de 8MB a 32MB__

> Recomendação: fórmula proporcional à memória física disponível e a quantidade de conexões máximas para definição do valor do work_mem

> pode-se definir um work_mem maior apenas para as queries que mais estão gerando arquivos temporários, ou apenas para uma base específica

Pode-se verificar se está ocorrendo __ordenação em disco__ através da view do catálogo __pg_ stat_database__, mas essa é uma informação geral para toda a base. Através do parâmetro __log_temp_files__, é possível __registrar no log do PostgreSQL__ toda vez que uma __ordenação em disco ocorrer__, ou que passe de determinado tamanho. Essa informação é inclusive mostrada nos relatórios do __pgBadger__.

Os valores para log_temp_files são:
- __0 g__ Todos os arquivos temporários serão registrados no Log
- __-1 g__ Nenhum arquivo temporário será registrado
- __N g__ Tamanho mínimo em KB. Arquivos maiores do que N serão registrados

Exemplo de log

~~~text
user=curso,db=curso
        LOG: temporary file:
                        Path “base/pgsql_tmp/pgsql_tmp23370.25”, size 269557760
    user=curso,db=curso STATEMENT: SELECT ...
~~~

### shared_buffers

> área de cache de dados do PostgreSQL

Aumentar o shared_buffers é uma possibilidade para forçar mais memória do sistema para o PostgreSQL

Calcular a taxa de acerto no shared buffer através da view __pg_stat_database__, pode ajudar a tomar uma decisão sobre aumentar essa área. É difícil dizer o que é um percentual de acerto adequado, mas se for uma __aplicação transacional__ de uso __frequente__, deve-se com certeza absoluta buscar trabalhar com __taxas superiores a 90% ou 95%__ de acerto

~~~sql
postgres=# SELECT datname,
                CASE WHEN blks_hit = 0 THEN 0
                    ELSE (( blks_hit / (blks_read + blks_hit)::float) * 100)::float
                END as cache_hit
            FROM pg_stat_database
            WHERE datname NOT LIKE ‘template_’
            ORDER BY 2;
~~~

![Shared Buffer](images/shared_buffer.png)
Taxa de acerto

> É possível carregar uma tabela específica para o cache do SO ou para os Shared Buffers com a extensão pg_prewarm. É possível configurar para ser executado automaticamente após um restart quando o cache está “frio”.

### effective_cache_size

É apenas uma informação, uma estimativa, do tamanho total de cache disponível, shared_ buffer + page cache do SO.
Essa estimativa pode ser usada pelo Otimizador para decidir se um determinado índice cabe na memória ou se a tabela deve ser varrida

> __Configuração:__ some o valor do parâmetro shared_buffers ao valor observado da memória sendo usada para cache em seu servidor. O tamanho do cache pode ser facilmente consultado com free, mas também com top, vmstat e sar

### Checkpoints












