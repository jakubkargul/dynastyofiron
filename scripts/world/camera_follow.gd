# camera_follow.gd
# Simple top-down camera that smoothly follows a target node.
# Attach this to a Camera3D in world_map.tscn.
#
# The camera maintains a fixed offset from the target and uses
# lerp for smooth movement. The offset determines the camera angle —
# (0, 15, 10) puts it above and behind for an angled top-down view.

extends Camera3D

# Path to the node this camera follows (set in the editor or tscn).
@export var target_path: NodePath = ""

# Offset from the target position. Adjustable in the editor.
# Y = height above target, Z = distance behind target.
@export var offset: Vector3 = Vector3(0, 15, 10)

# How quickly the camera catches up to the target. Lower = more lag.
@export var follow_speed: float = 5.0

# Cached reference to the target node.
var _target: Node3D = null


func _ready() -> void:
	# Get the target node from the path.
	if target_path:
		_target = get_node_or_null(target_path)

	if _target:
		# Snap to the correct position immediately on start.
		global_position = _target.global_position + offset
		look_at(_target.global_position, Vector3.UP)


func _process(delta: float) -> void:
	if not _target:
		return

	# Calculate desired position based on target + offset.
	var desired_pos: Vector3 = _target.global_position + offset

	# Smoothly interpolate toward the desired position.
	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	# Always look at the target.
	look_at(_target.global_position, Vector3.UP)
