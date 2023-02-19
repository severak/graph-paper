local units = require "severak.units"
local dim = units.dim
dim = units.dim
units.import_globals()

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

print((40*km) / (40*min))
print((1*km)/h)
print((100*km)/(120*km_h))
print(((100*h)/(120*km_h)))
os.exit()

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

