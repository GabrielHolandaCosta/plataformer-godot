# Plataform 2D Godot 4.0

Jogo de plataforma 2D feito em Godot 4.0, com foco em aventura, exploracao, combate contra inimigos, dialogos narrativos e progressao por fases. O jogador controla o Guardiao, atravessa uma floresta tomada por cinzas e enfrenta criaturas que tentam impedir a restauracao do mundo.

Repositorio: https://github.com/GabrielHolandaCosta/plataformer-godot

## Estado atual

Projeto em desenvolvimento, mas ja com fluxo jogavel completo:

- tela inicial;
- fases conectadas;
- HUD;
- moedas;
- vida;
- checkpoints;
- queda no limbo com respawn;
- dialogos;
- bosses;
- transicoes;
- tela de game over;
- cena final e creditos.

## Historia

A floresta esta adoecendo. As arvores queimam, os animais fogem e uma presenca ligada as cinzas comeca a despertar. O Guardiao precisa atravessar diferentes regioes da floresta, derrotar os inimigos principais e restaurar a vida que ainda resiste.

Durante a jornada, a Raposa guia o jogador, os bosses revelam partes da ameaca maior e o final mostra a floresta restaurada depois da ultima vitoria.

## Fases

### World 01

Primeira fase da floresta. Apresenta o jogador aos sistemas principais:

- movimentacao;
- moedas;
- caixas quebraveis;
- checkpoints;
- plataformas;
- fallzone;
- sinais/dialogos;
- inimigos iniciais;
- boss Vessa.

### World 02

Segunda fase, com progressao mais perigosa e combate contra Khorvan. O objetivo final pode ficar bloqueado ate o boss necessario ser derrotado.

### World 03

Fase de floresta escura/morta, com inimigos adicionais e o boss Necromancer. Depois da derrota do boss, o Flying Obelisk aparece e inicia a transicao de restauracao.

### World 04

Fase final da floresta restaurada. O jogador encontra a Raposa, ve o encerramento narrativo e segue para os creditos finais.

## Personagem principal

O player atual usa o heroi da pasta `assets/hero`.

Animacoes configuradas:

- `idle`;
- `run`;
- `jump`;
- `fall`;
- `hurt`.

Tambem foi criado um spritesheet ajustado para o tamanho jogavel:

```txt
assets/hero/adventurer-player-32x24.png
```

Esse sheet evita tremedeira visual durante corrida e pulo, porque o player nao depende mais de escala fracionada no Godot. O faceset de dialogo do heroi tambem foi atualizado:

```txt
assets/hero/faceset/faceset.png
```

## Sistemas principais

### Movimento

- corrida lateral;
- pulo com corte ao soltar o botao;
- gravidade diferenciada na queda;
- controle no ar;
- bloqueio de movimento durante dialogos e cutscenes.

### Vida e dano

- sistema de vidas globais;
- knockback ao receber dano;
- queda de moedas ao sofrer dano;
- estado `hurt`;
- game over quando a vida chega a zero.

### Checkpoints e respawn

Os checkpoints salvam a posicao de retorno em `Globals.current_checkpoint`. Quando o player cai na fallzone, ele perde vida e volta para o checkpoint ativo. Se nenhum checkpoint foi ativado, volta para o ponto inicial da fase.

### Moedas e pontuacao

- moedas coletaveis;
- contador na HUD;
- score global;
- moedas podem cair quando o player toma dano;
- caixas quebraveis podem soltar moedas.

### HUD

A interface mostra:

- moedas;
- score;
- cronometro;
- barra de vida animada.

### Dialogos

O jogo usa `prefabs/dialog_screen.tscn` e `scripts/dialog_screen.gd` para conversas com:

- Raposa;
- Vessa;
- Khorvan;
- Necromancer;
- placas e sinais.

Os dialogos usam facesets, texto com efeito de digitacao e travam o player quando necessario.

### Bosses

Bosses implementados:

