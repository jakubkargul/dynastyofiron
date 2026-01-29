# world_map.gd
# Main overworld scene controller for Dynasty of Iron.
# Attach this to the root node of world_map.tscn.
#
# Responsibilities:
#   - Initialize the game state on startup (create test player data)
#   - Connect to TimeSystem signals for world updates
#   - Connect to player signals for region change notifications
#   - Handle encounter results when returning from combat scenes
#   - (Future) Spawn and manage AI units

extends Node3D

# Reference to the player node. Set via @onready.
@onready var _player: CharacterBody3D = $PlayerUnit


func _ready() -> void:
	# --- Initialize game state ---
	# Create a test player character for now.
	# In a real game, this would come from character creation or a save file.
	_initialize_test_game()

	# --- Connect to player signals ---
	if _player:
		_player.region_changed.connect(_on_player_region_changed)

	# --- Connect to TimeSystem signals ---
	TimeSystem.hour_passed.connect(_on_hour_passed)
	TimeSystem.day_passed.connect(_on_day_passed)
	TimeSystem.week_passed.connect(_on_week_passed)

	# --- Connect to EventBus for encounter returns ---
	EventBus.encounter_ended.connect(_on_encounter_ended)

	# --- Handle returning from an encounter ---
	# If we're returning from an encounter scene, process the results.
	if not GameState.encounter_result.is_empty():
		_process_encounter_result()


func _initialize_test_game() -> void:
	# Create a test player character.
	var player_data := CharacterData.new()
	player_data.character_name = "Wandering Ronin"
	player_data.background = "ronin"
	player_data.strength = 7
	player_data.agility = 6
	player_data.constitution = 6
	player_data.intelligence = 5
	player_data.charisma = 4
	player_data.skills = {"sword": 3, "unarmed": 1}
	player_data.traits = []

	# Start the game with just the player — no clans or provinces yet.
	# These will be added in later phases.
	GameState.start_new_game(player_data, [], [])

	print("[WorldMap] Game initialized. Player: %s, Money: %d mon" % [
		GameState.player.character_name,
		GameState.money
	])


func _on_player_region_changed(new_region: String) -> void:
	# Called when the player enters a new terrain region.
	if new_region.is_empty():
		print("[WorldMap] Entered the wilderness.")
	else:
		print("[WorldMap] Entered region: %s" % new_region)


func _on_hour_passed(_hour: int) -> void:
	# Called every game hour.
	# Future uses:
	#   - Update AI unit positions
	#   - Check for random encounters
	#   - Update lighting/sky based on time of day
	pass


func _on_day_passed(total_days: int) -> void:
	# Called once per game day.
	# Future uses:
	#   - Deduct daily expenses (food, wages)
	#   - Update NPC schedules
	#   - Tick province income
	print("[WorldMap] Day %d has begun. Time: %s" % [total_days, TimeSystem.get_time_string()])


func _on_week_passed(week: int) -> void:
	# Called once per game week.
	# Future uses:
	#   - Clan AI strategic decisions
	#   - Market price fluctuations
	#   - Reputation decay/growth
	print("[WorldMap] Week %d has begun." % week)


func _on_encounter_ended(_result: Dictionary) -> void:
	# Called by EventBus when an encounter scene resolves.
	# The scene transition back to world_map will trigger _ready(),
	# which calls _process_encounter_result(). This signal connection
	# is for cases where we might handle it differently in the future.
	pass


func _process_encounter_result() -> void:
	# Apply the results of a completed encounter.
	var result: Dictionary = GameState.encounter_result

	var outcome: String = result.get("outcome", "unknown")
	var loot: int = result.get("loot_money", 0)
	var enemy_id: String = result.get("enemy_unit_id", "")

	match outcome:
		"victory":
			print("[WorldMap] Victory! Gained %d mon." % loot)
			GameState.add_money(loot)
			if enemy_id:
				# TODO: Remove the defeated AI unit from the map
				EventBus.ai_unit_removed.emit(enemy_id)
		"defeat":
			print("[WorldMap] Defeat. The ronin's journey ends... for now.")
			# TODO: Handle player death / game over / heir succession
		"fled":
			print("[WorldMap] Escaped the encounter.")

	# Clear the result so we don't process it again.
	GameState.encounter_result = {}

	# Resume time after the encounter.
	TimeSystem.resume()
