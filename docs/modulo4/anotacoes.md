# MÓDULO 4 - ADMINISTRANDO USUÁRIOS E SEGURANÇA

tags
~~~text
Roles de Usuários e de Grupos; Privilégios; GRANT; REVOKE; Host Based Authentication e RLS-
Row Level Security
~~~

## GERENCIANDO ROLES

O PostregSQL controla permissões de acesso através de roles. As roles pode ser entendidas como usuários ou grupos de
usuários dependendo de como são criadas.
Os comandos `User` e `Group`, manipulam roles e foram mantidos para manter a compatibiliade com versões anteriores.

Características:
- Roles existem no SGBD e não possuem relação com o SO
- são do escopo do servidor. Vale para toda a instância. (não é por base)
- quando iniciada com o `initdb`, é criada uma role do susperusuário com o mesmo nome do usuário do SO (default = postgres)

### CRIAÇÃO DE ROLES

~~~sql
postgres=# CREATE ROLE siscontabil LOGIN PASSWORD ‘a1b2c3’;
~~~

__LOGIN__: informa que a role pode conectar-se 

~~~sql
postgres=# CREATE ROLE jsilva LOGIN PASSWORD ‘xyz321’ VALID UNTIL ‘2018-12-31’;
~~~

__VALID UNTIL__: informa a data de expiração para a senha do usuário.

~~~sql
postgres=# CREATE ROLE moliveira LOGIN PASSWORD ‘xyz321’ CREATEROLE;
~~~

__CREATEROLE__: permissão para criar outras roles

> Importante destacar que apenas superusuários ou quem possui o privilégio CREATEROLE pode criar roles.

Outros atributos importantes das roles são:

- __SUPERUSER__: fornece à role o privilégio de superusuário. Roles com essa opção não precisam ter nenhum outro privilégio.
- __CREATEDB__: garante à role o privilégio de poder criar bases de dados.
- __REPLICATION__: roles com esse atributo podem ser usadas para replicação.

#### ROLE COM COMPORTAMENTO DE GRUPO

~~~sql
postgres=# CREATE ROLE contabilidade;
~~~

Adicionamos os usuários a role

~~~sql
postgres=# GRANT contabilidade TO jsilva;
postgres=# GRANT contabilidade TO moliveira;
~~~

O comando __GRANT__ fornece um privilégio para uma role.

### EXCLUSÃO DE ROLES

~~~sql
postgres=# DROP ROLE jsilva;
~~~

Entretanto, para uma role ser removida, ela não pode ter nenhum privilégio ou ser dona de objetos ou bases. Se houver, ou 
os objetos deverão ser excluídos previamente ou devemos revogar os privilégios e alterar os donos.

Para remover todos os objetos de uma role, é possível utilizar o comando DROP OWNED:

~~~sql
postgres=# DROP OWNED BY jsilva;
~~~

Serão revogados todos os privilégios fornecidos à role e serão removidos todos os objetos na base atual, caso não tenham dependência de outros objetos. Caso queira remover os objetos que dependem dos objetos da role, é possível informar o atributo __CASCADE__. Porém, deve-se ter em mente que isso pode remover objetos de outras roles. Esse comando não remove bases de dados
e tablespaces.

Caso deseje alterar o dono dos objetos da role que será removida, é possível usar o comando REASSIGN OWNED:

~~~sql
postgres=# REASSIGN OWNED BY jsilva TO psouza;
~~~

### MODIFICANDO ROLES

A instrução __ALTER ROLE__ pode modificar todos os atributos definidos pelo CREATE ROLE. No entanto, o ALTER ROLE é muito usado para fazer alterações específicas em parâmetros de configuração definidos globalmente no arquivo postgresql.conf ou na linha de
comando.

Definindo uma configuração específica para um único usuário. No exemplo vamos definir o atributo __work_mem__ para o usuário
_psouza_.

~~~sql
postgres=# ALTER ROLE psouza SET WORK_MEM = ‘8MB’

