@tool
extends EditorPlugin
const DataPanel = preload("res://addons/goblinden_data/data_panel.gd")
var panel: Control
func _enter_tree() -> void:
	panel = DataPanel.new()
	EditorInterface.get_editor_main_screen().add_child(panel)
	panel.hide()
func _exit_tree() -> void:
	if is_instance_valid(panel):
		panel.queue_free()
func _has_main_screen() -> bool:
	return true
func _make_visible(value: bool) -> void:
	if is_instance_valid(panel):
		panel.visible = value
func _get_plugin_name() -> String:
	return "GoblinDen Data"
func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("FileList", "EditorIcons")
func _get_unsaved_status(_for_scene: String) -> String:
	if is_instance_valid(panel) and panel.model.is_dirty():
		return "GoblinDen Data has unsaved changes. Use Save changes or Discard changes in the data tab."
	return ""
func _save_external_data() -> void:
	if is_instance_valid(panel) and panel.model.is_dirty():
		panel.save_changes()
