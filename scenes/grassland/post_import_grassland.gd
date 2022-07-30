extends Node


var compressed_tilemap = TileMap.new()
var mobs_nav_tilemap = TileMap.new()

var tilemap_list = []
var chunk_size = 10 # chunk tiles width/height in tiles
var map_width = 0
var map_height = 0
var map_min_pos = Vector2.ZERO # In tiles
var map_max_pos = Vector2.ZERO # In tiles


# Method to change the scene directly after it is imported by Tiled Map Importer
func post_import(scene):
	print("reimporte " + scene.name + "...")
	
	# generate chunks
	print("generate chunks...")
	generate_chunks(scene)
	
	# Setup map - performace optimisation
	iterate_over_nodes(scene)

	# Compress all tilemaps to one
	compress_tilemaps(scene)

	# Add navigation tilemap for mobs
	# Get TileSet from other TileMap because of changing tileset ids "res://assets/map/map_grassland.tmx::5195" -> 5195
	# Also in every TileMap all TileSets are stored
	var dirtLvl0TileMap : TileMap = scene.find_node("dirt lvl0")
	mobs_nav_tilemap = compressed_tilemap
	mobs_nav_tilemap.tile_set = dirtLvl0TileMap.tile_set
	mobs_nav_tilemap.cell_quadrant_size = 1
	mobs_nav_tilemap.cell_y_sort = false
	mobs_nav_tilemap.cell_clip_uv = true
	mobs_nav_tilemap.cell_size = Vector2(16,16)
	mobs_nav_tilemap.name = "NavigationTileMap"
	mobs_nav_tilemap.visible = false

	# merge all tilemaps and collisionshapes from "ground" together
	remove_collisionshapes_from_tilemap(mobs_nav_tilemap, scene.find_node("ground"))

	# Setup Navigation2D for mobs
	var navigation : Node2D = scene.find_node("navigation")
	var mobs_navigation2d = Navigation2D.new()
	mobs_navigation2d.name = "mobs_navigation2d"
	mobs_navigation2d.visible = false
	navigation.replace_by(mobs_navigation2d, true)
	scene.find_node("mobs_navigation2d").add_child(mobs_nav_tilemap)
	mobs_nav_tilemap.set_owner(scene)



	# Setup Navigation2D for ambient mobs
	var ambient_mobs_navigation : Node2D = scene.find_node("ambientMobs navigation")
	var ambient_mobs_navigation2d = Navigation2D.new()
	ambient_mobs_navigation2d.name = "ambient_mobs_navigation2d"
	ambient_mobs_navigation.replace_by(ambient_mobs_navigation2d, true)

	# Add navigation polygon for ambient mobs
	var navigation_polygon_instance = NavigationPolygonInstance.new()
	var navigation_polygon = NavigationPolygon.new()

	var tile_polygon = PoolVector2Array()
	var rec = compressed_tilemap.get_used_rect()

	var topleft = rec.position * 16
	var topright = Vector2(rec.end.x, rec.position.y) * 16
	var bottomleft = Vector2(rec.position.x, rec.end.y) * 16
	var bottomright = Vector2(rec.end.x, rec.end.y) * 16
	tile_polygon.append(topleft)
	tile_polygon.append(topright)
	tile_polygon.append(bottomright)
	tile_polygon.append(bottomleft)
	navigation_polygon.add_outline(tile_polygon)
	navigation_polygon.make_polygons_from_outlines()
	navigation_polygon_instance.navpoly = navigation_polygon
	ambient_mobs_navigation2d.add_child(navigation_polygon_instance)
	navigation_polygon_instance.set_owner(scene)


	# Setup entitylayer to YSorts
	var entitylayer : Node2D = scene.find_node("entitylayer")
	var ySortEntities = YSort.new()
	ySortEntities.name = entitylayer.name
	entitylayer.replace_by(ySortEntities, true)
	# Setup playerlayer
	var playerlayer : Node2D = scene.find_node("playerlayer")
	var ySortPlayer = YSort.new()
	ySortPlayer.name = playerlayer.name
	playerlayer.replace_by(ySortPlayer, true)
	# Setup mobslayer
	var mobslayer : Node2D = scene.find_node("mobslayer")
	var ySortMobs = YSort.new()
	ySortMobs.name = mobslayer.name
	mobslayer.replace_by(ySortMobs, true)

	# Setup NPC pathes
	var npcPathes = scene.find_node("npcPathes")
	var pathes = []
	for child in npcPathes.get_children():
		var path = child.get_child(0)
		var curve = Curve2D.new()
		for point in path.get_polygon():
			curve.add_point(point)
		var newPath = Path2D.new()
		if child.has_meta("is_circle"):
			var meta = child.get_meta("is_circle")
			newPath.set_meta("is_circle", meta)
		child.remove_child(path)
		newPath.set_curve(curve)
		newPath.name = child.name
		newPath.position = child.position
		pathes.append(newPath)
		npcPathes.remove_child(child)
	for path in pathes:
		npcPathes.add_child(path)
		path.set_owner(scene)

	# Set lights with script to lightsObject
	var lightsObject = scene.find_node("lights")
	if lightsObject != null and lightsObject.get_children().size() > 0:
		for child in lightsObject.get_children():
			if child is Sprite:
				var sprite_positon = child.position
				var custom_light = load("res://scenes/light/CustomLight.tscn").instance()
				custom_light.radius = 64
				custom_light.position = Vector2(sprite_positon.x + 8, sprite_positon.y - 8)

				lightsObject.add_child(custom_light)
				custom_light.set_owner(scene)
	
	print("reimported " + scene.name + "!")
	return scene



