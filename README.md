# Perdido no Mundo da Matemúsica

> Jogo 2D narrativo/rítmico educacional desenvolvido em **Godot 4** com **GDScript**.  
> Estética retrô anos 90 — synthwave, pixel art, CRT/VHS.

---

## Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Tecnologias](#tecnologias)
- [Como Rodar Localmente](#como-rodar-localmente)
- [Estrutura de Pastas](#estrutura-de-pastas)
- [Git Flow — Obrigatório](#git-flow--obrigatório)
- [Convenção de Commits](#convenção-de-commits)
- [Roadmap do Alfa](#roadmap-do-alfa)
- [Regras da Equipe](#regras-da-equipe)

---

## Sobre o Projeto

**Perdido no Mundo da Matemúsica** é um jogo educacional onde o jogador aprende teoria musical através de quizzes e um rhythm game.

O protagonista **Léo** é transportado para um mundo musical e precisa consertar a **Grande Partitura** com a ajuda do **Maestro Bit**.

**Fluxo principal:**
```
Abertura → Menu → Prólogo → Tutorial Musical → Quiz → Rhythm Game → Epílogo → Créditos
```

---

## Tecnologias

| Ferramenta | Versão | Uso |
|---|---|---|
| Godot Engine | 4.x stable | Engine principal |
| GDScript | — | Linguagem de programação |
| Git | — | Controle de versão |
| GitHub | — | Repositório remoto |

---

## Como Rodar Localmente

**Pré-requisitos:** ter o Godot 4 instalado ([download aqui](https://godotengine.org/download)).

```bash
# 1. Clone o repositório
git clone https://github.com/LS-PLuka/matematica-musical.git

# 2. Acesse a pasta
cd matematica-musical

# 3. Abra no Godot
# File > Open Project > selecione a pasta clonada
```

Pressione **F5** no editor para rodar o projeto.

---

## Estrutura de Pastas

```
res://
├── assets/
│   ├── audio/
│   │   ├── music/          ← trilhas musicais
│   │   └── sfx/            ← efeitos sonoros
│   ├── fonts/              ← fontes pixel art / retrô
│   ├── sprites/
│   │   ├── characters/     ← Léo, Maestro Bit
│   │   └── ui/             ← ícones, botões, elementos de interface
│   └── shaders/            ← efeitos CRT, scanlines
├── scenes/
│   ├── core/               ← SceneManager, loading
│   ├── cutscenes/          ← abertura, prólogo, epílogo, créditos
│   ├── gameplay/
│   │   ├── quiz/           ← cenas do sistema de quiz
│   │   └── rhythm/         ← cenas do rhythm game
│   └── ui/                 ← menu principal, HUD, diálogos
├── scripts/
│   ├── autoload/           ← singletons globais (GameManager, AudioManager, SceneManager)
│   ├── gameplay/           ← lógica de quiz e rhythm game
│   └── ui/                 ← scripts de menus e interfaces
└── data/
	└── quizzes/            ← arquivos JSON com perguntas e respostas
```

---

## Git Flow — Obrigatório

Todo o time **obrigatoriamente** segue este fluxo. Nenhuma exceção.

### Estrutura de branches

```
main          → código estável, build do alfa. SOMENTE o Tech Lead faz merge aqui.
develop       → integração contínua. Todo PR precisa de aprovação do Tech Lead.
feature/*     → onde cada integrante desenvolve sua parte.
```

### Fluxo do dia a dia

```bash
# 1. Sempre parta da develop atualizada
git checkout develop
git pull origin develop

# 2. Crie sua feature branch
git checkout -b feature/nome-da-sua-feature

# 3. Desenvolva e commite normalmente
git add .
git commit -m "feat: descrição do que foi feito"

# 4. Suba a branch
git push origin feature/nome-da-sua-feature

# 5. Abra um Pull Request no GitHub apontando para develop
#    Aguarde a revisão e aprovação do Tech Lead
#    NUNCA faça merge você mesmo
```

### Exemplos de nomes de branch

```
feature/menu-principal
feature/sistema-de-quiz
feature/rhythm-game-notas
feature/sistema-dialogo
feature/cena-abertura
feature/audio-manager
```

### Regras de proteção de branch

| Branch | Push direto | Merge sem PR | Quem aprova |
|---|---|---|---|
| `main` | ❌ Bloqueado | ❌ Bloqueado | Tech Lead |
| `develop` | ❌ Bloqueado | ❌ Bloqueado | Tech Lead |
| `feature/*` | ✅ Liberado | — | — |

> **Se tentar dar push direto em `main` ou `develop`, o GitHub vai rejeitar automaticamente.**

---

## Convenção de Commits

Use o padrão **Conventional Commits**. Mensagens fora do padrão serão solicitadas para correção na revisão do PR.

| Prefixo | Quando usar |
|---|---|
| `feat:` | nova funcionalidade |
| `fix:` | correção de bug |
| `chore:` | configuração, setup, dependências |
| `docs:` | documentação |
| `refactor:` | refatoração sem mudar comportamento |
| `style:` | ajuste visual ou formatação de código |
| `test:` | adição ou correção de testes |

**Exemplos reais do projeto:**

```bash
feat: implementa sistema de quiz com multipla escolha
feat: adiciona notas longas no rhythm game
fix: corrige sincronizacao de audio com as notas
chore: configura autoloads GameManager e AudioManager
docs: atualiza README com instrucoes de setup
refactor: extrai logica de pontuacao para classe separada
style: ajusta layout do menu principal para resolucao 1080p
```

**Regras:**
- Escreva no imperativo: "adiciona", "corrige", "remove" — não "adicionando" ou "adicionei"
- Sem ponto final
- Sem acento é ok para evitar problemas de encoding no terminal
- Máximo 72 caracteres na primeira linha

---

## Roadmap do Alfa

O objetivo do alfa é ter o **fluxo principal completo e jogável**. Sem polimento, sem features extras.

| Sprint | Entrega | Branch | Status |
|---|---|---|---|
| 0 | Setup, Git Flow, estrutura de pastas | — | ✅ Concluído |
| 1 | Menu principal funcional | `feature/menu-principal` | 🔄 Em andamento |
| 2 | Sistema de diálogo + prólogo | `feature/sistema-dialogo` | ⏳ Pendente |
| 3 | Tutorial do Maestro Bit | `feature/tutorial-musical` | ⏳ Pendente |
| 4 | Sistema de quiz completo | `feature/sistema-quiz` | ⏳ Pendente |
| 5 | Rhythm game funcional | `feature/rhythm-game` | ⏳ Pendente |
| 6 | Cutscenes: abertura, epílogo, créditos | `feature/cutscenes` | ⏳ Pendente |
| 7 | Integração do fluxo completo | `feature/integracao-alfa` | ⏳ Pendente |
| 8 | Testes, ajustes e build do alfa | — | ⏳ Pendente |

---

## Regras da Equipe

1. **Nunca trabalhe direto em `main` ou `develop`.** Sempre crie uma `feature/*`.
2. **Todo merge passa por PR e aprovação do Tech Lead.** Sem exceção.
3. **Siga a convenção de commits.** PRs com mensagens fora do padrão serão devolvidos.
4. **Mantenha a estrutura de pastas.** Não crie pastas fora da estrutura definida sem discutir com o Tech Lead.
5. **Um PR por feature.** Não acumule várias features em um mesmo PR.
6. **Atualize sua branch antes de abrir PR.**

```bash
git checkout develop
git pull origin develop
git checkout feature/sua-feature
git merge develop   # resolve conflitos localmente antes de abrir o PR
```

7. **Dúvidas técnicas?** Pergunte antes de implementar. É melhor alinhar a arquitetura antes do que refatorar depois.

---

> Projeto desenvolvido como Gamejam educacional.  
> Tech Lead responsável pela aprovação de todos os merges e decisões arquiteturais.
