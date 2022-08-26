# Módulo 9 - Backup e recuperação

tags
> Dump e variações (Texto e Binário); Restore; Backup online; Backup Lógico e Físico; Point-in-Time Recovery e Log Shipping.

## Introdução

O PostgreSQL possui duas estratégias de backup: 
- o dump de bases de dados (__backup lógico__) individuais;
- e o chamado __backup físico e de WALs__, para permitir o __Point-in-Time Recovery__.

O __dump__ de uma base de dados, também chamado de __backup lógico__, é feito através do utilitário __pg_dump__. 
O dump é a __geração de um arquivo com os comandos necessários para reconstruir a base no momento em que o backup__ foi iniciado. Assim, no arquivo de dump não estarão os dados de um índice, mas sim o comando para reconstrução do índice.

- O dump é dito __consistente__ por tomar um __snapshot do momento do início do backup__ e não considerar as __alterações que venham a acontecer desse ponto em diante__
- O dump é também __considerado um processo online__, por não precisar __parar o banco__, remover conexões e nem mesmo bloquear as operações normais de leitura e escrita concorrentes
- Os únicos comandos que não podem ser executados durante um dump são aqueles que __precisam de lock exclusivo__, como __ALTER TABLE__ ou __CLUSTER__.
- Os arquivos de dump são altamente __portáveis__, podendo ser executados em __versões diferentes do PostgreSQL__

## Dumps

### A ferramenta pg_dump

- O pg_dump pode ser usado remotamente. Com a maioria dos clientes do PostgreSQL, aplicam-se as opções de host (-h), porta (-p), usuário (-U)
- os backups são gerados como scripts SQL em formato texto
- ou em formato de archive, chamado também binário, que permite restauração seletiva, por exemplo, de apenas um schema ou tabela.
- necessário ter permissão de SELECT em todas as tabelas da base para fazer um dump completo. Normalmente, executa-se o dump com o superusuário postgres.

Exemplo
~~~bash
pg_dump curso > /backup/curso.sql
-- ou
pg_dump -f /backup/curso.sql curso
~~~

### Formatos

O parâmetro -F indica formato e pode ter os seguintes valores:

|||
|--|--|
|c (custom)| archive ou binário: é compactado e permite seleção no restore|
|t (tar)| formato tar|
|d (directory)|objetos em estrutura de diretórios, compactados|
|p (plain-text)|script SQL|

Para fazer um dump binário, usamos a opção -Fc. 
~~~bash
pg_dump -Fc -f /backup/curso.dump curso
~~~

### Schemas

É possível especificar quais schemas farão parte do dump com o __parâmetro -n__. Ele incluirá __apenas os schemas informados__.

dump apenas do schema extra
~~~bash
pg_dump -n extra -f /backup/extra.sql curso
~~~

schemas extra e avaliacao, em formato binário
~~~bash
pg_dump -Fc -n extra -n avaliacao -f /backup/extra_avaliacao.dump curso
~~~

Note que podemos excluir um ou mais schemas selecionados através da __opção -N__. Isso fará o dump de todos os schemas da base, exceto os informados com -N. 

dump de toda a base curso, exceto do schema extra:
~~~bash
pg_dump -N extra -f /backup/curso_sem_extra.sql curso
~~~

### Tabelas

Existem os __parâmetros -t e -T__ para tabelas. 
- __-t__: fará o dump somente da tabela informada
- __-T__: dump de todas as tabelas, exceto daquelas informadas com -T

dump apenas da tabela times:
~~~bash
pg_dump -t public.times -f /backup/times.sql curso
~~~

Podemos informar -t múltiplas vezes para selecionar mais de uma tabela:
~~~bash
pg_dump -t public.times -t public.grupos -f /backup/times_grupos.sql curso
~~~

A exclusão de uma determinada tabela do dump com -T:
~~~bash
pg_dump -T public.cidades -f /backup/curso_sem_cidades.sql curso
~~~


### Padrões de string