func generate_chunks(scene):
	var ground = scene.find_node("ground")
	
	count_tilemaps(ground)
	print(tilemap_list.size())
	print(map_min_pos)
	print(map_max_pos)
	
	# Size in tiles
	var map_width = abs(map_min_pos.x) + abs(map_max_pos.x)
	var map_height = abs(map_min_pos.y) + abs(map_max_pos.y)
	print(map_width)
	print(map_height)
	
	
	var chunks = []
	var chunks_node = Node2D.new()
	chunks_node.name = "Chunks"
	
	scene.add_child(chunks_node)
	chunks_node.set_owner(scene)
	
	for chunk_y in range(ceil(map_height / chunk_size)):
		for chunk_x in range(ceil(map_width / chunk_size)):
			var min_x = map_min_pos.x + chunk_size * chunk_x
			var min_y = map_min_pos.y + chunk_size * chunk_y
			var max_x = (map_min_pos.x + chunk_size * chunk_x) + chunk_size - 1
			var max_y = (map_min_pos.y + chunk_size * chunk_y) + chunk_size - 1
			var chunk = {"min_x": min_x, "min_y": min_y, "max_x": max_x, "max_y": max_y, "tilemaps": []}
			
			var chunk_node = Node2D.new()
			chunk_node.name = "Chunk"
			chunks_node.add_child(chunk_node)
			chunk_node.set_owner(scene)
			
			for tilemap in tilemap_list:

				var new_tilemap = TileMap.new()
				var dirtLvl0TileMap : TileMap = scene.find_node("dirt lvl0")
				new_tilemap.tile_set = dirtLvl0TileMap.tile_set
				new_tilemap.cell_quadrant_size = 1
				new_tilemap.cell_y_sort = false
				new_tilemap.cell_clip_uv = true
				new_tilemap.cell_size = Vector2(16,16)

				for cellPos in tilemap.get_used_cells(): 
#					print(cellPos)
#					print(chunk)
					if cellPos.x >= min_x and cellPos.x <= max_x and cellPos.y >= min_y and cellPos.y <= max_y:
						new_tilemap.set_cell(cellPos.x, cellPos.y, tilemap.get_cellv(cellPos))
				
				chunk_node.add_child(new_tilemap)
				new_tilemap.set_owner(scene)
