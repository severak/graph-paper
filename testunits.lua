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


--[[
print(-cm)
print(30*m2 // ft)
print(30*m / ft)
print(30*m // ft)
print(units.compound(206*cm, {km, m, cm, mm}))
print(units.compound(1067*mm, {ft, inch}))
print(units.compound(1524*mm, {ft, inch}))
print(units.compound(43200*s, {year, day, h, min, s}))
print(units.compound(86400*s, {year, day, h, min, s}))
print(units.compound(10, {year, day, h, min, s}))
os.exit()
print(3*ft + 6*inch)
print(3*ft + 6*inch ~ mm)
print(units.best(3*ft + 6*inch, {km, m, cm, mm})) 
print(units.best(106*cm, {km, m, cm, mm})) 
print(units.best(106*cm, {km, m, mm})) 
print(units.best(106*cm, {km, m})) 
print(units.best(1067*mm, {inch, ft, yd})) 
-- print(units.convert(106*cm, 'kg'))
print(-cm)
print((106*cm) % m)
print((106*cm) // m)
]]


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

print ""
print "Relations"
print "---------"
print ""
for ord, rel in ipairs(units.relations) do 
    print(string.format("%s = %s * %s", rel.c, rel.a, rel.b))
    print(string.format("%s = %s / %s", rel.a, rel.c, rel.b))
    print(string.format("%s = %s / %s", rel.b, rel.c, rel.a))
    print ""
end