Tanto para schemas quanto para tabelas, é possível utilizar padrões de string na passagem de parâmetros, conforme demonstrado a seguir:
~~~bash
pg_dump -t ‘extra.log*’ -f /backup/extra_log.sql curso
~~~

### Dados e estrutura

Para fazer dump somente dos dados, sem os comandos de criação da estrutura, ou seja, sem os __CREATE SCHEMA__, __CREATE TABLE__ e assemelhados, utiliza-se o __parâmetro -a__.
~~~bash
pg_dump -a -f /backup/curso_somente_dados.sql curso
~~~

dump apenas da estrutura do banco (definição da base de dados e seus schemas e objetos) - __opção -s ou --schema-only__
~~~bash
pg_dump -s -f /backup/curso_somente_estrutura.sql curso
~~~

### Dependências

Quando utilizado __-n__ para escolher um schema ou __-t__ para uma tabela, podem existir dependências de objetos em outros schemas. Por exemplo, pode existir uma foreign key ou uma visão apontando para uma tabela de outro schema. 
O __pg_dump não fará dump desses objetos__, levando a ocorrer __erros no processo de restauração__.

### Large objects

Os __large objects__ são incluídos por padrão nos __dumps completos__; porém, em backups seletivos __com -t, -n ou –s, eles não serão incluídos__.
Nesses casos, para incluí-los, é necessário usar a __opção -b__:
~~~bash
pg_dump -b -n extra -f /backup/extra_com_blobs.sql curso
~~~

### Exclusão de objetos existentes

No pg_dump, é possível informar a__ opção -c__ para gerar os __comandos de exclusão dos objetos__ antes de criá-los e populá-los. 

> É útil para dump texto, pois com dumps binários é possível informar essa opção durante a restauração

~~~bash
pg_dump -c -f /backup/curso.sql curso
~~~

### Criar a base de dados

Instrução para __criação da base__ dentro do próprio __arquivo de dump__.
Isso se aplica para scripts – __dump texto__, onde é gerado o comando para criação da base seguido da conexão com esta, independentemente da base original.

Dumps binários
~~~bash
pg_dump -C -f /backup/curso.sql curso
~~~

com o parâmetro -c, emitir um comando de drop da base de dados antes de criá-la:
~~~bash
pg_dump -C -c -f /backup/curso.sql curso
~~~

> Se a base indicada já existir, essa será excluída, desde que não existam conexões. Se houver conexões, será gerado um erro no DROP DATABASE. Como o comando CREATE DATABASE executado em sequência, um novo erro será gerado, já que a base já existe (pois não foi possível excluí-la). No final do processo, contudo, será feito o \connect na base, que não foi nem excluída e nem recriada, e tudo parecerá funcionar normalmente.

### Permissões

Para gerar um dump sem privilégios, usa-se a __opção -x__:
~~~bash
pg_dump -x -f /backup/curso_sem_acl.sql curso
~~~

Não serão gerados os GRANTs, mas continuam os proprietários dos objetos com os atributos OWNER. Para remover também o owner, usa-se a __opção -O__:
~~~bash
pg_dump -O -x -f /backup/curso_sem_permissoes.sql curso
~~~

### Compressão

É possível __definir o nível de compactação__ do dump com o __parâmetro -Z__. 
É possível informar um __valor de 0 a 9__, onde __0__ indica __sem compressão__ e __9__ o __nível máximo__. Por padrão, o dump binário (custom) é compactado com nível 6. 

> Um dump do tipo texto não pode ser compactado.

Dump binário com compactação máxima
~~~bash
pg_dump -Fc -Z9 -f /backup/curso_super_compacatado.dump curso
~~~

### Backup paralelo

Para __grandes bases de dados__ cujo tempo de dump esteja __muito longo__, é possível executar o __dump paralelamente através de diversos processos__, diminuindo o tempo total do backup. 
Para isso usamos o __parâmetro -j__ ou __--jobs__ com o número de processos. Esse recurso só pode ser utilizado com o __formato “directory” (-Fd)__. 
O seguinte comando roda o dump simultaneamente por 4 processos e gera o backup no diretório “curso-backup”.
~~~bash
pg_dump --Fd –j 4 -f /backup/curso-backup curso
~~~