-- desfazendo a configuração
postgres=# ALTER ROLE psouza RESET WORK_MEM;
~~~

## PRIVILÉGIOS

> comandos GRANT e REVOKE

### GRANT

Quando se cria uma base de dados ou um objeto em uma base, `sempre é atribuído um dono`. Caso nada seja informado, será considerado dono a `role que está executando o comando`. 
O dono possui `direito de fazer qualquer coisa` nesse objeto ou base, mas os demais usuários precisam `receber explicitamente um privilégio`. Esse privilégio é concedido com o comando __GRANT__.

O GRANT possui uma sintaxe rica que varia de acordo com o objeto para o qual se está fornecendo o privilégio. Ele pode fornecer privilégios para roles em:
- Bases de Dados
- Schemas
- Objetos
- Tablespaces
- Roles


Foi então criado o schema geral e fornecida permissão USAGE para o grupo contabilidade.

~~~sql
postgres=# CREATE DATABASE sis_contabil OWNER gerente;

sis_contabil=> CREATE SCHEMA geral;
sis_contabil=> GRANT USAGE ON SCHEMA geral TO contabilidade;
~~~

~~~sql
sis_contabil=> GRANT CONNECT ON DATABASE sis_contabil TO contabil;
sis_contabil=> GRANT USAGE ON SCHEMA geral TO contabil;
sis_contabil=> GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA geral TO contabil;
~~~

Explicando os comandos acima:

1. concessão é o acesso à base de dados com o privilégio CONNECT
2. acesso ao schema com USAGE
3. para permitir que o usuário da aplicação possa ler e gravar dados em todas as tabelas do schema (ALL TABLES)

~~~sql
sis_contabil=> GRANT SELECT ON geral.balanco TO contabilidade;
sis_contabil=> GRANT EXECUTE ON FUNCTION geral.lancamento() TO contabilidade
~~~

1. foram fornecidas permissão de leitura de dados na tabela balanço
2. permissão de execução da função lancamento() ao grupo contabilidade

#### REPASSE DE PRIVILÉGIOS

Quando uma role recebe um privilégio com _GRANT_, é possível que ela possa repassar esses mesmos privilégios para outras roles.

~~~sql
sis_contabil=> GRANT SELECT, INSERT ON geral.contas TO moliveira WITH GRANT OPTION;
~~~

- A role _moliveira_ ganhou permissão para consultar e adicionar dados na tabela _geral.contas_
- Com __WITH GRANT OPTION__, _moliveira_ poderá repassar a mesma permissão para outras roles

~~~sql
-- repassando a mesma permissao para a role jsilva
sis_contabil=> GRANT SELECT, INSERT ON geral.contas TO jsilva;
~~~

No caso `sis_contabil=> GRANT ALL ON geral.contas TO jsilva;`, _jsilva_ só irá receber a permissão que _moliveira_ recebeu,
que são: _INSERT_ e _SELECT_.

#### PRIVILÉGIOS DE OBJETOS

Principais objetos e seus respectivos privilégios.

__Base de dados__

- CONNECT: permite à role conectar-se à base.
- CREATE: permite à role criar schemas na base.
- TEMP or TEMPORARY: permite à role criar tabelas temporárias na base

~~~sql
curso=# GRANT CONNECT, TEMP ON DATABASE curso TO aluno;
~~~

__Schemas__

- CREATE: permite criar objetos no schema.
- USAGE: permite acessar objetos do schema, mas ainda depende de permissão no objeto.

__Tabelas__

- SELECT, INSERT, UPDATE e DELETE são triviais para executar as respectivas operações.
- Com exceçao do _DELETE_, é possível especificar colunas
~~~sql
sis_contabil=# GRANT SELECT (descricao), INSERT (descricao), UPDATE (descricao) ON geral.balanco TO psouza;
~~~
- Para UPDATE e DELETE com cláusula WHERE, _é necessário também que a role possua SELECT na tabela
- TRUNCATE: permite que a role execute essa operação na tabela.
    - `Truncate é uma operação que elimina todos os dados de uma tabela mais rapidamente do que o DELETE`
