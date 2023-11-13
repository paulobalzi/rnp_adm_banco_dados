--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cidades; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE cidades (
    id integer NOT NULL,
    nome character varying(50)
);


ALTER TABLE public.cidades OWNER TO postgres;

--
-- Name: cidades_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE cidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cidades_id_seq OWNER TO postgres;

--
-- Name: cidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE cidades_id_seq OWNED BY cidades.id;


--
-- Name: grupos; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE grupos (
    id integer NOT NULL,
    nome character(1)
);


ALTER TABLE public.grupos OWNER TO postgres;

--
-- Name: grupos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE grupos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.grupos_id_seq OWNER TO postgres;

--
-- Name: grupos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE grupos_id_seq OWNED BY grupos.id;


--
-- Name: grupos_times; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE grupos_times (
    idgrupo integer NOT NULL,
    idtime integer NOT NULL
);


ALTER TABLE public.grupos_times OWNER TO postgres;

--
-- Name: jogos; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE jogos (
    id integer NOT NULL,
    idtime1 integer,
    idtime2 integer,
    data timestamp without time zone,
    idcidade integer
);


ALTER TABLE public.jogos OWNER TO postgres;

--
-- Name: jogos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE jogos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.jogos_id_seq OWNER TO postgres;

--
-- Name: jogos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE jogos_id_seq OWNED BY jogos.id;


--
-- Name: times; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE times (
    id integer NOT NULL,
    nome character varying(50),
    historia text
);


ALTER TABLE public.times OWNER TO postgres;

--
-- Name: times_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.times_id_seq OWNER TO postgres;

--
-- Name: times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE times_id_seq OWNED BY times.id;


--
-- Name: v_grupos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW v_grupos AS
    SELECT g.nome AS grupo, t.nome AS "time" FROM ((grupos_times gt JOIN times t ON ((gt.idtime = t.id))) JOIN grupos g ON ((gt.idgrupo = g.id))) ORDER BY g.nome;


