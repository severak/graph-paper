-- simple 2D geometry library
-- (c) Severák 2023
-- MIT licensed

local geom = {}

function geom.almost_eq(a, b, epsilon)
    epsilon = epsilon or 0.1
    return math.abs(b - a) < epsilon
end

-- distance from point a to point b
function geom.distance(a, b)
    return math.sqrt(math.pow(b.x-a.x, 2) + math.pow(b.y-a.y,2, 2))
end

-- midpoint between a and b
function geom.midpoint(a, b)
    return {x=((b.x-a.x)/2)+a.x, y=((b.y-a.y)/2)+a.y}
end

return geom