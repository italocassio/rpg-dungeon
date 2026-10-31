class_name GameCatalog
extends Resource
## Índice raiz de todo o conteúdo do jogo; carregado por GameDB.

@export var balance: BalanceConfig
@export var classes: Array[ClassData] = []
@export var skills: Array[SkillData] = []
@export var items: Array[ItemData] = []
@export var recipes: Array[RecipeData] = []
@export var monsters: Array[MonsterData] = []
@export var dungeons: Array[DungeonData] = []