- TRIGGER: permite que a role crie triggers na tabela.
- REFERENCES: permite que a role referencie essa tabela quando criando uma foreign key em outra.

__Visões/views__

São tratadas no PostgreSQL praticamente como uma tabela devido à sua implementação.
Tabelas, visões e sequências (sequences) são vistas genericamente como relações.

Por isso, visões podem receber GRANTS de escrita como INSERT e UPDATE. Porém, o funcionamento de comandos de inserção e atualização em uma view dependerá da existência de RULES ou TRIGGERS para tratá-las.

__Sequências/sequences__

Os seguintes privilégios se aplicam às sequências:
- USAGE: permite executar as funções currval e nextval sobre a sequência.
- SELECT: permite executar a função curval.
- UPDATE: permite o uso das funções nextval e setval.

Sequences são a forma que o PostgreSQL fornece para implementar campos _autoincrementais_. Elas são manipuladas através das funções:
- curval: retorna o valor atual da sequence.
- nextval: incrementa a sequence e retorna o novo valor.
- setval: atribui à sequence um valor informado como argumento.

> Como o novo atributo __IDENTITY__, ao criar uma coluna, temos as mesmas funcionalidades sem as preocupações de gerenciar as sequences e seus privilégios de uso

__Funções/procedures__

> As funções, ou procedures, possuem apenas o privilégio __EXECUTE__

~~~sql
sis_contabil=# GRANT EXECUTE ON FUNCTION validacao(cpf bigint, nome varchar) TO contabilidade;
~~~

> por padrão, a role __PUBLIC__ recebe permissão de __EXECUTE__ em todas as funções. Caso queira evitar esse comportamento, use __REVOKE__ para tirar a permissão após a criação da função.

#### CLÁUSULA ALL

Para sequências, visões e tabelas, existe a cláusula ALL … IN SCHEMA, que ajuda a fornecer permissão em todos os objetos daquele tipo no schema.

~~~sql
sis_contabil=# GRANT USAGE ON ALL SEQUENCES IN SCHEMA geral TO contabilidade;
~~~

> Vários outros objetos do PostgreSQL, tais como languages, types, domains e large objects, possuem privilégios que podem ser manipulados

### PERMISSÕES POR REGISTROS

#### ROW LEVEL SECURITY – RLS

- Novo recurso de segurança introduzido
- significa segurança a nível de registros
- o recurso disponibiliza acesso a registros ligados somente a uma determinada role

Exemplo:
Tabela contra_cheque onde cada usuário só pode acessar seus registros.

~~~sql
CREATE TABLE contra_cheque (id int, logincolaborador text,...);
ALTER TABLE contra_cheque ENABLE ROW LEVEL SECURITY;
CREATE POLICY politica_acesso_contracheque ON contra_cheque USING (logincolaborador = current_user);
~~~

Porém, pode ser necessário que alguns usuários especiais tenham acesso completo a todos os registros. O seguinte exemplo cria uma política que permite ao usuário admin ler (__USING__) e escrever (__WITH CHECK__) qualquer registro.

~~~sql
CREATE POLICY politica_acesso_contracheque_adm ON contra_cheque TO admin USING (true) WITH CHECK (true);
~~~

Permitir que os membros do grupo RH possam acessar os registros de contracheque dos membros da diretoria

~~~sql
CREATE POLICY politica_acesso_contracheque_diretoria ON contra_cheque TO rh USING ( departamento = 'Diretoria');
~~~

__Superusuários__ e usuários que possuam o atributo __BYPASSRLS__ não são afetados pela RLS, sempre veem todos os registros. O __owner da tabela__, por padrão, também tem a visibilidade de todos os registros, porém esse comportamento pode ser alterado

> __Importante__: a segurança por registro não dispara erros, os registros são apenas omitidos se as condições da policy não forem atendidas. Assim, ao utilizar o RLS deve-se ter o cuidado de não causar um efeito colateral em que registros fiquem ocultos aos processos de backup! Se o backup é feito pelo superusuário, não haverá problemas.

