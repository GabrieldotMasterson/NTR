extends KinematicBody2D

export var speed := 600.0
export var gravity := 4500.0
export var jump_strengths := [1400.0, 1000.0]
export var knockback_force := 8000.0
export var knockback_up_force := 800.0
export var knockback_friction := 0.7  # Reduzido para menos lentidão
export var knockback_min_speed := 50.0  # Velocidade mínima para sair do knockback
export var damage_knockback_force := 6000.0  # Corrigido valor zerado

signal hurt

export var controls: Resource = null

var jump_number := 0
var velocity := Vector2.ZERO
var knockback_velocity := Vector2.ZERO
var is_invulnerable := false
var invulnerability_time := 0.3
var knockback_timer := 0.0
var max_knockback_time := 1.0  # Tempo máximo de knockback para evitar bugs

onready var skin := $JerrySkin


func _ready() -> void:
	if not controls:
		set_physics_process(false)


func _physics_process(delta: float) -> void:
	var horizontal_direction := Input.get_axis(controls.move_left, controls.move_right)
	
	# Aplica knockback primeiro
	if knockback_velocity != Vector2.ZERO:
		knockback_timer += delta
		knockback_velocity.x *= knockback_friction
		knockback_velocity.y += gravity * delta
		
		# Força saída do knockback se ficou muito tempo ou muito lento
		if (abs(knockback_velocity.x) < knockback_min_speed and is_on_floor()) or knockback_timer > max_knockback_time:
			knockback_velocity = Vector2.ZERO
			knockback_timer = 0.0
			return
		
		knockback_velocity = move_and_slide(knockback_velocity, Vector2.UP, false, 4, 0.785398, false)
		
		# Se ainda há knockback, não aplica movimento normal
		if knockback_velocity != Vector2.ZERO:
			skin.velocity = knockback_velocity
			return
		else:
			knockback_timer = 0.0
	
	# Movimento normal
	velocity.x = horizontal_direction * speed
	velocity.y += gravity * delta
	
	var is_jumping := Input.is_action_just_pressed(controls.jump)
	var is_jump_cancelled := Input.is_action_just_released(controls.jump) and velocity.y < 0.0
	
	if is_jumping and jump_number < jump_strengths.size():
		velocity.y = -jump_strengths[jump_number]
		jump_number += 1
	elif is_jump_cancelled:
		velocity.y = 0.0
	elif is_on_floor():
		jump_number = 0
	
	velocity = move_and_slide(velocity, Vector2.UP, false, 4, 0.785398, false)
	skin.velocity = velocity
	
	# Verifica colisões com tiles de dano
	check_damage_collisions()


func check_damage_collisions() -> void:
	# Só verifica dano se não estiver em knockback/invulnerável
	if is_invulnerable or knockback_velocity != Vector2.ZERO:
		return
	
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision and collision.collider is TileMap:
			var tilemap = collision.collider as TileMap
			# Verifica se o tilemap está na camada 2
			if tilemap.collision_layer & 2:  # Verifica o bit da camada 2
				handle_damage_from_tilemap(collision, tilemap)


func handle_damage_from_tilemap(collision: KinematicCollision2D, tilemap: TileMap) -> void:
	# Obtém a posição da colisão no mundo
	var collision_position = collision.position
	
	# Converte para coordenadas do tilemap
	var tile_pos = tilemap.world_to_map(collision_position)
	
	# Obtém o tile na posição da colisão
	var tile_id = tilemap.get_cellv(tile_pos)
	
	# Se existe um tile nessa posição (não é -1), aplica dano
	if tile_id != -1:
		apply_damage_knockback(collision.normal)


func apply_damage_knockback(collision_normal: Vector2) -> void:
	# Inverte a normal para empurrar o personagem para longe do tile
	var knockback_direction = -collision_normal
	
	# Se a colisão foi principalmente vertical, usa direção horizontal baseada na posição atual
	if abs(collision_normal.x) < 0.3:
		# Usa a direção do movimento ou uma direção padrão
		var move_direction = Input.get_axis(controls.move_left, controls.move_right)
		if move_direction == 0:
			move_direction = -1.0 if velocity.x < 0 else 1.0
		knockback_direction = Vector2(move_direction, -0.3).normalized()
	
	# Aplica o knockback
	apply_knockback(knockback_direction, damage_knockback_force)


func apply_knockback(direction: Vector2, custom_force := knockback_force) -> void:
	# Se já está em knockback, não aplica outro
	if knockback_velocity != Vector2.ZERO or is_invulnerable:
		return
	
	emit_signal("hurt")
	
	# Define a velocidade do knockback
	knockback_velocity = direction.normalized() * custom_force
	knockback_velocity.y = -knockback_up_force  # Força para cima
	
	# Reseta a velocidade normal
	velocity = Vector2.ZERO
	
	# Reseta o timer de knockback
	knockback_timer = 0.0
	
	# Ativa invulnerabilidade temporária
	is_invulnerable = true
	
	# Garante que o timer existe antes de usá-lo
	if has_node("InvulnerabilityTimer"):
		$InvulnerabilityTimer.start(invulnerability_time)
	else:
		# Fallback: cria um timer temporário se não existir
		var timer = Timer.new()
		timer.wait_time = invulnerability_time
		timer.one_shot = true
		timer.connect("timeout", self, "_on_InvulnerabilityTimer_timeout")
		add_child(timer)
		timer.start()
		timer.name = "TempInvulnerabilityTimer"


# Função para aplicar knockback a partir de uma posição (útil para inimigos)
func apply_knockback_from_position(source_position: Vector2, force := knockback_force) -> void:
	var direction = (global_position - source_position).normalized()
	# Adiciona um pouco de força vertical
	direction.y = -0.3
	apply_knockback(direction, force)


func _on_InvulnerabilityTimer_timeout() -> void:
	is_invulnerable = false


# Função para verificar se está em knockback
func is_knockback_active() -> bool:
	return knockback_velocity != Vector2.ZERO


# Função para interromper o knockback manualmente
func stop_knockback() -> void:
	knockback_velocity = Vector2.ZERO
	knockback_timer = 0.0


# Função para forçar saída do estado de knockback (útil para checkpoints ou respawn)
func force_stop_knockback() -> void:
	stop_knockback()
	is_invulnerable = false
	if has_node("InvulnerabilityTimer") and $InvulnerabilityTimer.time_left > 0:
		$InvulnerabilityTimer.stop()
	elif has_node("TempInvulnerabilityTimer"):
		$TempInvulnerabilityTimer.stop()


# Chamado quando o nó é removido da cena
func _exit_tree() -> void:
	# Limpa timers temporários se existirem
	if has_node("TempInvulnerabilityTimer"):
		$TempInvulnerabilityTimer.queue_free()


# Função para debug (opcional)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Tecla espaço para debug
		print("Estado - Knockback: ", is_knockback_active(), 
			  " | Invulnerável: ", is_invulnerable,
			  " | Velocidade: ", velocity,
			  " | Knockback Vel: ", knockback_velocity)
