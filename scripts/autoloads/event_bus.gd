# event_bus.gd
# Global signal hub for Dynasty of Iron.
# Register as Autoload named "EventBus" in Project Settings.
#
# This script contains ONLY signal declarations. No logic.
# Systems emit signals here instead of referencing each other directly.
# Any script can connect to these without knowing who emits them.
#
# Usage:
#   Emit:   EventBus.encounter_started.emit(encounter_data)
#   Listen: EventBus.encounter_started.connect(_on_encounter_started)

extends Node

# --- Encounter signals ---
# Fired by encounter_manager when the player touches an AI unit.
signal encounter_started(context: Dictionary)
# Fired by encounter scenes (duel, skirmish) when combat resolves.
signal encounter_ended(result: Dictionary)

# --- Reputation signals ---
# Fired by reputation_system when any faction opinion changes.
signal reputation_changed(clan_name: String, new_value: int)

# --- Province signals ---
# Fired when a province changes hands (conquest, grant, rebellion).
signal province_owner_changed(province_name: String, new_owner_clan: String)

# --- Economy signals ---
# Fired when the player's money changes for any reason.
signal money_changed(new_amount: int)

# --- Character signals ---
# Fired when the player character dies.
signal player_died()
# Fired when an heir takes over after death.
signal heir_succeeded(heir_data: Resource)

# --- World signals ---
# Fired when an AI unit is removed from the overworld (killed, routed, despawned).
signal ai_unit_removed(unit_id: String)
# Fired when a new AI unit should be spawned on the overworld.
signal ai_unit_spawned(unit_type: String, position: Vector3)