### REVOKE

O comando REVOKE remove privilégios fornecidos com GRANT

__ATENÇÃO__:
O REVOKE revogará um privilégio específico concedido em um objeto ou base, porém não significa que vai remover qualquer acesso que a role possua.

~~~sql
sis_contabil=# GRANT SELECT ON geral.balanco TO jsilva;
sis_contabil=# GRANT SELECT ON geral.balanco TO contabilidade;

-- revogando
sis_contabil=# REVOKE SELECT ON geral.balanco FROM jsilva;
~~~

Fazer o REVOKE da role direta não impedirá a role de acessar a tabela, pois ainda terá o privilégio através do grupo.

Nesse exemplo, a instrução __GRANT OPTION FOR__ não remove o acesso de INSERT e SELECT da role moliveira, apenas o direito de repassar essas permissões para outras roles.

~~~sql
sis_contabil=# REVOKE GRANT OPTION FOR SELECT, INSERT ON geral.contas FROM moliveira;
~~~

### USANDO GRANT E REVOKE COM GRUPOS

Adicionando as roles _jsilva_ e _moliveira_ ao grupo _contabilidade_

~~~sql
postgres=# GRANT contabilidade TO jsilva;
postgres=# GRANT contabilidade TO moliveira;
~~~

Removendo uma role do grupo

~~~sql
postgres=# REVOKE contabilidade FROM moliveira;
~~~

### CONSULTANDO OS PRIVILÉGIOS

Para consultar os privilégios existentes na tabela, no psql você pode usar o comando:

~~~sql
curso=# \dp cidades;
~~~

Na coluna _Access privileges_, temos:

~~~text
aluno=arwdDxt/postgres+
aluno=ar/postgres
~~~

onde (da esquerda pra direita):
- postgres: role que recebeu os privilégios
- arwdDxt: privilégios, cada letra representa um
- /postgres: quem forneceu a permissão

Na segunda linha, temos _aluno_ recebeu os privilégios __ar__ da role postgres

A tabela a seguir mostra o significado das letras:
|Cod|Descrição|
|--|--|
|a|INSERT (append)|
|r|SELECT (read)|
|w|UPDATE (write)|
|d|DELETE|
|D|TRUNCATE|
|x|REFERENCES|
|t|TRIGGER|
|X|EXECUTE|
|U|USAGE|
|C|CREATE|
|c|CONNECT|
|T|TEMPORARY|
|*|pode repassar o privilégio, pois recebeu o atributo WITH GRANT OPTION|

No exemplo `professor=ar*wd/postgres`, temos que a role professor pode repassar o privilégio _SELECT(r)_.

Outros comandos
- `\l`, na listagem das bases é possível verificar os privilégios
- `\dn+`, exibir privilégios nos __schemas__

> Quando a coluna "Accesss privileges" está vazia, o objeto possui o privilégio padrão

- `\dp`, políticas de segurança para controle de acesso a registros

Além dos comandos do psql, podemos consultar privilégios existentes em bases, schemas e objetos através de diversas visões do catálogo do sistema e também através de funções de sistema do PostgreSQL

- __a função has_table_privilege(user, table, privilege)__ retorna se determinado usuário possui determinado privilégio na tabela.

### GERENCIANDO AUTENTICAÇÃO

> Controle de autenticação de clientes pelo arquivo __pg_hba.conf__.

__HBA (host based authentication)__
Cada linha é um registro indicando permissão de acesso de uma role, a partir de um endereço IP a determinada base. Se não houver nenhum registro permitindo, nega a conexão.

> Localização: PGDATA/pg_hba.conf

Formaro

~~~text
Tipo de conexão | base de dados | role              | endereço         | método
host              curso           aluno               10.5.15.40/32      md5
host              contabil        +contabilidade      172.22.3.0/24      md5
~~~

