<p align="center">
  <img src="assets/sprites/ui/logo_matemusica.svg" alt="Logo do Matemúsica" width="520">
</p>

# Matemúsica

Uma aventura educacional 2D em que teoria musical vira história, desafio e ritmo. Preso em um mundo com estética de videogame dos anos 90, o jogador precisa aprender como a matemática organiza o tempo na música para restaurar a Grande Partitura e encontrar o caminho de volta para casa.

O jogo combina narrativa, um tutorial visual, perguntas de múltipla escolha e uma fase rítmica. A proposta é direta: entender o valor das figuras musicais e depois colocar esse conhecimento em prática no compasso.

---

## Índice

- [Comece a jogar](#comece-a-jogar)
- [A história](#a-história)
- [A jornada](#a-jornada)
- [Como jogar](#como-jogar)
- [O que você aprende](#o-que-você-aprende)
- [Identidade do jogo](#identidade-do-jogo)
- [Estado atual](#estado-atual)
- [Tecnologia](#tecnologia)
- [Créditos](#créditos)

---

## Comece a jogar

O projeto ainda não possui uma build distribuída. Para jogar a versão atual, é necessário ter o [Godot Engine 4.7](https://godotengine.org/download/) instalado.

```bash
git clone https://github.com/LS-PLuka/matematica-musical.git
cd matematica-musical
```

Abra o arquivo `project.godot` no Godot e pressione **F5** ou use o botão **Executar Projeto** no canto superior direito do editor.

O jogo abre no menu principal. Selecione **Jogar** para iniciar a transmissão.

---

## A história

Tudo começa com um disco de vinil e um aparelho antigo. Ao tentar descobrir se aquela tecnologia ainda funciona, o jogador é transportado para um universo retrô onde bits, beats e compassos fazem parte da mesma linguagem.

É lá que surge o **Maestro Bit**. A Grande Partitura está quebrada e, sem ela, o tempo daquele mundo deixou de funcionar como deveria. Para restaurá-la, não basta decorar notas: será preciso compreender a lógica por trás das figuras musicais, resolver os desafios do maestro e provar que teoria também pode virar ritmo.

> “A matemática organiza os números da mesma forma que a música organiza o tempo.”

---

## A jornada

```text
Abertura
   ↓
Prólogo
   ↓
Tutorial com o Maestro Bit
   ↓
Quiz de teoria musical
   ↓
Desafio rítmico
   ↓
Epílogo e créditos
```

Cada etapa prepara a próxima. O tutorial apresenta as figuras musicais com uma analogia visual; o quiz verifica se as relações ficaram claras; e o rhythm game transforma o conteúdo aprendido em coordenação e tempo de resposta.

---

## Como jogar

### Navegação e diálogos

| Ação | Controle |
|---|---|
| Navegar pelos menus e alternativas | Setas |
| Confirmar uma opção / avançar | `Enter` ou `Espaço` |
| Pular a abertura | `Esc` |
| Acelerar os créditos | Segurar `Enter` ou `Espaço` |
| Encerrar os créditos | `Esc` ou clique esquerdo |

### Quiz

O quiz possui seis perguntas, divididas entre os níveis iniciante, médio e avançado. Escolha uma das três alternativas e use a dica quando precisar. Uma resposta errada não encerra a partida: o Maestro Bit explica o erro e permite uma nova tentativa. O desafio só avança quando a resposta correta é encontrada.

### Desafio rítmico

Use as **setas direcionais** ou `WASD` quando cada seta em movimento alcançar sua marca. A pontuação depende da precisão:

| Julgamento | Pontos | O que significa |
|---|---:|---|
| `PERFECT` | 100 | Acerto no centro da janela de tempo |
| `GOOD` | 60 | Bom acerto, próximo do tempo ideal |
| `OK` | 30 | Acerto válido no limite da janela |

A música segue até o fim mesmo que algumas notas sejam perdidas. O objetivo é acompanhar a sequência completa e buscar a maior pontuação possível.

---

## O que você aprende

O conteúdo gira em torno da duração das figuras musicais dentro de um compasso de quatro tempos.

| Figura | Valor trabalhado no jogo | Relação |
|---|---:|---|
| Semibreve | 4 tempos | ocupa o compasso inteiro |
| Mínima | 2 tempos | metade de uma semibreve |
| Semínima | 1 tempo | metade de uma mínima |
| Colcheia | 0,5 tempo | metade de uma semínima |

As perguntas não cobram apenas memorização. Elas combinam soma, divisão e composição de compassos para mostrar que uma sequência musical também pode ser lida como uma estrutura matemática.

---

## Identidade do jogo

**Matemúsica** usa a linguagem visual de uma transmissão antiga: pixel art, fontes de arcade, cores synthwave, distorção de VHS e transições inspiradas em televisores de tubo. A trilha e os efeitos sonoros não são decoração — conduzem a abertura, o desafio rítmico e o encerramento da experiência.

O texto mistura referências musicais e digitais porque esse é o ponto de encontro do jogo. Para o Maestro Bit, uma partitura quebrada se parece com um sistema fora de sincronia; para o jogador, aprender ritmo é quase como entender o código que mantém aquele mundo funcionando.

---

## Estado atual

O fluxo principal está implementado do menu aos créditos e forma uma experiência curta, linear e completa.

Limitações conhecidas desta versão:

- não há executável publicado; o projeto precisa ser aberto pelo Godot;
- a partida não possui seleção de dificuldade ou de música;
- não existe tela de pausa nem configuração de volume;
- a pontuação do desafio rítmico não é salva entre partidas;
- o jogo foi pensado para teclado e ainda não possui suporte dedicado a controle.

Essas limitações são explícitas porque esta versão funciona como uma experiência educacional fechada, não como uma plataforma de fases ou músicas expansível pelo jogador.

---

## Tecnologia

| Tecnologia | Papel |
|---|---|
| Godot Engine 4.7 | engine, cenas, interface e execução do jogo |
| GDScript | narrativa, quiz, transições e mecânicas rítmicas |
| OGV, MP3 e SVG | vídeo, trilha, efeitos e identidade visual |
| Shader 2D | efeito de CRT/VHS aplicado à apresentação |

O jogo roda com o renderer de compatibilidade do Godot e usa apenas recursos locais. Não há servidor, cadastro, conexão com internet ou coleta de dados durante a partida.

---

## Créditos

| Área | Responsáveis |
|---|---|
| Direção de jogo | Gabriel Cassiano e Lucas Cury |
| Programação | Daniel Custódio, Gianluca Zocarato, João Vitor Simões e Pedro Luka Silva |
| Arte e animação | Matheus Henrique Nascimento |
| Música e sound design | Gabriel Cassiano |
| Roteiro e pedagogia musical | Gabriel Cassiano e Lucas Cury |

Projeto educacional desenvolvido com agradecimentos à **FATEC São Sebastião** e à **Expo Game Jam 2026**.