ALTER TABLE public.v_grupos OWNER TO postgres;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY cidades ALTER COLUMN id SET DEFAULT nextval('cidades_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY grupos ALTER COLUMN id SET DEFAULT nextval('grupos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY jogos ALTER COLUMN id SET DEFAULT nextval('jogos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY times ALTER COLUMN id SET DEFAULT nextval('times_id_seq'::regclass);


--
-- Data for Name: cidades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY cidades (id, nome) FROM stdin;
1	São Paulo
2	Rio de Janeiro
3	Belo Horizonte
5	Fortaleza
6	Brasilia
7	Recife
8	Natal
9	Manaus
10	Cuiaba
11	Curitiba
12	Porto Alegre
4	Salvador
\.


--
-- Name: cidades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('cidades_id_seq', 12, true);


--
-- Data for Name: grupos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY grupos (id, nome) FROM stdin;
1	A
2	B
3	C
4	D
5	E
6	F
8	H
7	G
\.


--
-- Name: grupos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('grupos_id_seq', 8, true);


--
-- Data for Name: grupos_times; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY grupos_times (idgrupo, idtime) FROM stdin;
1	1
1	33
1	9
1	26
2	8
2	18
2	20
2	24
3	12
3	32
3	23
4	5
4	28
4	6
5	11
5	13
5	7
5	29
6	4
6	31
6	21
6	15
7	3
7	19
7	27
7	14
8	30
8	16
8	17
8	22
3	25
4	2
\.


--
-- Data for Name: jogos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY jogos (id, idtime1, idtime2, data, idcidade) FROM stdin;
\.


--
-- Name: jogos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('jogos_id_seq', 1, false);


--
-- Data for Name: times; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY times (id, nome, historia) FROM stdin;
1	Brasil	Sem dúvidas, a seleção que mais entra pressionada na Copa do Mundo é o Brasil. Jogando em casa, precisando retirar o estigma de que as seleções que ganham a Copa das Confederações nunca vão bem no mundial e precisando acalmar os anseios da população, que não vai aceitar menos que a taça, os canarinhos entrarão em campo precisando se firmar e acabar com as críticas.\nA nova "Família Scolari" já está quase toda formada e restam apenas algumas pequenas dúvidas. No gol, Júlio César quase não joga em seu clube e pode ter sua titularidade ameaçada. Já no setor ofensivo, Fred praticamente não jogou no Fluminense após ser titular e principal artilheiro da seleção no título da Copa das Confederações, e, portanto, ainda há uma vaga para um centroavante.\nAs esperanças estão nos pés de Neymar, que hoje é o grande nome verde e amarelo no futebol mundial, mas ele não é o único. Outros jogadores, como Thiago Silva, Paulinho, Oscar e Hulk também podem ser determinantes em um possível título, já que o jogo coletivo é sempre uma grande arma dos times comandados por Felipão
33	Croacia	Não é a geração de 1998, com Suker e Cia., mas é uma safra de qualidade. Comandada por Mandzukic, Modric e Srna, a Croácia pode pensar pelo menos em passar da fase de grupos. Cair antes disso seria decepcionante. \nO time chega para o torneio depois de passar por um grupo enjoado nas eliminatórias (que contava com Bélgica e Sérvia) e pela respecagem europeia (batendo a Islândia). Mas há males que vem para o bem e agora o time desembarca no Brasil bem mais experiente e testado, além de estar "fechado" com o treinador Niko Kovac.
9	Mexico	Depois de muito suar, o México se garantiu na Copa do Mundo na repescagem, com duas boas vitórias sobre a Nova Zelândia, mas precisa evoluir bastante. E quem disse isso foi o próprio treinador de "La Verde", Miguel Herrera:\n"Sim, nós precisamos melhorar muito mais para a Copa do Mundo. Precisamos melhorar e temos consciência disso, porque sabemos que o nível na Copa é bem maior. Vamos ter que trabalhar muito para evoluir, sem dúvidas".\nAlém de ter ido mal nas Eliminatórias, o time também não foi bem na Copa das Confederações, passou por muitas trocas no comando e conflitos entre comissão técnica e jogadores. Somando isso a uma postura defensiva bem fraca - que beira a irresponsabilidade -, o México vai precisar de muita sorte para não quebrar uma sequencia de cinco participações nas oitavas de final. Atualmente oa Aztecas são o pior time do Grupo A.
26	Camaroes	É o mais tradicional representante da África e, das últimas seis Copas, Camarões pintou em cinco (ficou fora em 2006). É bem verdade que o encanto de 1990 nunca mais se repetiu, mas a equipe que vem ao Brasil é encardida. \nEtoo, claro, é o destaque. Mas Assou-Ekoto, MBia, Emana, Matip e Song ajudam muito a estrela do Chelsea. Até porque, depois de abandonar a equipe o atacante não tem a moral que já teve no passado e tem até junho para reconquistar o grupo. \nAo contário do estereótipo irresponsável dos times do continente, este Camarões é equilibrado e cauteloso. Se conseguir tapar algns buracos no meio e nas laterais, tem tudo para fazer uma boa campanha.
8	Espanha	Vivendo a pior fase da história recente, a Fúria deveria agradecer aos céus pelo fato da Copa ser apenas em junho. Com os seus principais jogadores em baixa ou contundidos, Vicente del Bosque já passou por momentos mais tranquilos. Titular do Real Madrid apenas na Liga dos Campeões, Casillas não tem mais o mesmo prestígio de outrora e passa a ter a titularidade ameaçada por Victor Valdés, que vive seu melhor momento. No meio-campo, Xavi vem sentindo o peso dos 33 anos e começa a ser menos participativo na criação das jogadas, sobrecarregando Iniesta e David Silva. \nPorém, a grande preocupação dos espanhóis fica no ataque. Sem um camisa 9 para chamar de seu, a Espanha precisou "contratar" o brasileiro Diego Costa, artilheiro do Atlético de Madrid, para tentar resolver a falta de gols de seus homens de frente. Faro de gol ele tem, mas será que o seu estilo vai combinar com o tiki-taka?
18	Holanda	No próximo mês de junho, a Holanda vai trazer a última marcha de medalhões que terá a missão de guiar um time em formação: Sneijder, Robben, Kuyt, Nigel De Jong, Huntelaar e Robin van Persie. O último, inclusive, foi artilheiro das Eliminatórias, com 12 gols.\nNo entanto, o intocável 4-3-3 holandês vai trazer novos nomes e provavelmente alguns desses talentos vão estar em gigantes europeus após o Mundial. Leroy Fer, Adan Maher, Jeremain Lens, Luciano Narsingh e Memphis Depay... São tantas opções que o técnico Louis van Gaal deve cometer algumas injustiças. \nO país vem ao Brasil com grandes jogadores, mas um time em formação nos deixa ainda mais incertos do que vai acontecer, ainda mais se tratando de Holanda. A equipe pode voar baixo, ser eficiente, tremer em alguma fase... O que esperar da Laranja Mecânica?
20	Chile	O Chile chega a Copa com um respeito nunca antes visto na história dessa competição. Com o diferenciado Alexis Sánchez vivendo seu melhor momento no Barcelona, o time alia qualidade individual a um esquema de jogo ofensivo e bem interessante. Após fazer um trabalho excepcional na Universidad de Chile, o comandante Jorge Sampaoli vem se mostrando um substituto à altura de Marcelo "Loco" Bielsa.\nO treinador perdeu em sua estreia à frente da Roja (1 a 0 para o Peru), mas logo deu sua cara à equipe e engatou uma sequência arrasadora, com treze jogos de invencibilidade. Destaque para as vitórias sobre Uruguai e Inglaterra, além de um empate diante da campeã mundial Espanha. A série só foi quebrada no último amistoso com a Seleção Brasileira, que venceu por 2 a 1 em Toronto. Nada que tire a confiança do belo time chileno, que, além de Sánchez, se apoia no juventino Vidal para ir longe. 
32	Grecia	Sem muita tradição em Copas do Mundo, a Grécia chega no mundial com a esperança de, finalmente, fazer bonito e passar de fase. O Navio Pirata irá apenas para a terceira participação, não tendo nunca passado da fase de grupos, mas chega embalada após boa campanha nas eliminatórias e vitórias convincentes contra a Romênia nos playoffs.\nMesmo com bons nomes, como Sokratis, o eterno Karagounis e Samaras, a grande esperança grega está nos pés do artilheiro Mitroglou, que vive excelente fase e pode ser o diferencial da seleção. 
29	Honduras	A seleção hondurenha vai para sua terceira Copa do Mundo após uma boa campanha nas Eliminatórias da CONCACAF, que forçou o bicho-papão do continente, o México, a disputar a repescagem. Não tem nomes muito badalados e não vai contar com David Suazo e Julio César De León, seus principais jogadores no passado recente, mas vai buscar surpreender no mundial.\nAs principais esperanças são depositadas em Jerry Bengtson, Wilson Palacios e Maynor Figueroa, além do experiente goleiro Noel Valladares. O amistoso recente contra o Brasil mostrou que a seleção não está a altura de competir com as principais favoritas e se marcar um ponto já vai sair no lucro. 
24	Australia	Garantida em sua terceira Copa do Mundo consecutiva (e apenas a quarta em sua história), a Austrália passou sem grandes sustos pelas Eliminatórias da Ásia - confederação da qual faz parte desde 2006. No entanto, mesmo com a vaga já carimbada, a coisa desandou e o técnico Holger Osieck acabou demitido após uma sequência desastrosa. Derrotas para Japão e China, e humilhantes goleadas de 6 a 0 para Brasil e França. Com a Copa chegando, algo precisava ser feito. \nA Federação Australiana de Futebol apostou em Ange Postecoglou, jovem treinador que vinha fazendo sucesso no campeonato local. A resposta da equipe foi imediata, com o eterno Tim Cahill fazendo o único gol da vitória sobre a Costa Rica. O primeiro objetivo de  Postecoglou é começar a reformular a já envelhecida equipe, pois além de não fazer feio na Copa do Mundo o time também terá que se sair bem na Copa da Ásia de 2015, a ser sediada em casa.
12	Colombia	As esperanças do povo colombiano para a Copa estão lá nas alturas. Ainda mais altas que os morros de Bogotá. É cedo para falar se o time de José Pekerman vai superar a memorável equipe de 1994, que contava com Rincón, Valencia e Valderrama, mas há uma qualidade invejável no grupo.\nNo gol, Faryd Mondragon pode ser o jogador mais velho a disputar uma Copa do Mundo, com 43 anos, caso tome a vaga do titular David Ospina. A defesa conta com o também experiente Yepes, mas há lugar para os jovens e promissores Arias e Medina disputarem uma vaga. Do meio para frente a coisa melhora muito e o time explora bastante os flancos com Cuadrado e Armero, mas sem perder a qualidade no setor mais central com Guarin. Mais avançados, James Rodriguez, Falcao García e Jackson Martínez formam um trio de bastante respeito.\nA qualidade técnica impressiona, mas Pekerman terá que ter muito cuidado para segurar o ímpeto naturalmente ofensivo da equipe. Se todo mundo partir para o ataque e não ficar de olho na retaguarda poderemos ver uma bela seleção dando adeus de forma dolorosa.
25	Costa do Marfim	Os Elefantes da Costa do Marfim já não podem mais serem tachados como surpresa. A equipe é hoje uma das principais seleções da África. E se nas duas Copas em que participou (2006 e 2010) eles não conseguiram passar da primeira fase (vale lembrar que caíram as duas vezes no "grupo da morte"), dessa vez a história pode ser diferente.\nO time do treinador francês Sabri Lamouchi tem peças importantíssimas. Muitos de seus principais jogadores atuam nas grandes equipes da europa - caso de Didier Drogba, Kolo e Yaya Touré, Eboué, Kalou...\nOs marfinenses contam ainda com Gervinho, ex-jogador do Arsenal e que vem fazendo uma temporada acima da média com a camisa da Roma. Vale lembrar que muitos desses jogadores já passaram da casa dos 30 anos de idade e devem ter sua última grande oportunidade de brilhar em uma Copa do Mundo. Sinal de que os elefantes chegarão com fome de bola ao Brasil.
23	Japao	O Japão chega ao quinto Mundial de sua história vivendo o melhor momento do futebol do país. Contando com o talento dos meias Honda e Kagawa e criando disciplina tática, a seleção deve causar problemas. Na última Copa das Confederações, a equipe perdeu os três jogos que disputou, contra Brasil, Itália e México, mas deixou o torneio de cabeça erguida, já que jogou de igual para igual em todas as partidas.\nRecentemente, os nipônicos visitaram a badalada seleção da Bélgica e conquistaram uma bela vitória por 3x2, em Bruxelas. Os asiáticos chegam dispostos a surpreender os favoritos e superar o desempenho na última edição do torneio, quando foram eliminados pelo Paraguai nas oitavas de final. 
5	Uruguai	Atuais campeões da América e semifinalistas em 2010, os uruguaios sofreram mais do que esperavam para confirmar um lugar na Copa. A vaga só veio na repescagem, diante da fragilíssima Jordânia. Mas a sensação para ao sul do Rio Grande do Sul é de que o pior já passou. O time celeste aposta na mística do Maracanazo para repetir o feito de 1950 e chegar ao topo do mundo. Mais que bons agouros, os uruguaios também contam com um time que tem condições de chegar lá.\nCavani e Suárez formam provavelmente a melhor dupla de ataque entre todas as 32 seleções da Copa. Difícil de segurar. Forlán, maior artilheiro da história da Celeste, é uma belíssima opção para Óscar Tabárez. O problema segue sendo a falta de equilíbrio entre o setor ofensivo e o resto do time. Mas se engana quem pensa que o resto do time é fraco. O zagueiro Diego Godín, por exemplo, vive grande momento no Atlético de Madrid. O sonho de repetir 1950 está vivo como nunca.
28	Costa Rica	A Costa Rica está muito empolgada com a ótima participação da seleção tica nas Eliminatórias. Depois de jogar mal na terceira fase (quando perdeu as duas para o México e passou sufoco contra El Salvador), a equipe treinada pelo colombiano Jorge Luís Pinto evoluiu e se classificou sem sustos no hexagonal final da Concacaf. Com direito a quase eliminar os rivais mexicanos na última rodada.\nA Costa Rica quase sempre é armada em um 5-4-1 para fortalecer o sistema defensivo do time, que é ruim, lento e dá muito espaço, principalmente à frente da área. Mas, o que falta atrás sobra na frente, com os experientes Bryan Ruiz, Cristian Bolaños e Álvaro Saborio dando suporte ao ótimo garoto Joel Campbell. Se os adversários não tomarem conta deste ataque, a Costa Rica podem perder pontos preciosos na briga pela classificação, além de tomar um prejuízo no saldo de gols.
6	Inglaterra	Sempre se espera muito dos ingleses, que historicamente mostraram ser apenas uma seleção decente. Segundo dados estatísticos do excelente livro Soccernomics, a Inglaterra entre 1970 e 2007 venceu 67,4% das suas partidas ou seja: dois terços de três partidas. O livro confirma também que a seleção é constante, logo uma boa seleção que costuma se sair melhor do que as outras boas. No entanto, isso não é necessário para ser transformado em títulos, em ser a melhor da Copa do Mundo, por exemplo.\nJoe Hart é um goleiro de ótimos reflexos, mas não vive bom momento. Os laterais Glen Johnson, Walker, Baines e Ashley Cole seriam titulares em várias seleções do mundo. Jagielka e Cahil são dois bons zagueiros. Não se discute a técnica de Gerrard, Lampard e Carrick ou o potencial de Barkley. No entanto, os três primeiros (que são titulares) podem pecar pela falta de velocidade.\nTownsend, do Tottenham, é uma grata surpresa neste ano de 2013 e será muito útil pelos lados do campo. Walcott, que retornou de lesão recentemente, também. Rooney, por fim, é o jogador que mais pode fazer a diferança e as esperanças estão depositadas no Shrek. Sturridge está em excelente fase no Liverpool, mas as atuações pela Inglaterra não correspondem às expectativas do seu faro de gol no Campeonato Inglês. \nPara completar, o English Team caiu no Grupo da Morte da Copa. A classificação não será uma surpresa para a boa, mas imprevisível seleção de Roy Hodgson. A eliminação precoce também não.
2	Italia	Embora a Copa das Confederações tenha deixado uma boa impressão da seleção italiana, um clima de incerteza ronda a Squadra Azzurra a alguns meses da Copa do Mundo e é muito difícil prever o desempenho de um time que sempre muda de postura no meio da competição. Como disse o lendário goleiro Buffon: "A Itália sempre surpreende, seja para o bem ou para o mal".\nSe a Copa fosse hoje, 80% do elenco italiano estaria fechado e o time titular praticamente definido, mas a lateral-esquerda e o ataque ainda são zonas nebulosas. Prandelli cogitou até mesmo o retorno de Totti, mas mudou de ideia e descartou o capitão da Roma. Giuseppe Rossi e Balotelli seria uma ótima dupla de ataque e, provavelmente, será a escolha do treinador, mas o primeiro sofre muitas lesões e o segundo tem um temperamento extremamente volátil.\nPode parecer um absurdo, mas foi bom a Itália cair em um grupo tão difícil. Historicamente o país se comporta melhor quando enfrenta grandes adversários, e ter dois grandes desafios logo de cara vai fazer com que os jogadores estejam focados desde o primeiro minuto. 
11	Suica	Se a Copa fosse hoje... É o que devem pensar diariamente muitos suíços que veem atualmente a mais forte seleção suíça dos últimos 50 anos. A equipe treinada pelo ótimo alemão Ottmar Hitzfeld mostrou isso dominando completamente seu (fraco) grupo nas eliminatórias, conquistando sete vitórias e três empates. Além disso, o bom desempenho em amistosos (vitórias sobre Alemanha, Brasil e Croácia desde 2012) deram à Suíça a inimaginável condição de cabeça-de-chave.\nA fortíssima defesa que bateu o recorde de invencibilidade em Copas do Mundo em 2006 e 2010 já não é tão impenetrável assim (embora tenha tomado apenas seis gols em dez gols nas eliminatórias, quatro em um mesmo jogo, da Islândia!). Mas isso é bom, pois representa que os suíços têm mais talento e têm buscado produzir mais com a bola. \nOs volantes Inler e Behrami levam o entrosamento do Napoli, protegendo a zaga Von Bergen e Djourou e chegando forte à frente. Na linha de meias, muita qualidade com os jovens Shaqiri, Xhaka, Stocker e Mehmedi. Na frente, Seferovic parece estar pronto para assumir os gols. Além disso, ainda tem boas opções de banco como Gelson Fernandes, Barnetta, Dzemaili e Derdiyok. Não é absurdo, no melhor cenário, pensar na Suíça repetindo uma quartas-de-final, seu melhor resultado em Copas (1934, 1938 e 1954).
13	Equador	De volta a Copa do Mundo após ficar ausente em 2010, o Equador chega como franco atirador. O time fez uma campanha regular nas Eliminatórias e, assim como aconteceu antes das Copas de 2002 e 2006, garantiu sua vaga no Mundial com um ótimo retrospecto caseiro, sem sofrer nenhuma derrota em seus domínios. Mas, para a infelicidade de "La Tri", nenhuma cidade-sede da nossa Copa fica em regiões muito acima do nível do mar, onde o seu futebol é bem difrente.\nFelipe Caicedo é um bom ataque e o incansável capitão Antonio Valencia dá um pouco de consistência ao meio-campo, mas é muito pouco. Além disso, o time perdeu um de seus bons atacantes, Christian Benitez, que morreu em julho. 
7	Franca	Por muito pouco a França não teve que assistir a Copa do Mundo pela TV. A Ucrânia deu um susto do tamanha da Torre Eiffel na repescagem, mas o time de Didier Deschamps conseguiu reverter uma derrota de 2 a 0 e com certeza ganhou moral para o Mundial.\nColetivamente a equipe ainda não rendeu tudo o que podia, mas se for feita uma análise individual dos principais talentos, o time tem alguns dos atletas que mais evoluíram nos últimos anos. Ribéry sempre foi um bom jogador, mas agora vive o auge. Giroud ganha cada vez mais confiança a medida em que faz gols no Arsenal e na seleção briga forte com Benzema por uma vaga no ataque. Por fim, a juventude de Varane e Pogba, que completaram 20 anos há pouco mas já são titulares dos gigantes Real Madrid e Juventus. Se Deschamps aproveitar o tempo que tem pela frente para conseguir "dar liga" ao time, a França pode ir longe.
4	Argentina	Engana-se quem olha para o time como Messi e mais dez. De fato, ter o melhor do mundo ajuda. E muito. Mas a Argentina de Alejandro Sabella passa longe da equipe de 1986, que era amparada somente em Maradona. O protagonista de agora tem coadjuvantes mais fortes.\n Sabella tem Di Maria e Aguero em ótima forma. Higuaín foi vice-artilheiro das Eliminatórias e recuperou a confiança ao trocar o Real Madrid pelo Napoli. O elenco é tão forte no setor ofensivo que pode se dar ao luxo de não contar com Carlos Tévez. Na retaguarda, Mascherano é cada vez mais líder de uma defesa que vai se arrumando (foi a segunda melhor das Eliminatórias).
31	Bosnia Herzegovina	A Bósnia fez história ao unir um país e garantir sua primeira competição da história. A estreante em Copas ainda contou com a sorte no sorteio e tem grandes chances de avançar à fase de mata-mata.\nApesar dos 30 gols feitos na Fase de Grupos das Eliminatórias, o time não teve de enfrentar nenhum gigante no seu caminho. Os dois maiores eram a Grécia e Eslováquia. Mesmo assim, a dupla de ataque Ibisevic e Dzeko acabou com a disputa e juntos eles marcaram 18 gols.\nO país ainda conta com outros bons jogadores. O experiente camisa 10, Misimovic, mostra que pode ser útil ao técnico Susic. O capitão Spahic, que joga pelo Bayer Leverkusen, é a referência do inexperiente setor defensivo. Voltando ao meio-campo outros dois bons nomes são Pjanic, da Roma, e Lulic, da Lazio, que também pode jogar na lateral.\nO que pode pesar contra a equipe é a falta de experência. Nos últimos amistosos, contra Argentina, Estados Unidos, Eslovênia, Argélia, País de Gales, México, Irlanda e Brasil, foram três vitórias, mas nenhuma delas foi contra países que vão estar na Copa. Uma das derrotas foi para a Argentina. 
21	Ira	A seleção iraniana aparece vez ou outra na Copa do Mundo. A última vez foi em 2006, quando foi eliminada ainda na primeira fase com apenas um ponto conquistado. Por outro lado, o time do técnico português Carlos Queiroz chega embalado ao Brasil. Os iranianos venceram a tradicional seleção da Coréia do Sul na última rodada das eliminatórias por 1 a 0 e garantiram a vaga com a primeira colocação do grupo asiático. \nAs esperanças de uma campanha que os leve até as oitavas de final estão depositadas nos gols do artilheiro Reza Ghoochannejhad, que divide o protagonismo do time com experiente Javad Nekounam, principal armador de jogadas da equipe. Se esses dois não estiverem em um bom dia a coisa fica preta...
15	Nigeria	As Super Águias chegam ao seu quinto Mundial dispostas a apagar a péssima campanha no Mundial da África do Sul, quando somaram apenas um ponto e terminaram na lanterna do seu grupo. Mas, apesar de credenciada pelo título da Copa Africana das Nações e por uma participação honrosa na última Copa das Confederações, os nigerianos nem de longe lembram a equipe que encantou o mundo na década de 1990.\nCom um time renovado e bastante jovem, a Nigéria tem em Obi Mikel e Moses as principais esperanças para tentar alguma coisa. Um fator preocupante são os problemas de relacionamento entre os jogadores e a federação, que quase deixaram o time fora da Copa das Confederações. 
3	Alemanha	A tricampeã mundial sempre chega à Copa do Mundo como uma das favoritas. Mas dessa vez pode-se dizer que esse favoritismo é ainda maior. Com um elenco jovem e muito promissor, a equipe de Joachim Löw tem a base das duas equipes que disputaram o título da Liga dos Campeões na última temporada.\nJogadores da nova safra como Özil, Götze, Reus, Thomas Müller, Schürrle e Draxler, jogam ao lado dos mais experientes Philipp Lahm, Schweinsteiger, Podolski, Mario Gomez e Klose - que pode se tornar o maior artilheiro de todas as Copas do Mundo, ultrapassando Ronaldo.\nNas eliminatórias, uma campanha impecável garantiu a liderança de seu grupo. Os alemães se classificaram invictos, conquistando 9 vitórias e 1 empate em 10 jogos no período pré-Copa. \nMas nem tudo são flores. Löw pode encontrar problemas para armar o meio-campo da equipe, principalmente na proteção à zaga. Schweinsteiger e Khedira sofreram lesões graves e a previsão é de que só retornem num período bem próximo ao início dos jogos. Para cumprir esse papel, o treinador pode contar ainda com Gundogan, Toni Kroos, e os irmãos (Sven e Lars) Bender. 
19	Portugal	O maior trunfo de Portugal na Copa do Mundo é também seu maior problema. Cristiano Ronaldo mostrou que sua fase exuberante não está a serviço apenas do Real Madrid e carregou o país nas costas para garantir a vaga diante da Suécia. Provável melhor do mundo em 2013, ele hoje teria plena condições de passar por cima de qualquer adversário e dar o primeiro título mundial aos patrícios.\nA questão é que, no altíssimo nível de uma Copa, é difícil alguém resolver sozinho. Romário, em 1994, e Maradona, em 1986, foram protagonistas destacadíssimos, mas tinham por trás equipes que funcionavam. Cristiano Ronaldo sofre com a falta de coadjuvantes de peso. O talentoso João Moutinho e o xerifão Pepe são belos nomes, mas, no geral, o time de Paulo Bento não é nada consistente. É bola no craque e - ai, Jesus! - seja o que Deus quiser. 
27	Gana	As chances de Gana surpreender são grandes. O jovem elenco que foi parado nos pênaltis pelo Uruguai nas quartas de final da Copa do Mundo de 2010 está mais maduro. Nas Eliminatórias, Gana venceu cinco das seis partidas da fase de grupos e passou sem dificuldades. O Egito tentou desafiar as Estrelas Negras no mata-mata, porém não aguentou o tranco. No primeiro jogo, um acachapante seis a um e a volta foi só para cumprir tabela e ver o cara do time, Kevin-Prince Boateng, deixar sua marca.\nAlém do camisa 9 do Schalke 04, o time conta com muitos outros bons nomes. Inkoom é o lateral que leva o time ao ataque com alta velocidade. O quarteto que pode atuar na meio impressiona: o seguro Essien, do Chelsea, o motorzinho da marcação Muntari, do Milan, o veloz Asamoah, da Juventus, e o já comentado Boateng garantem tranquilidade ao treinador Akwasi Appiah. O ataque também traz boas opções: o artilheiro Asamoah Gyan, atual capitão, lidera a negra estrela da África. Ao seu lado podem jogar os irmãos Ayew, do Olympique de Marseille.\nO setor defensivo é o menos forte. Não existe uma referência na marcação desde Samuel Kuffour. Portanto, vai sobrar disposição para evitar que a bola entre e muita técnica e correria para balançar a rede lá na frente.
14	Estados Unidos	Na décima Copa do Mundo da sua história, sétima seguida, os americanos chegam ao Brasil dispostos a mostrar que não entendem apenas de futebol com bola oval. Potência em todas as modalidades esportivas, os Estados Unidos ainda caminham devagar quando o assunto é o soccer.\nTreinados pela lenda alemã Jürgen Klinsmann, campeão da competição em 1990, e com uma liga profissional que cresce em ritmo alucinante graças a craques consagrados como Thierry Henry, os sobrinhos do Tio Sam prometem incomodar em 2014. Dentro das quatro linhas, as esperanças ficam nos pés do capitão Dempsey, do atacante Altidore e do experiente Landon Donovan, maior goleador da história da seleção.\nAlém do sorteio ter sido ingrato pelos adversários, os norte-americanos também tem outro motivo para reclamar: a equipe fará jogos em Natal, Manaus e Recife, o que significa que vai ser a seleção que mais quilometros vai percorrer na primeira fase. O desgaste pode pesar. 
30	Belgica	A Bélgica está nos holofotes da imprensa mundial e tudo leva a crer que continuará estando em junho de 2014. A aclamada "geração belga" classificou a seleção para um Mundial (após dois torneios de ausência) com vários jogadores de muito potencial: Courtois, Mignolet, Kompany, Vertonghen, Fellaini, Witsel, Hazard, De Bruyne, Lukaku, Benteke, entre outros.  Mas eles desembarcarão no Brasil com o status de cabeça-de-chave e com uma pressão grande para ir longe na competição. Aí pode estar o problema...\nÉ indiscutível que a Bélgica tem muito talento e jogadores acostumados a grandes jogos, vários deles no melhor campeonato nacional do mundo, o Inglês. Só que eles vão precisar mostrar que estão prontos para render de cara em uma Copa do Mundo, reconhecidamente uma competição "diferente". Se isso acontecer, a Bélgica pode sim ir longe. Mas caso eles não virem essa chave, não acho impossível os belgas serem a grande decepção do torneio. Outra questão: o time é muito competitivo, mas está longe de jogar um futebol "bonito de se ver" e com grande volume. Com esse cartaz todo, será um desafio produzir contra equipes retrancadas. 
16	Argelia	A Argélia chegou na Copa do Mundo após um disputado playoff final contra Burkina Faso, passando por conta dos gols feitos fora de casa. Na última partida, a torcida argelina lotou o estádio e sete horas antes do jogo começar não havia mais lugar vago, o que motivou as Raposas do Deserto a alcançar o objetivo maior.\nLonge de estar entre as favoritas, as Raposas terão que confiar em Bougherra, Yebda e Feghouli para ter alguma chance, mas a fraqueza de opções será um problema. A Argélia pode se inspirar na seleção de 82, que só não passou de fase por conta do saldo de gols e inclusive bateu a poderosa Alemanha na fase de grupos, mas muito provavelmente o time de hoje não passará da primeira fase.
17	Russia	A Rússia chega a Copa pensando em se recuperar dos vexames recentes. Dos últimos seis mundiais, os russos não se classificaram em três (1998, 2006 e 2010) e foram eliminados na primeira fase nas outras três (em 1990 ainda como União Soviética). Treinada por Fabio Capello desde julho de 2012, a equipe chamou a atenção por ter conseguido se classificar de forma segura no grupo que tinha Portugal.\nCapello formou uma seleção experiente, com vários jogadores que se acostumaram a disputar competições europeias pelo Zenit e pelo CSKA. O goleiro Akinfeev é bom, mas já inspirou mais confiança. A defesa é muito forte fisicamente e segura. O meio-campo sofre um pouco para criar. E o ataque vem dando conta do recado com o artilheiro Kezhakov (está a três gols de se tornar o maior artilheiro russo). Sem dúvida é um trabalho para conseguir passar da primeira fase.
22	Coreia do Sul	A Coreia do Sul vai para a sua oitava Copa do Mundo seguida. Mas já viveu dias melhores. A classificação não foi tranquila e o time demorou para encaixar. Ji Dong-Won, do Sunderland, é a referência na frente. No meio, o capitão Lee Chung-Yong e o promissor Son Heung-Min, do Bayer Leverkusen, têm sido os destaques. \n No geral, a Coreia pinta como um adversário que, dentre os considerados mais fracos, ninguém quer pegar. Difícil dizer que pode tirar Bélgica ou Rússia, mas vai exigir o melhor de seus adversários. 
\.


--
-- Name: times_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('times_id_seq', 33, true);


--
-- Name: pk_cidades; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY cidades
    ADD CONSTRAINT pk_cidades PRIMARY KEY (id);


--
-- Name: pk_grupos; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY grupos
    ADD CONSTRAINT pk_grupos PRIMARY KEY (id);


--
-- Name: pk_grupostimes; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY grupos_times
    ADD CONSTRAINT pk_grupostimes PRIMARY KEY (idgrupo, idtime);


--
-- Name: pk_times; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY times
    ADD CONSTRAINT pk_times PRIMARY KEY (id);


--
-- Name: idx_grupos_nome; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX idx_grupos_nome ON grupos USING btree (nome);


--
-- Name: fk_grupos; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY grupos_times
    ADD CONSTRAINT fk_grupos FOREIGN KEY (idgrupo) REFERENCES grupos(id);


--
-- Name: fk_times; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY grupos_times
    ADD CONSTRAINT fk_times FOREIGN KEY (idtime) REFERENCES times(id);



