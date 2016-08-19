local parser = require('peg')
local keys = require('keys')
local lsystem = require('lsystem')

-- dragon curve
local default_what = [[
axiom FX

rule X X+YBF+
rule Y -WFX-Y

tg F forward 10
tg - turn -90
tg + turn 90
tg B color blue
tg W color green
]]

-- canvas size
local csize = {
	x = 4096,
	y = 4096,
}

local state = {
	-- toggled help
	help = false,
	-- file
	file = "",
	text = "",

	-- l-system steps
	steps = 1,

	-- current parsed l-system
	tree = {},
	-- expanded l-system
	exp = "",

	-- offset from top-left to draw canvas
	origin = { x = 0, y = 0 },
	canvas = {},

	rotation = 0,

	-- last render time
	ms = 0,
}

local loadl = function()
	if state.file and state.file ~= "" then
		local stuff = love.filesystem.read(state.file)
		state.text = stuff
	end
end

function state:step(n)
	if n + self.steps > 0 then
		self.steps = self.steps + n
	end
end

function state:rot(deg)
	self.rotation = self.rotation + (deg * (math.pi/180))
end

function state:vert(px)
	self.origin.y = self.origin.y + px
end

function state:horiz(px)
	self.origin.x = self.origin.x + px
end

function state:zero()
	self.origin.x = 0
	self.origin.y = 0
	self.rotation = 0
end

local eval = function()
	local gfx = love.graphics
	local width = gfx.getWidth()
	local height = gfx.getHeight()
	local st, t = pcall(parser.parse, state.text)
	if st == false then

		state.tree = nil
		state.exp = ""

		print(t)
		gfx.printf(t, 5, 10, width)
	else
		local start = love.timer.getTime()
		state.tree = t

		local ls = lsystem.create({x=csize.x/2,y=csize.y/2}, t)

		gfx.setCanvas(canvas)
		gfx.clear()

		state.exp = ls:expand(state.steps)

		local r,g,b,a=gfx.getColor()
		ls:draw(state.exp)
		gfx.setColor(r,g,b,a)

		gfx.setCanvas()

		local result = love.timer.getTime() - start
		state.ms = result * 1000
	end
end

local kbinds = {
	{ {},		"f1",		function() state.help = not state.help end,	"toggle help" },
	{ {},		"r",		function() loadl() eval() end,			"redraw" },
	{ {},		"z",		function() state:zero() end,			"center" },
	{ {"lshift"},	"right",	function() state:rot(5) end,			"rotate -5 degrees" },
	{ {"lshift"},	"left",		function() state:rot(-5) end,			"rotate 5 degrees" },
	{ {},		"right",	function() state:horiz(10) end,			"move right 10 pixels" },
	{ {},		"left",		function() state:horiz(-10) end,		"move left 10 pixels" },
	{ {},		"up",		function() state:vert(-10) end,			"move up 10 pixels" },
	{ {},		"down",		function() state:vert(10) end,			"move down 10 pixels" },
	{ {},		"pageup",	function() state:step(1); eval() end,		"increase step" },
	{ {},		"pagedown",	function() state:step(-1); eval() end,		"decrease step" },
	{ {},		"escape",	love.event.quit,				"quit",	},
}

function love.load(arg)
	state.file = arg[2]
	state.text = default_what

	local g = love.graphics

	love.window.setMode(800, 600, {resizable=true, vsync=true, minwidth=400, minheight=300})
	love.keyboard.setKeyRepeat(true)

	for i = 1, #kbinds do
		keys:bind(unpack(kbinds[i]))
	end

	canvas = g.newCanvas(csize.x, csize.y)
	g.setLineWidth(3)
end

function love.textinput(t)
	--text = text .. t
	--eval()
	love.keypressed(t, false)
end

function love.draw()
	local g = love.graphics
	local width = g.getWidth()
	local height = g.getHeight()
	local w = width / 2   -- half the window width
	local h = height / 2   -- half the window height

	-- just loaded, or something is wrong
	if state.ms == 0 then
		loadl()
		eval()
	end

	-- draw lsystem first, below the rest
	g.push()
	g.draw(canvas, w + state.origin.x, h + state.origin.y, state.rotation, 1, 1, csize.x/2, csize.y/2)
	g.pop()

	if state.help then
		local help = "key bindings:\n\n"
		for k,v in pairs(kbinds) do
			local key = ""
			if #v[1] > 0 then
				key = table.concat(v[1], "+") .. "+"
			end

			key = key .. v[2]

			help = help .. string.format("%-12s...\t%s\n", v[2], v[4])
		end

		g.print(help, w - 50, 50)
	end

	g.printf(state.text, 5, 40, width)
	g.print(tostring(state.steps), width - 20, 10)
	g.print(string.format("took %.3fms", state.ms), width - 100, 22)

	-- debugging
	--g.print(inspect(state.tree), 5, 500)
end

function love.keypressed(key)
	print("key", key)
	keys:handle(key)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
	print(id, x, y, pressure)
end

