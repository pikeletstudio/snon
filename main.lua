require("item")
require("station")
require("ui")
require("player")

function love.load()

	math.randomseed(os.time())
	love.graphics.setBackgroundColor(0.1, 0.05, 0.1, 1)
	love.graphics.setDefaultFilter("nearest")
	screenW = love.graphics.getWidth() / 2
	screenH = love.graphics.getHeight() / 2
	screenScale = 2


	SCREEN_TRANSFORM = love.math.newTransform()
	SCREEN_TRANSFORM:scale(screenScale, screenScale)
	SCREEN_TRANSFORM:translate(screenW / screenScale, screenH / screenScale)

	SCORE = 0
	CREDITS = 0
	GAMEOVER = false
	TIME = 0

	-- fixed update settings
	PAUSE = false
	fixed_tick = 0.01 -- seconds
	tick_accum = 0
	
	item_timer = 2 -- seconds
	item_accum = 0
	items = {}

	ignore_types = {"EMPTY", "FUEL"}
	ItemTypes = {}
	item_type_keys = getKeys(EntityTypes, ignore_types)
	for k = 1, #item_type_keys do
		type = item_type_keys[k]
		ItemTypes[type] = EntityTypes[type]
	end

	player_sprite_head = love.graphics.newImage("assets/player_head.png")
	player_sprite_body = love.graphics.newImage("assets/player_body_empty.png")
	player = Player.new(fixed_tick, player_sprite_head, player_sprite_body, 0, 0, 1)
	player_grow_first = false
	
	pfb_pos = 0.2 -- % of screen width in from left side
	player_fuel_bar = ProgressBar.new(screenW * pfb_pos, 80,
										screenW * (1-pfb_pos) * 2, 10,
										0, 0,
										"horizontal", EntityTypes.FUEL)
	
	drop_points = {}
	fuel_stations = {}
	shipyards = {}
	stations = {drop_points, fuel_stations, shipyards}

	for d = 1, 3 do
		type = getKeys(ItemTypes)[d]
		table.insert(drop_points, spawnStation(type, DropPoint, stations))
	end
	print("done 1")
	
	for f = 1, 2 do
		table.insert(fuel_stations, spawnStation("FUEL", FuelStation, stations))
		print("done 2."..f)
	end
	print("done 2")
	
	for s = 1, 1 do
		table.insert(shipyards, spawnStation("EMPTY", Shipyard, stations))
	end
	print("done 3")
end

function love.draw()
	love.graphics.print("SCORE: "..SCORE, 20, 20, 0, 1.25)
	love.graphics.print("CREDITS: "..CREDITS, 20, 40, 0, 1.25)
	--love.graphics.print(printCells(), 20, 40, 0)
	--love.graphics.print("len: "..player.length.." segs: "..#player.segments.." last: "..player.last_filled, 20, 60, 0)
	player_fuel_bar:draw(player.fuel / player.fuelMax)
	love.graphics.push()
	love.graphics.applyTransform(SCREEN_TRANSFORM)

	love.graphics.rectangle("fill", 0, 0, 1, 1)
	player:draw()
	for i, item in pairs(items) do item:draw() end -- drawBBox("circle", item:getBBox("circle")) end
	for i, dp in pairs(drop_points) 
		do dp:draw() drawBBox("circle", dp:getDepositBBox("circle"), dp.colour) end
	
	for i, fs in pairs(fuel_stations) 
		do fs:draw() drawBBox("circle", fs:getDepositBBox("circle"), fs.colour) end
	
	for i, sy in pairs(shipyards) 
		do sy:draw() drawBBox("circle", sy:getDepositBBox("circle"), sy.colour) end

	love.graphics.pop()
	if GAMEOVER then drawEndScreen() end
end

function love.update(dt)
	if player.fuel <= 0 then endGame() end
	if PAUSE then return end
	
	TIME = TIME + dt
	if TIME > 0.1 then
		if not player_grow_first then
			player:grow(1)
			player_grow_first = true
		end
	end

	-- player fixed tick update
	tick_accum = tick_accum + dt
	if tick_accum >= fixed_tick then
		tick_accum = 0
		player:update(fixed_tick)
	end

	-- spawning items
	item_accum = item_accum + dt
	if item_accum >= item_timer and #items < 25 then
		item_accum = 0
		
		table.insert(items, spawnItem(getRandomKey(ItemTypes), items, TIME))
	end

	-- player collision with items
	for i, item in pairs(items) do 
		if item:checkCollision(player:getBBox()) then
			collected = player:collect(item)
			if collected then table.remove(items, i) end
		end
	end

	-- player collision with drop point pickup radius
	for i, dp in pairs(drop_points) do 
		dp:update(dt)

		if dp.ready and dp:checkDeposit(player:getBBox("circle")) then
			seg = player:getFirstFilled()
			if dp:deposit(seg) then
				SCORE = SCORE + 1
				CREDITS = CREDITS + 10
				player:emptySegment(seg)
				player.last_filled = player.last_filled - 1
				player:cycleCells(-1)
				--player:grow(1)
			end
		end
	end

	-- player collision with fuel station pickup radius
	for i, fs in pairs(fuel_stations) do 
		fs:update(dt)
		if fs.ready and fs:checkDeposit(player:getBBox("circle")) then
			if CREDITS >= 10 then
				CREDITS = CREDITS - 10
				player.fuel = player.fuel + player.fuelMax * 0.2
				fs:refill()
			end
		end
	end
	
	-- player collision with shipyard pickup radius
	for i, sy in pairs(shipyards) do 
		sy:update(dt)
		if sy.ready and sy:checkDeposit(player:getBBox("circle")) then
			if CREDITS >= 50 then
				CREDITS = CREDITS - 50
				player:grow(1)
				sy:refill()
			end
		end
	end

	new_scale = 2 - math.min(1.75, player.length / 200)
	updateTransform(new_scale)
end

function love.keypressed(key, scancode, isrepeat)
	if love.keyboard.isDown("r") then
		love.load()
	end

	if love.keyboard.isDown("escape") then
		love.event.quit()
	end

	if love.keyboard.isDown("p") then
		PAUSE = not PAUSE
	end
		
	if key == "s" then
		player:grow(1)
	end
end

function love.mousepressed(x, y, button, istouch, presses)

end

function updateTransform(scale)
	SCREEN_TRANSFORM = love.math.newTransform()
	SCREEN_TRANSFORM:scale(scale, scale)
	SCREEN_TRANSFORM:translate(screenW / scale, screenH / scale)
end

function endGame()
	PAUSE = true
	GAMEOVER = true
end


function printCells()
	text = ""
	for n, cell in pairs(player.segments) do
		text = text.."("..n.." "..cell.type..")"
	end
	return text
end

function printTable(t)
	for k, v in pairs(t) do
		print(tostring(k)..": "..tostring(v))
	end
end