### Outras opções

alterar o formato do encoding com a __opção -E__:
~~~bash
pg_dump -E UTF8 -f /backup/curso_utf8.sql curso
~~~

Quando o arquivo de dump é gerado, os comandos de criação de objetos são emitidos com seus tablespaces originais, que deverão existir no destino. É possível __ignorar esses tables-spaces__ com
o __argumento --no-tablespaces__.
Nesse caso, será usado o tablespace default no momento da restauração.
~~~bash
pg_dump --no-tablespaces -f /backup/curso_sem_tablespaces.sql curso
~~~

Para dumps __somente de dados__, pode ser útil emitir comandos para __desabilitar triggers e validação de foreing keys__. Para tanto, é necessário informar o __parâmetro –disable-triggers__.
Essa opção vai emitir comandos para desabilitar e habilitar as triggers antes e depois da carga das tabelas.
~~~bash
pg_dump --disable-triggers -f /backup/curso_sem_triggers.sql curso
~~~

## pg_dumpall

- É um utilitário que faz o __dump do servidor inteiro__. 
- Ele executa o pg_dump internamente para cada base da instância, incluindo ainda os objetos globais – roles, tablespaces e privilégios que nunca são gerados pelo pg_dump. 
- Esse dump é gerado somente no formato texto.

~~~bash
pg_dumpall > /backup/servidor.sql
-- Ou
pg_dumpall -f /backup/servidor.sql
~~~

### Opções

Para gerar um dump somente das informações globais – usuários, grupos e tablespaces – é possível informar a __opção -g__:
~~~bash
pg_dumpall -g -f /backup/servidor_somente_globais.sql
~~~

Para gerar o dump apenas das roles – usuários e grupos – use a __opção -r__:
~~~bash
pg_dumpall -r -f /backup/roles.sql
~~~

Para gerar o dump apenas dos tablespaces, use a __opção -t__:
~~~bash
pg_dumpall -t -f /backup/tablespaces.sql
~~~

## Dump com blobs

O dump de bases com um grande volume de dados em __large objects__ ou em __campos do tipo bytea__ pode ser um sério problema. Esses campos são usados para armazenar conteúdo de arquivos, como imagens e arquivos no formato pdf, ou mesmo outros conteúdos multimídia.

Large objects são manipulados por um conjunto de funções específicas e são armazenados em estruturas paralelas ao schema e à tabela na qual são definidos. 
Ao fazer __um dump de um schema ou tabela__ específicos, __os blobs não são incluídos por padrão__. Utilizar o __argumento –b__ para incluí-los fará com que todos os large objects da base sejam incluídos no dump, e não somente os relacionados ao schema ou tabela em questão.

Já os campos bytea não possuem essas inconsistências no dump. Mas os large objects têm um péssimo desempenho e consomem muito tempo e espaço
Parte da explicação para isso está no __mecanismo de TOAST__, que já faz a compressão desses dados na base. 
Toda operação de leitura de um dado armazenado como TOAST exige que esses sejam previamente descomprimidos. Com um dump envolvendo dados TOAST não é diferente. O pg_dump lê os dados da base e grava um arquivo. Se a base está cheia de blobs, serão realizadas grande quantidade de descompressões.

Em seguida, tudo terá de ser novamente compactado (já que a compressão dos dados é o comportamento padrão do pg_dump). Esse duplo processamento de descompressão e compressão acaba consumindo muito tempo. Além disso, se o nível de compressão dos dados TOAST for maior que o padrão do pg_dump, o tamanho do backup poderá ser maior que o da base original.

> Baixar o nível de compressão, digamos para Z3, aumentará o espaço consumido em disco, mas consumirá menos tempo. Já a opção Z1 fornece uma opção boa de tempo com um nível razoável de compressão



