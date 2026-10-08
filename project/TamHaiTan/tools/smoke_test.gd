extends Node
# ทดสอบวงจรหลักแบบอัตโนมัติ: godot --headless --path . res://tools/smoke_test.tscn

var fails := 0

func check(cond: bool, msg: String) -> void:
	print(("PASS " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1

func st(k: Node, n: String) -> Station:
	return k.get_node("Stage/Stations/" + n) as Station

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var gs = get_tree().root.get_node("GameState")
	for lvl in [0, 1]:
		gs.level_index = lvl
		var k: Node = load("res://scenes/kitchen.tscn").instantiate()
		get_tree().root.add_child(k)
		await get_tree().process_frame
		var p: Player = k.get_node("Player")
		var om: OrderManager = k.get_node("OrderManager")
		if lvl == 0:
			check(gs.phase == gs.Phase.STORY, "opening story plays before level 1")
			var dlg: DialogueBox = k.get_node("DialogueBox")
			dlg._on_next()
			dlg._on_next()
			check(dlg._index == 1, "story advances (index=%d)" % dlg._index)
			dlg.skip()
			check(gs.phase == gs.Phase.INTRO and not dlg.visible, "story skip -> intro")
		k._start()
		check(gs.phase == gs.Phase.PLAYING, "lvl%d start playing" % lvl)
		om.orders.clear()
		var o = om.add_random_order()
		var recipe: Recipe = null
		for r in om.config.recipes:
			if r.id == "tam_thai": recipe = r
		o.recipe = recipe
		o.spice = 1
		var mortar := st(k, "Mortar1")
		for ing in ["papaya", "chili", "tomato", "peanut"]:
			st(k, "Crate_" + ing).interact(p)
			check(p.held != null and p.held.ingredient_id == ing, "lvl%d pick %s" % [lvl, ing])
			if ing == "papaya" and om.config.require_chopping:
				mortar.interact(p)
				check(p.held != null, "unchopped papaya rejected by mortar")
				st(k, "Chop1").interact(p)
				check(p.held == null, "papaya on board")
				for i in 6: st(k, "Chop1").work(p)
				st(k, "Chop1").interact(p)
				check(p.held != null and p.held.prepared, "papaya chopped and picked")
			mortar.interact(p)
			check(p.held == null, "put %s in mortar" % ing)
		st(k, "Plates").interact(p)
		mortar.interact(p)
		check(p.held.is_empty_plate(), "can't plate before pounding")
		for i in 10: mortar.work(p)
		check(mortar.is_done(), "pounded")
		mortar.interact(p)
		check(p.held.dish == recipe, "plate has ตำไทย")
		# วางบนเคาน์เตอร์แล้วหยิบคืน
		st(k, "CounterF1").interact(p)
		check(p.held == null and st(k, "CounterF1").held != null, "place on counter")
		st(k, "CounterF1").interact(p)
		check(p.held != null, "pick from counter")
		st(k, "Serve").interact(p)
		check(p.held == null and om.score >= recipe.score and om.orders.is_empty(), "served, score=%d" % om.score)
		# ตำมั่ว
		var before := om.score
		st(k, "Crate_chili").interact(p); mortar.interact(p)
		for i in 10: mortar.work(p)
		st(k, "Plates").interact(p); mortar.interact(p)
		check(p.held.dish_failed, "wrong mix -> ส้มตำมั่ว")
		st(k, "Serve").interact(p)
		check(om.score == max(before - 5, 0), "wrong dish penalty")
		# ทิ้งขยะ
		st(k, "Crate_corn").interact(p); st(k, "Trash").interact(p)
		check(p.held == null, "trash ingredient")
		# ออเดอร์หมดเวลา
		var o2 = om.add_random_order()
		o2.time_left = 0.01
		om._process(0.1)
		check(om.stats.expired == 1, "order expired")
		# จบด่าน
		om.time_left = 0.01
		om._process(0.1)
		check(gs.phase == gs.Phase.RESULT, "level finished -> result (phase=%d running=%s t=%.3f)" % [gs.phase, om.running, om.time_left])
		k.queue_free()
		await get_tree().process_frame
	await customer_test()
	await systems_test()
	await cutscene_test()
	await menu_test()
	check(om_stars_ok(), "stars formula")
	print("FAILS: %d" % fails)
	get_tree().quit(1 if fails else 0)

func customer_test() -> void:
	var gs = get_tree().root.get_node("GameState")
	gs.level_index = 0
	var k: Node = load("res://scenes/kitchen.tscn").instantiate()
	get_tree().root.add_child(k)
	await get_tree().process_frame
	k.get_node("DialogueBox").skip()
	k._start()
	var om: OrderManager = k.get_node("OrderManager")
	var cm: Node = k.get_node("Customers")
	om.orders.clear()
	var o = om.add_random_order()
	check(cm.get_child_count() == 1, "customer spawned for order")
	var c: Customer = cm.get_child(0)
	for i in 400:
		c._process(0.05)
	check(c.rig.state == "sit" and c.global_position.distance_to(c.seat.global_position) < 0.05, "customer walked to seat and sat")
	om.serve(o.recipe)
	check(c.leaving, "served customer leaves")
	await get_tree().create_timer(1.1).timeout
	for i in 600:
		if not is_instance_valid(c):
			break
		c._process(0.05)
	check(not is_instance_valid(c) or c.is_queued_for_deletion(), "customer exits and is freed")
	k.queue_free()
	await get_tree().process_frame


## ความเผ็ด คอมโบ ทิป เหตุการณ์สุ่ม ท่าตำ
func systems_test() -> void:
	var gs = get_tree().root.get_node("GameState")
	gs.level_index = 1
	var k: Node = load("res://scenes/kitchen.tscn").instantiate()
	get_tree().root.add_child(k)
	await get_tree().process_frame
	k.get_node("DialogueBox").skip()
	k._start()
	var om: OrderManager = k.get_node("OrderManager")
	var p: Player = k.get_node("Player")
	var thai: Recipe = null
	for r in om.config.recipes:
		if r.id == "tam_thai": thai = r
	om._event_plan.clear()
	# --- ความเผ็ด: ต้องตรงจำนวนพริก ---
	om.orders.clear()
	var o = om.add_random_order({}, thai)
	o.spice = 2
	var before := om.score
	om.serve(thai, 0)
	check(om.orders.size() == 1 and om.stats.wrong == 1 and om.combo == 0, "spice off by 2 -> wrong dish, order stays")
	before = om.score
	o.time_left = o.patience * 0.1  # ช้า: ไม่มีทิป
	om.serve(thai, 1)
	check(om.orders.is_empty() and om.score - before == int(round(thai.score * 0.75)), "spice off by 1 -> 75%% score (+%d)" % (om.score - before))
	# --- คอมโบ + ทิป ---
	om.combo = 0
	var gains := []
	for i in 6:
		var oo = om.add_random_order({}, thai)
		oo.spice = 1
		oo.time_left = oo.patience  # เสิร์ฟทันที: ทิปเต็ม
		var b := om.score
		om.serve(thai, 1)
		gains.append(om.score - b)
	var s := thai.score
	check(gains[0] == s + OrderManager.TIP_FAST, "first dish x1 + fast tip (%d)" % gains[0])
	check(gains[1] == int(round(s * 1.5)) + OrderManager.TIP_FAST, "combo 2 -> x1.5 (%d)" % gains[1])
	check(gains[3] == s * 2 + OrderManager.TIP_FAST and gains[5] == s * 3 + OrderManager.TIP_FAST, "combo 4 -> x2, combo 6 -> x3")
	check(om.stats.max_combo == 6 and om.stats.tips == OrderManager.TIP_FAST * 6, "stats max combo / tips")
	var ex = om.add_random_order({}, thai)
	ex.time_left = 0.01
	om._process(0.05)
	check(om.combo == 0, "expired order breaks combo")
	# --- ทิปตามความเร็ว + หน้าลูกค้า ---
	var t1 = om.add_random_order({}, thai)
	t1.time_left = t1.patience * 0.5
	check(om.tip_for(t1) == OrderManager.TIP_OK and t1.mood() == 1, "half-waited -> small tip, neutral face")
	t1.time_left = t1.patience * 0.2
	check(om.tip_for(t1) == 0 and t1.mood() == 0, "long wait -> no tip, angry face")
	om.orders.clear()
	# --- เหตุการณ์สุ่ม ---
	om.start_event("rain")
	await get_tree().process_frame
	var tr = om.add_random_order({}, thai)
	tr.time_left = tr.patience
	check(om.tip_for(tr) == OrderManager.TIP_FAST * 2 and om._interval_scale() > 1.0, "rain: tip x2, slower customers")
	om.end_event("rain")
	om.orders.clear()
	om.start_event("tour")
	check(om.orders.size() == 3 and om.orders[0].recipe == om.orders[2].recipe, "tour: 3 orders same menu")
	om.orders.clear()
	om.start_event("rush")
	var rr = om.add_random_order({}, thai)
	check(om._interval_scale() < 1.0 and rr.patience < 65.0 * 0.85 + 30.0, "rush: faster spawns, shorter patience")
	om.end_event("rush")
	om.orders.clear()
	om.start_event("reviewer")
	check(om.orders.size() == 1 and om.orders[0].reviewer, "reviewer order created")
	var rv = om.orders[0]
	rv.time_left = rv.patience
	var b2 := om.score
	om.combo = 0
	om.serve(rv.recipe, rv.spice)
	check(om.score - b2 == (rv.recipe.score + OrderManager.TIP_FAST) * 2, "reviewer pays x2 (+%d)" % (om.score - b2))
	om.start_event("papaya_out")
	await get_tree().process_frame
	var crate := st(k, "Crate_papaya") as CrateStation
	check(crate.out_of_stock, "papaya crate out of stock")
	crate.interact(p)
	check(p.held == null, "can't take from empty crate")
	for i in CrateStation.RESTOCK_HITS: crate.work(p)
	check(not crate.out_of_stock, "mash space -> restocked")
	crate.interact(p)
	check(p.held != null and p.held.ingredient_id == "papaya", "take papaya after restock")
	p.release().queue_free()
	om.end_event("papaya_out")
	# --- ท่าตำ: ยืนตรงจุด ให้หัวสากลงกลางครก ---
	var m := st(k, "Mortar1") as MortarStation
	var spot := m.pound_spot(Vector3(1, 0, 0))
	var basis := Basis(Vector3.UP, spot.yaw)
	var hit: Vector3 = spot.position + basis * Vector3(CharacterRig.POUND_REACH.x, 0, -CharacterRig.POUND_REACH.z)
	check(Vector2(hit.x - m.global_position.x, hit.z - m.global_position.z).length() < 0.02, "pound spot puts pestle in mortar")
	k.queue_free()
	await get_tree().process_frame


func cutscene_test() -> void:
	Engine.time_scale = 12.0
	for id in ["level_1", "level_2", "level_3", "ending_good", "ending_mid", "ending_bad"]:
		var gs = get_tree().root.get_node("GameState")
		gs.cutscene_id = id
		var cs = load("res://scenes/cutscene.tscn").instantiate()
		cs.no_scene_change = true
		var finished := [false]
		cs.done.connect(func(): finished[0] = true)
		get_tree().root.add_child(cs)
		var frames := 0
		while not finished[0] and frames < 6000:
			await get_tree().process_frame
			frames += 1
		check(finished[0], "cutscene %s plays to the end (%d frames, actors=%d)" % [id, frames, cs.actors.size()])
		cs.queue_free()
		await get_tree().process_frame
	Engine.time_scale = 1.0


func menu_test() -> void:
	var m = load("res://scenes/main_menu.tscn").instantiate()
	get_tree().root.add_child(m)
	await get_tree().process_frame
	for p in ["levels", "howto", "settings"]:
		m._open(p)
		await get_tree().process_frame
		check(m._panels[p].visible and not m._main_box.visible, "menu panel " + p)
		m._close()
	m.queue_free()
	await get_tree().process_frame


func om_stars_ok() -> bool:
	var om := OrderManager.new()
	om.config = load("res://data/levels/level_1.tres")
	var ok: bool = om.stars_for(0) == 1 and om.stars_for(300) == 5 and om.stars_for(180) == 3
	om.free()
	return ok
