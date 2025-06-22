-- this is the config file, you can configure settings for the game window, input, etc

function love.conf(t)
	t.window.width = 800
    t.window.height = 500
	-- t.window.resizable = true

	t.window.title = "snon"

	-- turning off these modules to save memory as they are not being used
	t.modules.joystick = false
    t.modules.physics = false

	t.console = true
end