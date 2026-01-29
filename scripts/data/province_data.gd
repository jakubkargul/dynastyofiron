# province_data.gd
# Data container for a province in Dynasty of Iron.
# This is a Godot Resource — create .tres files per province or build in code.
#
# Each province represents a region on the map with economic, military,
# and strategic value. Provinces have owners (clans), produce income,
# supply troops, and can be developed over time.
#
# See GDD section "Province Structure" for full design context.

class_name ProvinceData
extends Resource

# --- Identity ---
@export var province_name: String = ""
# Name of the clan that controls this province. Empty if uncontrolled.
@export var owner_clan: String = ""

# --- Core stats ---
# These map directly to the GDD's province stat table.
# All range 0-100. Higher is better.
@export_group("Province Stats")
@export_range(0, 100) var fertility: int = 50      # Food production, population growth
@export_range(0, 100) var wealth: int = 50          # Tax income, trade value
@export_range(0, 100) var manpower: int = 50        # Recruitment pool size
@export_range(0, 100) var fortification: int = 20   # Defensive strength
@export_range(0, 100) var development: int = 30     # Overall infrastructure

# --- Derived values ---
# These are calculated from the core stats. They represent what the province
# produces each game week (when economy_system ticks).

func get_tax_income() -> int:
	# Weekly tax revenue. Wealth is the main driver, development helps.
	return wealth / 5 + development / 10


func get_food_production() -> int:
	# Weekly food output. Fertility is the main driver.
	return fertility / 5


func get_recruitment_pool() -> int:
	# How many troops can be raised. Manpower drives it, development helps.
	return manpower / 10 + development / 20


func get_defense_strength() -> int:
	# How hard this province is to take by force.
	return fortification + development / 5


# --- Location ---
# World position on the overworld map. Used to place the province node
# and for AI pathfinding (armies march toward province positions).
@export_group("Map")
@export var map_position: Vector3 = Vector3.ZERO

# --- State ---
# Provinces can be damaged by war, improved by investment, or neglected.

@export_group("State")
# Current population satisfaction. Low loyalty = risk of revolt.
@export_range(0, 100) var loyalty: int = 50
# Is the province currently under siege?
@export var under_siege: bool = false


# --- Public API ---

func change_owner(new_clan_name: String) -> void:
	owner_clan = new_clan_name
	# Loyalty drops when ownership changes — the people don't know you yet.
	loyalty = clampi(loyalty - 20, 0, 100)
	EventBus.province_owner_changed.emit(province_name, new_clan_name)


func improve_stat(stat_name: String, amount: int) -> void:
	# Used by development projects. Clamps to 0-100.
	match stat_name:
		"fertility":
			fertility = clampi(fertility + amount, 0, 100)
		"wealth":
			wealth = clampi(wealth + amount, 0, 100)
		"manpower":
			manpower = clampi(manpower + amount, 0, 100)
		"fortification":
			fortification = clampi(fortification + amount, 0, 100)
		"development":
			development = clampi(development + amount, 0, 100)


func change_loyalty(amount: int) -> void:
	loyalty = clampi(loyalty + amount, 0, 100)
