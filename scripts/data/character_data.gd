# character_data.gd
# Data container for any character in Dynasty of Iron — player or NPC.
# This is a Godot Resource, meaning it can be:
#   - Created in code:   var c = CharacterData.new()
#   - Saved as .tres:    ResourceSaver.save(c, "res://resources/characters/oda.tres")
#   - Edited in the Inspector when saved as .tres
#
# Every named character in the game (player, lords, companions, rivals)
# gets one of these. Troops and unnamed peasants do not.

class_name CharacterData
extends Resource

# --- Identity ---
@export var character_name: String = ""
# Background determines starting conditions. See GDD table:
# "ronin", "peasant", "merchant_son", "minor_noble", "monk", "pirate"
@export var background: String = "ronin"
@export var clan_name: String = ""  # Empty if clanless (ronin, peasant)
@export var is_alive: bool = true

# --- Attributes ---
# Core stats from the GDD. Range 1-20, start around 5-10 depending on background.
# These improve slowly over time through training and experience.
@export_group("Attributes")
@export_range(1, 20) var strength: int = 5       # Melee damage, carry capacity
@export_range(1, 20) var agility: int = 5        # Attack speed, dodge, movement
@export_range(1, 20) var constitution: int = 5   # Health, stamina, disease resistance
@export_range(1, 20) var intelligence: int = 5   # Learning speed, strategy
@export_range(1, 20) var charisma: int = 5       # Persuasion, leadership

# --- Skills ---
# Skills improve through use (fight to raise sword, trade to raise commerce).
# Stored as a dictionary: {"sword": 3, "spear": 1, "trade": 5, ...}
# Missing keys are treated as 0 by consumers.
@export_group("Skills")
@export var skills: Dictionary = {}

# Skill category reference (not stored per character, just for documentation):
# Combat:  "sword", "spear", "bow", "unarmed", "riding"
# Command: "tactics", "logistics", "inspiration", "discipline"
# Social:  "persuasion", "intimidation", "deception", "etiquette"
# Economic:"trade", "farming", "crafting", "stewardship"
# Misc:    "medicine", "literacy", "navigation", "stealth"

# --- Traits ---
# Acquired through actions. Each trait is a string tag.
# Examples: "honorable", "ruthless", "brave", "coward", "ambitious", "content"
# Game systems check for trait presence to apply bonuses/penalties.
@export_group("Traits")
@export var traits: Array[String] = []

# --- Combat stats (derived) ---
# These are calculated from attributes + equipment, not stored directly.
# Helper functions below compute them so combat scripts don't need to.

func get_max_health() -> int:
	# Constitution is the main driver. 50 base + 10 per point.
	return 50 + constitution * 10


func get_max_stamina() -> int:
	# Constitution and agility both contribute.
	return 30 + constitution * 5 + agility * 3


func get_base_damage() -> int:
	# Strength drives raw damage. Weapon damage is added on top by combat scripts.
	return 5 + strength * 2


func get_movement_speed() -> float:
	# Agility makes you faster in combat. Overworld speed is separate (player_unit.gd).
	return 4.0 + agility * 0.3


# --- Skill helpers ---

func get_skill(skill_name: String) -> int:
	# Returns the skill level, or 0 if the character has never used it.
	return skills.get(skill_name, 0)


func improve_skill(skill_name: String, amount: int = 1) -> void:
	# Call this when the character practices a skill.
	# Skills cap at 20 to match the attribute range.
	var current: int = skills.get(skill_name, 0)
	skills[skill_name] = mini(current + amount, 20)


# --- Trait helpers ---

func has_trait(trait_name: String) -> bool:
	return trait_name in traits


func add_trait(trait_name: String) -> void:
	if not has_trait(trait_name):
		traits.append(trait_name)


func remove_trait(trait_name: String) -> void:
	traits.erase(trait_name)
