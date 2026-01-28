# clan_data.gd
# Data container for a clan (faction) in Dynasty of Iron.
# This is a Godot Resource — create .tres files per clan or build in code.
#
# Each clan in the game gets one of these: Oda, Takeda, Imagawa, etc.
# Clans own provinces, have leaders, field armies, and hold opinions
# about other clans (and the player).
#
# The clan AI (Phase 7+) will read this data to decide strategy.
# For now it's just a data bag that GameState holds in an array.

class_name ClanData
extends Resource

# --- Identity ---
@export var clan_name: String = ""
# The clan leader. A CharacterData resource.
@export var leader: CharacterData = null

# --- Holdings ---
# Names of provinces this clan controls. Must match ProvinceData.province_name.
@export var held_provinces: Array[String] = []

# --- Military ---
# Total army strength as a simple int. Represents combined troop count.
# Individual army units on the map are separate (ai_army.tscn), but this
# is the clan's total on-paper strength for strategic AI decisions.
@export var total_army_strength: int = 0

# --- Relationships ---
# How this clan feels about other clans. Dictionary of {clan_name: int}.
# Positive = friendly, negative = hostile. Range roughly -100 to +100.
# Missing keys are treated as 0 (neutral) by consumers.
@export var clan_relationships: Dictionary = {}

# How this clan feels about the player specifically.
# Separate from clan_relationships because the player may not have a clan.
@export var player_opinion: int = 0

# --- State ---
# Is this clan still active? Clans can be destroyed through conquest.
@export var is_active: bool = true

# Is the player a vassal of this clan?
@export var player_is_vassal: bool = false


# --- Public API ---

func get_relationship(other_clan_name: String) -> int:
	# Returns opinion of another clan. 0 if no relationship exists yet.
	return clan_relationships.get(other_clan_name, 0)


func change_relationship(other_clan_name: String, delta: int) -> void:
	# Shift opinion of another clan. Clamps to -100..+100.
	var current: int = clan_relationships.get(other_clan_name, 0)
	clan_relationships[other_clan_name] = clampi(current + delta, -100, 100)


func change_player_opinion(delta: int) -> void:
	# Shift this clan's opinion of the player. Clamps to -100..+100.
	player_opinion = clampi(player_opinion + delta, -100, 100)


func is_hostile_to(other_clan_name: String) -> bool:
	# A clan is considered hostile at -50 or below.
	return get_relationship(other_clan_name) <= -50


func is_hostile_to_player() -> bool:
	return player_opinion <= -50


func is_friendly_to_player() -> bool:
	# Friendly at +30 or above. Neutral in between.
	return player_opinion >= 30


func add_province(province_name: String) -> void:
	if province_name not in held_provinces:
		held_provinces.append(province_name)


func remove_province(province_name: String) -> void:
	held_provinces.erase(province_name)
