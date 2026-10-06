class_name DistrictMinimap
extends Control

var district: HarborDistrict
var vehicle: DeliveryVehicle
var missions: DeliveryManager
var traffic: HarborTraffic
var show_labels: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func map_point(pos: Vector3) -> Vector2:
	return Vector2(16 + (pos.x + 185) / 375.0 * (size.x - 32), 19 + (pos.z + 192) / 384.0 * (size.y - 38))

func _draw() -> void:
	if not is_instance_valid(vehicle):
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("182f34"))
	var water_x = map_point(Vector3(175, 0, 0)).x
	draw_rect(Rect2(Vector2(water_x, 0), Vector2(size.x - water_x, size.y)), Color("244c58"))
	for x in [-60, 60]:
		for z in [-75, 75]:
			draw_rect(Rect2(map_point(Vector3(x - 44, 0, z - 57)), Vector2(88.0 / 375 * (size.x - 32), 114.0 / 384 * (size.y - 38))), Color("26413f"))
	for x in HarborDistrict.ROAD_X:
		draw_line(map_point(Vector3(x, 0, -150)), map_point(Vector3(x, 0, 150)), Color("5c7170"), 6 if not show_labels else 13, true)
	for z in HarborDistrict.ROAD_Z:
		draw_line(map_point(Vector3(-120, 0, z)), map_point(Vector3(120, 0, z)), Color("5c7170"), 6 if not show_labels else 13, true)
	if missions.route.size() > 1:
		var line = PackedVector2Array()
		for p in missions.route:
			line.append(map_point(p))
		draw_polyline(line, Color("edb677"), 2.3, true)
	for i in district.places.size():
		var p = map_point(district.places[i].position)
		var active = not missions.service_waypoint and missions.target_index() == i
		draw_circle(p, 4.5 if active else 2.2, Color("edc387") if active else Color("86a69c"))
		if show_labels:
			var caption: String = district.places[i].short
			var width = ThemeDB.fallback_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var at = p + Vector2(-width - 8 if p.x > size.x * 0.7 else 8, -7)
			draw_string(ThemeDB.fallback_font, at, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e9e4cf"))
	draw_rect(Rect2(map_point(HarborDistrict.FUEL_POINT) - Vector2(3, 3), Vector2(6, 6)), Color("71b3b0"))
	if show_labels:
		draw_string(ThemeDB.fallback_font, map_point(HarborDistrict.FUEL_POINT) + Vector2(8, -7), "COAST SERVICE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("81bcb0"))
	for car in traffic.cars:
		draw_circle(map_point(car.body.global_position), 1.7, Color("b0b8b1"))
	var center = map_point(vehicle.global_position)
	var heading = vehicle.global_rotation.y
	var arrow = PackedVector2Array()
	for p in [Vector2(0, -7), Vector2(4.5, 5), Vector2(0, 2.5), Vector2(-4.5, 5)]:
		arrow.append(center + p.rotated(-heading))
	draw_circle(center, 8, Color(0.06, 0.12, 0.14, 0.65))
	draw_colored_polygon(arrow, Color("f5ead0"))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 24, 20), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d1dccd"))
