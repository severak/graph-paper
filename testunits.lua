local units = require "severak.units"
local dim = units.dim
dim = units.dim
units.import_globals()

local push = table.insert

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


print "Supported units"
print "---------------"
print ""

local push = table.insert
local supported = {}

for unit_name, unit_size in pairs(units.size) do
    if not units.is_prefixed[unit_name] then
        push(supported, units.explain(unit_name))
    end
end
table.sort(supported);

print(table.concat(supported, "\n"))
print ""

print "Conversion table"
print "----------------"
print ""

for unitType, baseUnit in pairs(units.base) do
    print(unitType .. ":")
    local sorted_by_size = {}
    for unit, size in pairs(units.size) do
        if units.type[unit]==unitType then
            push(sorted_by_size, {name=unit, size=size})
        end
    end

    table.sort(sorted_by_size, function(a, b) return a.size>b.size end)
    for _, unit in pairs(sorted_by_size) do
      print(string.format("1 %s = %g %s", unit.name, unit.size, baseUnit))  
    end
    print ""
end