- Vessa;
- Khorvan;
- Necromancer.

Eles possuem dialogos de introducao/derrota, estados de combate, hitboxes, dano, morte e registro em `Globals.bosses_defeated`.

### Transicoes e final

O projeto inclui:

- transicao entre fases;
- bloqueio de goals ate bosses serem derrotados;
- cutscene de restauracao;
- fase final com floresta restaurada;
- tela de creditos.

## Controles

Controles principais:

```txt
Setas esquerda/direita ou input ui_left/ui_right: mover
ui_accept: pular
E: interagir e avancar dialogo
Esc / ui_cancel: pausa, quando disponivel
Toque na tela: suporte a botoes mobile em fases com controles touch
```

O Input Map pode ser ajustado pelo editor do Godot em `Project > Project Settings > Input Map`.

## Como executar

1. Instale o Godot 4.0 ou uma versao 4.x compativel.
2. Clone o repositorio:

```bash
git clone https://github.com/GabrielHolandaCosta/plataformer-godot.git
```

3. Abra o Godot.
4. Importe o arquivo:

```txt
project.godot
```

5. Abra `scenes/title_screen.tscn` e execute a cena pelo editor.

## Estrutura do projeto

```txt
actors/      Personagens, inimigos, bosses e NPCs
assets/      Sprites, tilesets, facesets, fontes, backgrounds e sons
levels/      Fases jogaveis world_01, world_02, world_03 e world_04
prefabs/     Cenas reutilizaveis: moedas, checkpoints, goal, HUD, dialogos etc.
scenes/      Telas principais: title screen, game over, creditos
scripts/     Logica em GDScript
shaders/     Shaders do projeto
sigletons/   Autoloads globais, como Globals e DialogManager
sounds/      Efeitos sonoros e musicas
```

## Arquivos importantes

```txt
project.godot
actors/player.tscn
scripts/player.gd
sigletons/globals.gd
scripts/checkpoint.gd
scripts/goal.gd
scripts/dialog_screen.gd
scripts/world_01.gd
scripts/world_02.gd
scripts/world_03.gd
scripts/world_04.gd
```

## Atualizacoes recentes

- troca completa do player para o heroi em `assets/hero`;
- animacoes novas de idle, run, jump, fall e hurt;
- ajuste de tamanho, colisao, hurtbox e head collider do player;
- correcao do respawn da fallzone para respeitar checkpoints;
- remocao da tremedeira visual do heroi com sheet `32x24`;
- troca do faceset do Guardiao nos dialogos;
- inclusao de fases finais, Necromancer, Flying Obelisk, restauracao e creditos.

## Assets e creditos

O jogo usa assets de terceiros e pacotes gratuitos encontrados dentro da pasta `assets/`. Os creditos finais do jogo listam os pacotes usados e indicam quando autor/licenca foram encontrados nos arquivos locais.

Pacotes citados nos creditos internos:

- Sprite Pack 2;
- Sprite Pack 8;
- Mini FX, Items & UI;
- Seasonal Tilesets;
- Jungle Asset Pack;
- Forest Monsters;
- Martial Hero Asset Pack;
- Monsters Creatures Fantasy;
- Demon Woods parallax pack;
- Dead Forest Asset Pack;
- Dark Fantasy Enemies FREE;
- Flying Forest Enemies FREE;
- Necromancer CreativeKind;
- Skeleton Enemy;
- FlyingObelisk;
- Fox Sprites 2D Pixel;
- Cave Tileset;
- RevMiniPixel font;
- Godot Engine 4.

## Time

- Gabriel Holanda;
- Paulo Sergio;
- Breno Sadoke;
- Jose Rafael;
- Vinicius Kaua;
- Pablo Cafe;
- Victor Milito.

## Licenca

Este repositorio contem codigo do jogo e assets de diferentes pacotes. Antes de redistribuir ou publicar builds comerciais, confira as licencas especificas de cada asset dentro da pasta `assets/` e nos creditos finais do jogo.
