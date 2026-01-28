# world_map.gd
# Example of a script that listens to the global TimeSystem.
# Attach this to the root node of world_map.tscn.
#
# Demonstrates how any script in the project can react to time
# passing without importing or referencing the time system directly —
# it just connects to the autoload's signals.

extends Node3D


func _ready() -> void:
	# Connect to TimeSystem signals.
	# TimeSystem is available everywhere because it's an autoload.
	TimeSystem.hour_passed.connect(_on_hour_passed)
	TimeSystem.day_passed.connect(_on_day_passed)
	TimeSystem.week_passed.connect(_on_week_passed)


func _on_hour_passed(hour: int) -> void:
	# Called every game hour. Use this for frequent updates:
	# - Moving AI units along their paths
	# - Checking encounter proximity
	# - Updating lighting / sky color
	print("[WorldMap] Hour: %s" % TimeSystem.get_time_string())


func _on_day_passed(total_days: int) -> void:
	# Called once per game day. Use this for daily ticks:
	# - Province income collection
	# - Food consumption
	# - NPC schedule changes
	print("[WorldMap] A new day has begun. Total days elapsed: %d" % total_days)


func _on_week_passed(week: int) -> void:
	# Called once per game week. Use this for slower systems:
	# - Clan AI strategic decisions
	# - Market price shifts
	# - Reputation decay / growth
	print("[WorldMap] Week %d has started." % week)