#				chunk["tilemaps"].append(new_tilemap)
			
			chunks.append(chunk)
#			print(chunk)
	
	
#	for chunk in chunks:
#		for tilemap in chunk["tilemaps"]:
#			chunks_node.add_child(tilemap)
#			tilemap.set_owner(scene)
	
	
	# vlt chunks (-informationen) in datei speichern und runtime laden?
	
	
	
	

	
	
#	print(chunks)



# Method to iterate over all nodes and sets specific properties
func count_tilemaps(node):
	for child in node.get_children():
		if child.get_child_count() > 0:
			count_tilemaps(child)
		else:
			if child is TileMap:
				tilemap_list.append(child)
				
				# Get maximum map size in tiles
				var used_cells = child.get_used_cells()
				for cell_pos in used_cells:
					if cell_pos.x < map_min_pos.x:
						map_min_pos.x = cell_pos.x
					elif cell_pos.x > map_max_pos.x:
						map_max_pos.x = cell_pos.x

					if cell_pos.y < map_min_pos.y:
						map_min_pos.y = cell_pos.y
					elif cell_pos.y > map_max_pos.y:
						map_max_pos.y = cell_pos.y



# Method to iterate over all nodes and sets specific properties
func iterate_over_nodes(node):
	for child in node.get_children():
		if child.get_child_count() > 0:
			iterate_over_nodes(child)
		else:
			if child is TileMap:
				child.cell_quadrant_size = 1
				child.cell_y_sort = false
			
			elif child is CollisionPolygon2D and child.get_parent().get_parent().name == "mobSpawns":
				child.disabled = true
				child.get_parent().set_collision_layer_bit(0, false)
				child.get_parent().set_collision_mask_bit(0, false)
				child.get_parent().monitoring = false
				child.get_parent().monitorable = false
			
			elif child is CollisionShape2D and child.get_parent().get_parent().name == "playerSpawns":
				child.disabled = true
				child.get_parent().set_collision_layer_bit(0, false)
				child.get_parent().set_collision_mask_bit(0, false)
				child.get_parent().monitoring = false
				child.get_parent().monitorable = false
			
			elif child is CollisionShape2D and child.get_parent().get_parent().name == "changeScenes":
				child.get_parent().set_collision_mask_bit(0, false)
				child.get_parent().monitoring = true
				child.get_parent().monitorable = false
			
			elif child is CollisionShape2D and child.get_parent().get_parent().name == "stairs":
				child.get_parent().set_collision_mask_bit(0, false)
				child.get_parent().monitoring = true
				child.get_parent().monitorable = false


# Method to iterate over all nodes in "scene" and compresses all tilemaps to only one
func compress_tilemaps(node):
	for child in node.get_children():
		if child.get_child_count() > 0:
			compress_tilemaps(child)
		else:
			if child is TileMap:
				for cellPos in child.get_used_cells():
					compressed_tilemap.set_cell(cellPos.x, cellPos.y, child.get_cellv(cellPos))



# Method to iterate over all nodes in "ground" and removes all tiles under collisionshapes in tilemap to use map as navigation map
func remove_collisionshapes_from_tilemap(tilemap, node_with_collisionshapes):
	for child in node_with_collisionshapes.get_children():
		if child.get_child_count() > 0:
			remove_collisionshapes_from_tilemap(tilemap, child)
		else:
			if child is CollisionShape2D and child.get_parent() is StaticBody2D:
				var xExtentsFactor = 2
				var yExtentsFactor = 2
					
				for x in (child.shape.extents.x * xExtentsFactor):
					for y in (child.shape.extents.y * yExtentsFactor):
						tilemap.set_cell(int(floor((child.get_parent().position.x + x) / 16)), int(floor((child.get_parent().position.y + y) / 16)), -1)
