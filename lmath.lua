local M = {}

function M.angle2pos(point, angle, distance)
	local rad = math.pi / 180
	local op = math.sin(angle * rad) * distance
	local ad = math.cos(angle * rad) * distance

	return {
		x = op + point.x,
		y = ad + point.y,
	}
end

return M

