local units = require "severak.units"
local dim = units.dim
dim = units.dim
units.import_globals()

print(to(50 * 25 * 2.5 * m3, "hl"))
os.exit()

print ""

print "Conversion table"
print "----------------"
print ""

for unitType, baseUnit in pairs(units.base) do
    print(unitType .. ":")
    for unit, size in pairs(units.size) do
        if units.type[unit]==unitType then
            local type = units.type[unit]
            local base = units.base[type]
            if size < 1 then
                print(string.format("1 %s = %.10g %s (%f)", unit, size, base, size))
            else 
                print(string.format("1 %s = %.10g %s", unit, size, base))
            end
        end
    end
    print ""
end

