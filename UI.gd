extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.



onready var dist1 = $UI/distP1
onready var dist2 = $UI/distP2
onready var p1 = $LeftViewportContainer/Viewport/Level/Player1
onready var p2 = $LeftViewportContainer/Viewport/Level/Player2
onready var camad1 = $UI/camadaP1
onready var camad2 = $UI/camadaP2
onready var fundCamad1 = $UI/Panel3
onready var fundCamad2 = $UI/Panel
onready var g1 = $UI/ganhouP1
onready var fg1 = $UI/fundoGanhouP1
onready var g2 = $UI/ganhouP2
onready var fg2 = $UI/fundoGanhouP2

func _ready():
	g1.visible = false
	fg1.visible = false
	g2.visible = false
	fg2.visible = false
	
func fim():
	p1.speed = 0 
	p1.jump_strengths = [0,0]
	p2.speed = 0
	p2.jump_strengths = [0,0]
	
func _process(delta):
	
	fundCamad1.visible = true
	camad1.visible = true
	if p1.position.x > 0 and p1.position.x < 500:
		camad1.text = "CAMADA FISICA"
		
	elif p1.position.x > 4000 and p1.position.x < 4500:
		camad1.text = "CAMADA ENLACE"
	
	elif p1.position.x > 8000 and p1.position.x < 8500:
		camad1.text = "CAMADA REDE"
		
	elif p1.position.x > 12000 and p1.position.x < 12500:
		camad1.text = "CAMADA TRANSPORTE"
		
	elif p1.position.x > 16000 and p1.position.x < 16500:
		camad1.text = "CAMADA APLICAÇÃO"
		
	else:
		fundCamad1.visible = false
		camad1.visible = false
	
	fundCamad2.visible = true
	camad2.visible = true
	if p2.position.x > 0 and p2.position.x < 1000:
		camad2.text = "CAMADA FISICA"
		
	elif p2.position.x > 4000 and p2.position.x < 5000:
		camad2.text = "CAMADA ENLACE"
	
	elif p2.position.x > 8000 and p2.position.x < 9000:
		camad2.text = "CAMADA REDE"
		
	elif p2.position.x > 12000 and p2.position.x < 13000:
		camad2.text = "CAMADA TRANSPORTE"
		
	elif p2.position.x > 16000 and p2.position.x < 17000:
		camad2.text = "CAMADA APLICAÇÃO"
		
	else:
		fundCamad2.visible = false
		camad2.visible = false
	
	if p2.position.x > 20000: 
		p1.visible = false
		fim()
		g2.visible = true
		fg2.visible = true
	else: 	dist1.text = "distancia: " +str(int(p1.position.x))
		
	if p1.position.x > 20000: 
		p2.visible = false
		fim()
		g1.visible = true
		fg1.visible = true
		
	else: dist2.text = "distancia: " +str(int(p2.position.x))
		
		
