# 🎮 Platform 2D (Godot 4)

![Godot](https://img.shields.io/badge/Godot-4.x-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-Game%20Logic-355570?style=for-the-badge)
![Status](https://img.shields.io/badge/status-em%20desenvolvimento-orange?style=for-the-badge)

Um jogo de plataforma 2D feito no **Godot 4**, com foco em aprendizado prático de game dev: movimentacao, combate, checkpoints, UI/HUD, transicoes de fase e design de nivel.

---

## ✨ Visao geral

Neste projeto, o player percorre fases com obstaculos, inimigos e colecionaveis.  
O objetivo e avancar entre mundos, sobreviver aos perigos e acumular pontuacao.

---

## 🕹️ Funcionalidades atuais

- **Movimento fluido do personagem** com corrida, pulo e controle no ar
- **Sistema de dano e knockback** ao colidir com inimigos/perigos
- **Sistema de vidas** com respawn do jogador
- **Checkpoints funcionais** para retorno durante a fase
- **Inimigos de patrulha** e perigos como espinhos
- **Plataformas moveis e que caem**
- **Coleta de moedas e sistema de score**
- **HUD completo** (vidas, moedas, score e cronometro)
- **Sistema de dialogo**
- **Pausa de jogo** (menu de pause)
- **Transicao entre cenas/fases** com efeito visual
- **Shader de nuvens/background** para dar vida ao cenario

---

## 🎛️ Controles

> Os controles podem variar conforme o mapeamento no Godot, mas o padrao atual e:

- `← / →` : mover personagem
- `Espaco` (`ui_accept`) : pular
- `E` (`interact` / `advance_message`) : interagir e avancar dialogo
- `Esc` (`ui_cancel`) : abrir menu de pausa

---

## 🧱 Estrutura do projeto

```txt
actors/      # player, inimigos e elementos relacionados
assets/      # sprites, tilesets, backgrounds e recursos visuais
levels/      # fases (world_01, world_02, ...)
prefabs/     # cenas reutilizaveis (checkpoint, plataformas, goal, etc.)
scripts/     # logica principal em GDScript
shaders/     # shaders do projeto
sigletons/   # autoloads globais (Globals, DialogManager)
```

---

## 🚀 Como executar

1. Instale o **Godot 4.x**  
2. Clone o repositorio:

```bash
git clone https://github.com/GabrielHolandaCosta/plataformer-godot
```

3. Abra o Godot e clique em **Import**
4. Selecione a pasta do projeto
5. Rode a cena principal pelo editor

---

## 👥 Time

- Gabriel Holanda Costa
- Pablo de Omena Café
- Paulo Junior
- José Rafael Oliveira
- Victor Milito

GitHub: [@GabrielHolandaCosta](https://github.com/GabrielHolandaCosta)

---

## 📌 Status do projeto

🚧 **Em desenvolvimento**  
Projeto em evolucao continua para estudo, experimentacao e melhoria de arquitetura/gameplay.
