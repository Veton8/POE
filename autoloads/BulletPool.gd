extends Node

const POOL_SIZE := 384

var _pools: Dictionary = {}
var _default_container: Node2D
# Optional override — when a scene (e.g. endless mode) renders into a
# SubViewport, it sets this so pooled bullets parent to its world and
# are picked up by the SubViewport's camera transform. Stale refs
# auto-clear on next access (handles scene-tear-down).
var _world_root: Node2D = null


func _ready() -> void:
	_default_container = Node2D.new()
	_default_container.name = "BulletPoolContainer"
	add_child(_default_container)


func set_world_root(node: Node2D) -> void:
	_world_root = node
	_reparent_all_pooled()


func clear_world_root() -> void:
	_world_root = null
	_reparent_all_pooled()


func _container() -> Node2D:
	if _world_root != null and is_instance_valid(_world_root):
		return _world_root
	_world_root = null
	return _default_container


func _reparent_all_pooled() -> void:
	var c: Node2D = _container()
	for arr_v: Variant in _pools.values():
		var arr: Array = arr_v as Array
		for b: Node2D in arr:
			if not is_instance_valid(b):
				continue
			if b.get_parent() != c:
				_safe_reparent(b, c)


func _safe_reparent(b: Node2D, new_parent: Node) -> void:
	var old: Node = b.get_parent()
	if old != null:
		old.remove_child(b)
	new_parent.add_child(b)


func warm(scene: PackedScene, n: int = POOL_SIZE) -> void:
	var arr: Array = _pools.get(scene, [])
	var c: Node2D = _container()
	for i in n:
		var b: Node2D = scene.instantiate() as Node2D
		if b == null:
			continue
		b.set_meta("pool_scene", scene)
		c.add_child(b)
		_disable(b)
		arr.append(b)
	_pools[scene] = arr


func acquire(scene: PackedScene) -> Node2D:
	var arr: Array = _pools.get(scene, [])
	if arr.is_empty():
		warm(scene, 32)
		arr = _pools[scene]
	if arr.is_empty():
		return null
	var b: Node2D = arr.pop_back()
	var c: Node2D = _container()
	if b.get_parent() != c:
		_safe_reparent(b, c)
	_enable(b)
	return b


func release(b: Node2D) -> void:
	if not is_instance_valid(b):
		return
	_disable(b)
	var scene: PackedScene = b.get_meta("pool_scene", null)
	if scene == null:
		b.queue_free()
		return
	var c: Node2D = _container()
	if b.get_parent() != c:
		_safe_reparent(b, c)
	var arr: Array = _pools.get(scene, [])
	arr.append(b)
	_pools[scene] = arr


func _enable(b: Node2D) -> void:
	b.visible = true
	b.set_process(true)
	b.set_physics_process(true)
	var cs: CollisionShape2D = b.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		cs.set_deferred("disabled", false)


func _disable(b: Node2D) -> void:
	b.visible = false
	b.set_process(false)
	b.set_physics_process(false)
	var cs: CollisionShape2D = b.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs != null:
		cs.set_deferred("disabled", true)
