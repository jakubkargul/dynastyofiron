# player_unit.gd
# Player controller for the top-down 3D overworld.
# Attach this to a CharacterBody3D node (the player_unit.tscn root).
#
# How movement works:
#   WASD input is read each physics frame and turned into a direction
#   vector on the XZ plane (Y is up in Godot 3D). That direction is
#   multiplied by BASE_SPEED and by whatever terrain speed multiplier
#   the player is currently standing on. The result is passed to
#   move_and_slide(), which handles collisions with the world.
#
# How terrain modifies speed:
#   The player has a child Area3D node called "TerrainDetector".
#   Terrain regions are Area3D nodes placed in the world, each with a
#   script or metadata key called "speed_multiplier" (float) and a
#   "region_name" (String). When the player's detector enters a terrain
#   area, we read those values. Roads might be 1.3 (faster), forests
#   0.6 (slower), mountains 0.4 (much slower). If the player isn't
#   overlapping any terrain area, the multiplier defaults to 1.0.
#
# Scene tree expected:
#   player_unit (CharacterBody3D) — this script
#     ├── CollisionShape3D           — physics body shape
#     ├── MeshInstance3D             — the visible model
#     └── TerrainDetector (Area3D)   — detects terrain regions
#           └── CollisionShape3D     — small shape at player's feet

extends CharacterBody3D

# --- Signals ---
# Emitted when the player walks into a different named region.
# world_map.gd or a HUD can connect to this to update the UI or trigger events.
signal region_changed(new_region: String)

# --- Constants ---
# Base movement speed in units per second before terrain modifies it.
const BASE_SPEED: float = 8.0

# --- State ---
# Current terrain modifier. Updated by TerrainDetector area overlaps.
var _terrain_speed_multiplier: float = 1.0

# Name of the region the player is currently in. Empty string means wilderness / no region.
var _current_region: String = ""

# Reference to the child Area3D. Cached in _ready() so we don't look it up every frame.
@onready var _terrain_detector: Area3D = $TerrainDetector


func _ready() -> void:
	# Connect the TerrainDetector's signals to our handlers.
	_terrain_detector.area_entered.connect(_on_terrain_entered)
	_terrain_detector.area_exited.connect(_on_terrain_exited)


func _physics_process(delta: float) -> void:
	# --- Pause check ---
	# When TimeSystem is paused (encounter, menu), the player cannot move.
	if TimeSystem.paused:
		velocity = Vector3.ZERO
		return

	# --- Read input ---
	# Build a direction vector from WASD. This uses Godot's Input Map,
	# which expects these actions to be defined in Project Settings > Input Map:
	#   "move_forward"  -> W
	#   "move_back"     -> S
	#   "move_left"     -> A
	#   "move_right"    -> D
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_back")

	# Convert 2D input to 3D world direction on the XZ plane.
	# In Godot 3D: X is right, Z is forward/back (negative Z is "into" the screen),
	# Y is up. For a top-down camera looking down the Y axis, WASD maps to XZ.
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)

	# Normalize so diagonal movement isn't faster than cardinal movement.
	if direction.length() > 1.0:
		direction = direction.normalized()

	# --- Apply speed ---
	# Final speed = base * terrain modifier.
	var speed: float = BASE_SPEED * _terrain_speed_multiplier
	velocity = direction * speed

	# --- Move ---
	# move_and_slide() uses the velocity we just set, handles collisions,
	# and slides along walls and obstacles.
	move_and_slide()


# --- Terrain detection callbacks ---

func _on_terrain_entered(area: Area3D) -> void:
	# Read the terrain's speed multiplier. Terrain areas should have this
	# as metadata (set in the editor Inspector under "Meta" at the bottom)
	# or as an exported variable on their script.
	if area.has_meta("speed_multiplier"):
		_terrain_speed_multiplier = area.get_meta("speed_multiplier")

	# Check if this is a named region.
	if area.has_meta("region_name"):
		var new_region: String = area.get_meta("region_name")
		if new_region != _current_region:
			_current_region = new_region
			region_changed.emit(_current_region)


func _on_terrain_exited(area: Area3D) -> void:
	# When leaving a terrain area, check if we're still inside another one.
	# get_overlapping_areas() returns all areas the detector currently touches.
	# NOTE: The exiting area may still be in the list during this callback,
	# so we must filter it out to avoid using stale data.
	var overlapping := _terrain_detector.get_overlapping_areas()
	overlapping.erase(area)

	if overlapping.is_empty():
		# No terrain areas — back to default.
		_terrain_speed_multiplier = 1.0
		if _current_region != "":
			_current_region = ""
			region_changed.emit(_current_region)
	else:
		# Still inside at least one area. Use the last one entered
		# (top of the array) as the active terrain.
		var active: Area3D = overlapping.back()
		if active.has_meta("speed_multiplier"):
			_terrain_speed_multiplier = active.get_meta("speed_multiplier")
		if active.has_meta("region_name"):
			var region: String = active.get_meta("region_name")
			if region != _current_region:
				_current_region = region
				region_changed.emit(_current_region)
