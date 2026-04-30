extends Node

const POOL_SIZE := 256

var _pools: Dictionary = {}
var _container: Node2D

func _ready() -> void:
	_container = Node2D.new()
	_container.name = "BulletPoolContainer"
	add_child(_container)

func warm(scene: PackedScene, n: int = POOL_SIZE) -> void:
	var arr: Array = _pools.get(scene, [])
	for i in n:
		var b: Node2D = scene.instantiate() as Node2D
		if b == null:
			continue
		b.set_meta("pool_scene", scene)
		_container.add_child(b)
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