- linha 1: conexão IP, na base curso, com usuário aluno, vindo do endereço 10.5.15.40/32 autenticando por md5
- linha 2: qualquer usuário do grupo contabilidade, acessando a base contabil, vindo de qualquer máquina da rede 172.22.3.x e autenticando por md5 é permitido

> sinal __+__, que identifica um grupo

Há diversas opções de valores para cada campo

__Tipo de conexão (Type)__
- localConexões: locais do próprio servidor por unix-socket
- hostConexões: por IP, com ou sem SSL
- hostsslConexões: somente por SSL

__Base de dados (Database)__
- nome da(s) base(s): Uma ou mais bases de dados separada por vírgula
- all: Acesso a qualquer base
- replication: Utilizado exclusivamente para permitir a replicação

__Role (User)__
- role(s): Um ou mais usuários, separados por vírgula
- +grupo(s): Um ou mais grupos, separados por vírgula e precedidos de +
- all Acesso: de qualquer usuário

__Endereço (Address)__
- Um endereço IPv4: Um endereço IPv4 como 172.22.3.10/32
- Uma rede IPv4: Uma rede IPv4 como 172.22.0.0/16
- Um endereço IPv6: Um endereço IPv6 como fe80::a00:27ff:fe78:d3be/64
- Uma rede IPv6: Uma rede IPv6 como fe80::/60
- 0.0.0.0/0: Qualquer endereço IPv4
- ::/0: Qualquer endereço IPv6
- all: Qualquer IP

> __OBS__: É possível usar nomes de máquinas em vez de endereços IP, porém isso pode gerar problemas de lentidão no momento da conexão, dependendo da sua infraestrutura DNS.

__Método (Method)__
- trust: Permite conectar sem restrição, sem solicitar senha, permitindo que qualquer usuário possa se passar por outro
- md5: Autenticação com senha encriptada com hash MD5
- password: Autenticação com senha em texto pleno
- ldap: Autenticação usando um servidor LDAP
- reject: Rejeita a conexão


> __Quando alterar o pg_hba.conf, é necessário fazer a reconfiguração com pg_ctl reload.__


#### A VISÃO PG_HBA_FILE_RULES

A view pg_hba_file_rules, que exibe o conteúdo do arquivo pg_hba.conf. Além de ser uma maneira prática de consultar as regras do arquivo, possibilitando por exemplo filtrar através de SQL, essa view traz outro grande benefício: __mostrar erros de sintaxe no arquivo mesmo antes de aplicá-los__.


#### Boas práticas

Apresentamos a seguir algumas dicas relacionadas à segurança que podem ajudar na administração do PostgreSQL.
1. Utilize roles de grupos para gerenciar as permissões
Como qualquer outro serviço – não somente bancos de dados –, administrar permissões para grupos e apenas gerenciar a inclusão e remoção de usuários do grupo torna a manutenção de acessos mais simples.
2. Remova as permissões da role public e o schema public se não for utilizá-lo
Retire a permissão de conexão na base de dados, de uso do schema e qualquer privilégio em objetos. Remova também no template1 para remover das futuras bases.
3. Seja meticuloso com a pg_hba.conf
No início de um novo servidor, ou mesmo na criação de novas bases, pode surgir a ideia de liberar todos os acessos à base e controlar isso mais tarde. Não caia nessa armadilha! Desde o primeiro
acesso, somente forneça o acesso exato necessário naquele momento. Sempre crie uma linha para cada usuário em cada base vindo de cada estação ou servidor. 
4. Evite a liberação de acesso a partir de uma rede de servidores de aplicação. 
Melhor utilizar um servidor específico
5. Somente use trust para conexões locais no servidor
6. Documente suas alterações. 
É possível associar comentários a roles. Documente o nome real do usuário, utilidade do grupo, quem e quando solicitou a permissão etc. Também comente suas entradas no arquivo pg_hba.conf. De quem é o endereço IP, estação de usuário ou nome do servidor, quem e quando foi solicitado.
7. Antes de recarregar o arquivo, valide a alteração através da pg_hba_file_rules.
8. Faça backup dos seus arquivos de configuração antes de cada alteração.
 