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
