# game_state.gd
# Central runtime state for Dynasty of Iron.
# Register as Autoload named "GameState" in Project Settings.
#
# This is the single source of truth for all persistent game data.
# Other scripts read and write here rather than storing global data
# on themselves. This also serves as the entry point for save/load
# when that system is built later.
#
# Usage:
#   GameState.player  — the player's CharacterData resource
#   GameState.clans   — array of all ClanData in the world
#   GameState.money   — player's current funds
#   GameState.current_encounter — context dict passed to encounter scenes

extends Node

# --- Player ---
# The player's character data. Set during game start / character creation.
var player: Resource = null  # Will be a CharacterData resource

# Player's current money in mon (the base currency).
var money: int = 0

# --- World data ---
# All clans currently in the game. Populated at game start.
var clans: Array = []  # Array of ClanData resources

# All provinces in the game. Populated at game start.
var provinces: Array = []  # Array of ProvinceData resources

# --- Encounter context ---
# Populated by encounter_manager before transitioning to an encounter scene.
# The encounter scene reads this to know who is fighting, what type, etc.
# Cleared when returning to the overworld.
var current_encounter: Dictionary = {}

# Results written by the encounter scene before returning to the overworld.
# world_map.gd reads this on re-entry to apply outcomes.
var encounter_result: Dictionary = {}

# --- Dynasty ---
# The player's heirs. Array of CharacterData resources.
var heirs: Array = []

# The player's spouse. Null if unmarried.
var spouse: Resource = null  # CharacterData


# --- Public API ---

func start_new_game(player_data: Resource, clan_list: Array, province_list: Array) -> void:
	# Called once when a new game begins. Sets up all initial state.
	player = player_data
	clans = clan_list
	provinces = province_list
	money = _get_starting_money(player_data)
	heirs = []
	spouse = null
	current_encounter = {}
	encounter_result = {}


func set_money(amount: int) -> void:
	money = amount
	EventBus.money_changed.emit(money)


func add_money(amount: int) -> void:
	money += amount
	EventBus.money_changed.emit(money)


func remove_money(amount: int) -> bool:
	# Returns true if the player could afford it, false if not enough funds.
	if money >= amount:
		money -= amount
		EventBus.money_changed.emit(money)
		return true
	return false


func setup_encounter(context: Dictionary) -> void:
	# Called by encounter_manager right before scene transition.
	# context should include:
	#   "type": "duel" | "skirmish" | "battle"
	#   "enemy_data": CharacterData or army info
	#   "enemy_unit_id": String — so we can remove the unit on victory
	current_encounter = context
	encounter_result = {}


func resolve_encounter(result: Dictionary) -> void:
	# Called by encounter scenes when combat ends.
	# result should include:
	#   "outcome": "victory" | "defeat" | "fled"
	#   "loot_money": int
	#   "reputation_changes": Dictionary  — {clan_name: int delta}
	#   "enemy_unit_id": String — which overworld unit was involved
	encounter_result = result
	EventBus.encounter_ended.emit(result)


func find_clan(clan_name: String) -> Resource:
	# Look up a clan by name. Returns null if not found.
	for clan in clans:
		if clan.clan_name == clan_name:
			return clan
	return null


func find_province(province_name: String) -> Resource:
	# Look up a province by name. Returns null if not found.
	for province in provinces:
		if province.province_name == province_name:
			return province
	return null


# --- Internal ---

func _get_starting_money(player_data: Resource) -> int:
	# Starting money depends on background. Defaults to a modest amount.
	# Once CharacterData has a background field, this can branch on it:
	#   "merchant_son" -> 500, "ronin" -> 12, "noble" -> 200, etc.
	if player_data and player_data.has_method("get"):
		var bg = player_data.get("background")
		match bg:
			"ronin":
				return 12
			"peasant":
				return 5
			"merchant_son":
				return 500
			"minor_noble":
				return 200
			"monk":
				return 30
			"pirate":
				return 100
			_:
				return 50
	return 50
