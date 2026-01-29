# time_system.gd
# Global time system for Dynasty of Iron.
# Register this as an Autoload named "TimeSystem" in Project Settings.
#
# Tracks hours, days, and weeks. Runs continuously in real-time,
# can be paused or sped up. Emits signals when time milestones pass
# so other systems can react without polling.

extends Node

# --- Signals ---
# Other scripts connect to these to react to time passing.
signal hour_passed(hour: int)
signal day_passed(day: int)
signal week_passed(week: int)

# --- Constants ---
# Tune these to control how fast game time flows.
# At default: 1 real second = 1 game hour, so a full day takes 24 real seconds.
const HOURS_PER_DAY: int = 24
const DAYS_PER_WEEK: int = 7
const DEFAULT_SECONDS_PER_HOUR: float = 1.0

# --- State ---
# Current time. These only go up (hour wraps within a day, day wraps within a week).
var hour: int = 6          # Start at dawn (hour 6 of 0-23)
var day: int = 1           # Day of the current week (1-7)
var total_days: int = 0    # Running count of days elapsed, never resets
var week: int = 1          # Running count of weeks elapsed

# Time flow control.
var paused: bool = false
var time_scale: float = 1.0  # Multiplier: 2.0 = double speed, 0.5 = half speed

# Internal accumulator — tracks fractional seconds between frames.
var _accumulator: float = 0.0


func _ready() -> void:
	# Nothing to set up yet. The system starts running immediately.
	pass


func _process(delta: float) -> void:
	if paused:
		return

	# Accumulate real time, scaled by time_scale.
	_accumulator += delta * time_scale

	# How many real seconds equal one game hour (adjusted by time_scale already
	# being folded into the accumulator).
	var secs_per_hour: float = DEFAULT_SECONDS_PER_HOUR

	# Advance hours as long as enough time has built up.
	while _accumulator >= secs_per_hour:
		_accumulator -= secs_per_hour
		_advance_hour()


# --- Public API ---
# Call these from other scripts: TimeSystem.pause() / TimeSystem.resume() etc.

func pause() -> void:
	paused = true


func resume() -> void:
	paused = false


func set_time_scale(scale: float) -> void:
	# Clamp to sane range. 0 would freeze time (use pause for that).
	time_scale = clampf(scale, 0.1, 10.0)


func get_time_string() -> String:
	# Returns something like "Day 3, 14:00 (Week 2)"
	return "Day %d, %02d:00 (Week %d)" % [day, hour, week]


func get_total_hours() -> int:
	# Useful for durations and comparisons.
	return total_days * HOURS_PER_DAY + hour


# --- Internal ---

func _advance_hour() -> void:
	hour += 1

	# Check for day rollover BEFORE emitting, so we emit the correct hour (0, not 24).
	if hour >= HOURS_PER_DAY:
		hour = 0
		_advance_day()

	hour_passed.emit(hour)


func _advance_day() -> void:
	day += 1
	total_days += 1
	day_passed.emit(total_days)

	if day > DAYS_PER_WEEK:
		day = 1
		_advance_week()


func _advance_week() -> void:
	week += 1
	week_passed.emit(week)
