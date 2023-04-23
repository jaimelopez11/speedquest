extends Node2D

#Boss Stats
export (float) var health = 3.0
export (float) var speed = 50.0
export (int) var damage = 1
export (int) var projectile_damage = 1
var actual_speed
var slow = 1

#Boss States
enum attack_type {idle,dash,fire,shoot}
export (attack_type) var my_attack = attack_type.idle
export (bool) var passable = false
var jumping = false
#Boss Setup
var rb
var sprite
var sfx
var path: Array = []
var level_navigation: Navigation2D = null
export (PackedScene) var projectile
var timer = 2
var jump_dir = Vector2.ZERO
var moving = false
var collision
var wait = false
export (PackedScene) var stair

onready var line2d = $Line2D


# Called when the node enters the scene tree for the first time.
func _ready():
	rb = $BossBody
	sprite = $BossBody/Sprite
	sfx = $BossBody/BossAudio
	collision = $BossBody/CollisionShape2D
	yield(get_tree(), "idle_frame")
	
	speed = 30
	health = 20
	sprite.animation = "wizard_idle"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	level_navigation = get_parent().get_node("LevelNavigation")
	line2d.global_position = Vector2.ZERO
	if health <= 0:
		death()
	
	actual_speed = speed * slow
	if slow < 1:
		slow+= delta

	if global_position.x > Global.player_position.x:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
	
	#print(wait, timer)
	if wait == false:
		if timer > 0:
			timer-=delta
		else:
			match my_attack:
				0: #Idle
					wait = true
					idle()
					
				1: #Dash
					wait = true
					dash()
					
				2: #Fire
					wait = true
					fire()
					
				3: #Laser
					wait = true
					laser()
					


func _on_RigidBody2D_body_shape_entered(_body_id, body, _body_shape, _local_shape):

	if body.name == "WeaponBody":
		sprite.modulate = Color(1,0,0)
		yield(get_tree().create_timer(.1), "timeout")
		sprite.modulate = Color(1,1,1)
		position -= (Global.player_position - self.position).normalized() * 3
		slow = .75
		take_damage(body.attack_damage)
		
	if "Projectile" in body.name and body.friendly == true:
		sprite.modulate = Color(1,0,0)
		yield(get_tree().create_timer(.1), "timeout")
		take_damage(Global.player_damage)
		sprite.modulate = Color(1,1,1)
		position -= (Global.player_position - self.position).normalized() * 3
		slow = .5

func take_damage(damage_dealt):
	sfx.play_sound(sfx.hitsounds)
	health-=damage_dealt

func death():
	get_parent().get("enemies").erase(self)
	var heart = preload("res://scenes/Heart_Container.tscn").instance()
	heart.position = position
	var new_stair = preload("res://scripts/Stair.tscn").instance()
	new_stair.position = position + Vector2(0,-30)
	get_parent().add_child(new_stair)
	get_parent().add_child(heart)
	queue_free()

func shoot(direction = (Global.player_position - global_position).normalized(), shootPos = position + (Global.player_position - global_position).normalized() * 10):
	var new_projectile = projectile.instance()
	new_projectile.set("friendly", false)
	new_projectile.set("attack_damage", projectile_damage)
	new_projectile.set("provided_velocity", direction)
	new_projectile.set("start_pos", shootPos)
	get_parent().add_child(new_projectile)
	return new_projectile

func choose_attack():
	my_attack = attack_type.values()[ randi()%attack_type.size() ]

func idle():
	
	print("idle")
	randomize()
	choose_attack()
	timer = 0
	#timer = rand_range(2,3)
	wait = false
	
func dash():
	
	print("dash")
	randomize()
	choose_attack()
	timer = .1
	wait = false

	
func laser():
	
	print("fire")
	randomize()
	choose_attack()
	timer = 0
	wait = false

	
func fire():
	var shoot_angle = Vector2.UP
	var strange = rand_range(64,128)
	var wrange = rand_range(.02,.05)
	
	sprite.animation = "wizard_firestart"
	yield(sprite,"animation_finished")
	sprite.animation = "wizard_fire"
	
	for _x in range(64):
		var new_projectile = shoot(shoot_angle.normalized(),global_position + shoot_angle)
		new_projectile.use_sprite.animation = "fire"
		new_projectile.CS.scale *= 4
		shoot_angle = shoot_angle.rotated(deg2rad(strange))
		yield(get_tree().create_timer(wrange), "timeout")
	randomize()
	choose_attack()
	sprite.animation = "wizard_firestop"
	timer = 3
	wait = false

