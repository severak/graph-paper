local units = require "severak.units"
local dim = units.dim

cm = units.dim(1, "cm")
m = units.dim(1, "m")

print("---")

print(units.parse("1m"))
print(units.parse("-1cm"))
print(units.parse("1m"))
print(units.parse("160 m"))

print "---"

print(cm)
print(m)
print(cm.value)
print(cm.unit)


function test_convert(from, to)
    print(tostring(from) .. " -> " .. to .. " = " .. tostring(units.convert(from, to)))
end

test_convert(dim(1000, "l"), "m3")
test_convert(dim(1, "ml"), "cm3")
test_convert(dim(100, "cm"), "m")
test_convert(dim(1, "m"), "cm")
test_convert(dim(1, "km"), "m")
test_convert(dim(10, "km"), "m")
test_convert(dim(1, "km"), "cm")
test_convert(dim(1, "mile"), "m")
test_convert(dim(1, "mile"), "km")
test_convert(dim(1, "day"), "min")


test_convert(dim(180, "deg"), "circle")
test_convert(dim(180, "deg"), "rad")
test_convert(dim(60, "deg"), "rad")

-- print(3 + dim(1, "m"))
-- print(dim(1, "m") + 6)
-- print(dim(1, "m") + dim(6, "cm"))
-- print(dim(1, "m") - dim(6, "cm"))
-- print(dim(1, "m") * 3)
-- print(3 * dim(1, "m"))
--print(dim(1, "m") * dim(1, "m"))


-- print units.dim(1, "m") + units.dim(1, "cm")