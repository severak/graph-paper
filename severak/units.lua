-- units tracking and conversion library
-- (c) Severák 2023
-- MIT licensed

-- This code tracks your units and converts them automatically so your Mars Climate Orbiter does not crash
--
-- (or it crashes even more because of unit conversion errors below:)
-- 
-- Strongly inspired by Frink language (https://frinklang.org/).

local units = {}
local units_meta = {}

-- size from unit to base unit (by unit name), e.g. 100 for cm
units.size = {}

-- dimension (type) of unit (by unit name), e.g. lenght for m
units.type = {}

-- base unit for unit type (e.g. m for lenght)
units.base = {}

-- alias to resolve to canonical unit name
units.alias = {}

-- human-readable description of unit
units.description = {}

-- explicit conversion for problematic units
units.explicit_convert = {}

-- format of units when calling tonstring(unit)
units.format_string = "%.10g %s"

function units.dim(value, unit)
    if units.alias[unit] then
        unit = units.alias[unit]
    end
    assert(units.size[unit], "Unknown unit " .. unit .. "!")
    return setmetatable({value=value, unit=unit}, units_meta)
end

function units.is_unit(val)
    return type(val)=="table" and getmetatable(val)==units_meta
end

function units.conforms(a, b)
    return units.is_unit(a) and units.is_unit(b) and units.type[a.unit]==units.type[b.unit]
end

function units.convert_value(val, unit)
    return val.value * units.size[val.unit] / units.size[unit]
end

function units.convert(val, unit)
    if units.alias[unit] then
        unit = units.alias[unit]
    end
    assert(units.is_unit(val), "Only units can be converted!")
    assert(units.size[unit], "Unknown target unit " .. unit .. "!")

    if units.explicit_convert[val.unit] then
        local try = units.explicit_convert[val.unit](val, unit)
        if try then
            return try
        end
    end

    assert(units.type[val.unit]==units.type[unit], "Cannot convert to different type of unit!")
    if val.unit==unit then
        return val -- target unit same as source unit
    end

    return units.dim(units.convert_value(val, unit),  unit)
end

function units.parse(val)
    local num, unit = string.match(val, "([%d%.]+)%s-(%w+)")
    if num and unit then
        if units.size[unit] then
            return units.dim(tonumber(num), unit)
        else
            return false, "Unit " .. unit .. " not defined!"
        end
    else
        return false, "Does not look like an unit."
    end
end

-- magic happens here:
-- (in metatable definition)
function units_meta.__tostring(val)
    return string.format(units.format_string, val.value, val.unit)
end

function units_meta.__eq(a, b)
    if units.is_unit(a) and units.is_unit(b) and units.conforms(a,b) then
        return a.value==units.convert_value(b, a.unit)
    end
    return false
end

function units_meta.__lt(a, b)
    if units.is_unit(a) and units.is_unit(b) and units.conforms(a,b) then
        return a.value<units.convert_value(b, a.unit)
    end
    return false
end

function units_meta.__le(a, b)
    if units.is_unit(a) and units.is_unit(b) and units.conforms(a,b) then
        return a.value<=units.convert_value(b, a.unit)
    end
    return false
end

function units_meta.__add(a, b)
    assert(units.is_unit(a) and units.is_unit(b), "Only units can be add together.")
    assert(units.conforms(a,b), "Only conformal units can be added. (We will not add kilograms to meters.)")
    
    -- units are first converted to the smaller one to perform addition
    if units.size[a.unit] < units.size[b.unit] then
        b = units.convert(b, a.unit)    
    end

    if units.size[a.unit] > units.size[b.unit] then
        a = units.convert(a, b.unit)    
    end

    return units.dim(a.value + b.value, a.unit)
end

function units_meta.__sub(a, b)
    assert(units.is_unit(a) and units.is_unit(b), "Only units can be subtracted.")
    assert(units.conforms(a,b), "Only conformal units can be subtracted. (We will not add kilograms to meters.)")

    -- units are first converted to the smaller one to perform subtraction
    if units.size[a.unit] < units.size[b.unit] then
        b = units.convert(b, a.unit)    
    end

    if units.size[a.unit] > units.size[b.unit] then
        a = units.convert(a, b.unit)    
    end

    return units.dim(a.value - b.value, a.unit)
end

function units_meta.__mul(a, b)
    if units.is_unit(a) and tonumber(b) then
        return units.dim(a.value * tonumber(b), a.unit)
    end
    if units.is_unit(b) and tonumber(a) then
        return units.dim(b.value * tonumber(a), b.unit)
    end

    error("Multiplication by other unit not yet implemented.")
end

function units_meta.__div(a, b)
    if units.is_unit(a) and tonumber(b) then
        return units.dim(a.value / tonumber(b), a.unit)
    end
    if units.is_unit(b) and tonumber(a) then
        return units.dim(b.value / tonumber(a), b.unit)
    end

    error("Division by other unit not yet implemented.")
end

function units.define(def)
    assert(def,name, "Undefined unit name!")
    units.size[def.name] = def.size or error("Undefined unit size!")
    units.type[def.name] = def.type or error("Undefined unit type!")
    
    if def.size==1 then
        units.base[def.type] = def.name
    end

    if def.description then
        units.description[def.name] = def.description
    end

    if def.explicit_convert then
        units.explicit_convert[def.name] = def.explicit_convert
    end
    
    if def.alias then
        for _, from in ipairs(def.alias) do
            units.alias[from] = def.name
        end
    end
    
    if def.SI_prefixes then
        def.SI_dimension = def.SI_dimension or 1

        local prefixes = {
            P = 10^15,
            T = 10^12,
            G = 10^9,
            M = 10^6,
            k = 10^3,
            h = 10^2,
            da = 10^1,
            d = 10^-1,
            c = 10^-2,
            m = 10^-3,
            u = 10^-6,
            n = 10^-9,
        }

        for prefix, size in pairs(prefixes) do
            units.size[prefix .. def.name] = def.size * (size ^ def.SI_dimension)
            units.type[prefix .. def.name] = def.type
        end 
    end
end

-- c = a * b
-- TODO: units.relate(a, b, c)

-- pollutes _G with definited units, dim and convert functions
function units.import_globals()
    for unit, size in pairs(units.size) do
        _G[unit] = units.dim(1, unit)
    end
    for unit, trueSize in pairs(units.alias) do
        _G[unit] = _G[trueSize]
    end

    _G.dim = units.dim
    _G.convert = units.convert
    _G.to = units.convert

    -- defines % operator for unit conversion
    units_meta.__mod = function(a, b)
        if units.is_unit(a) and units.is_unit(b) then
            return units.convert(a, b.unit)
        elseif units.is_unit(a) and type(b)=="string" then
            return units.convert(a, b)
        end
        error("Conversion is not posssible.")
    end
end

-- UNIT DEFINITIONS
-- 
-- Mostly stolen from https://frinklang.org/frinkdata/units.txt but only some units are defined.
-- Made more sensible using Wikipedia.

-- LENGTH

units.define{name="m", size=1, type="length", SI_prefixes=true}

-- imperial
units.define{name="in", alias={"inch"}, size=units.size.cm * 2.54, type="length"}
units.define{name="ft", alias={"feet", "foot"}, size=units.size['in'] * 12, type="length"}
units.define{name="mi", alias={"mile"}, size=units.size.ft * 5280, type="length"}
units.define{name="nmi", size=1852, type="length", description="nautical mile"} 

-- astronomical unit
units.define{name="AU", size=149597870700, type="length"}

units.define{name="U", size=units.size.mm * 44.45, type="lenght", description="Rack unit"}

-- TODO - typographical units

-- TIME
units.define{name="s", size=1, type="time"}
units.define{name="min", size=units.size.s * 60, type="time"}
units.define{name="h", size=units.size.min * 60, type="time"}
units.define{name="day", size=units.size.h * 24, type="time"}
units.define{name="week", size=units.size.day * 7, type="time"}
units.define{name="year", size=units.size.day * 365, type="time"}

-- we do not definte calendar operations in this library

-- MASS
units.define{name="g", size=1/1000, type="mass", SI_prefixes=true}
units.base.mass = "kg" -- base unit for weight is kilogram, but it got prefix so we need to force it to be base unit

units.define{name="t", size=units.size.kg * 1000, type="mass", description="metric ton"}

-- imperial (https://en.wikipedia.org/wiki/Avoirdupois)
units.define{name="lb", alias={"pound"}, size=units.size.kg * 0.45359237, type="mass"}
units.define{name="oz", alias={"ounce"}, size=units.size.lb * 1/16, type="mass"}
-- https://en.wikipedia.org/wiki/Stone_(unit)#Modern_use
units.define{name="stone", size=units.size.kg * 6.350, type="mass"}

-- https://en.wikipedia.org/wiki/Troy_weight
units.define{name="ozt", size=units.size.g * 31.10, alias={"oz t"}, type="mass"} -- for gold

-- CURRENT
units.define{name="A", size=1, type="current", SI_prefixes=true} -- ampere

-- TEMPERATURE
local fromK = function(val, unit)
    if unit=='C' then return units.dim(val.value - 273.15, "C") end
    if unit=='F' then return units.dim(1.8 * val.value - 459.67, "F") end
    if unit=='R' then return units.dim(1.8 * val.value, "R") end
end

units.define{name="K", size=1, type="temperature", description="Kelvin", explicit_convert=fromK}
units.define{name="R", alias={"°R"}, size=5/9, type="temperature", description="Rankine"}

-- as Farenheit and Celsius do not have same 0, we don't want to automatically convert between those and you need to convert them explicitly

-- see https://en.wikipedia.org/wiki/Celsius
local fromC = function(val, unit) 
    if unit=='K' then return units.dim(val.value + 273.15, "K") end
    if unit=='R' then return units.dim((val.value +  273.15) * (9/5), "R") end
    if unit=='F' then return units.dim((val.value * (9/5)) + 32, "F") end
end

units.define{name="C", alias={"°C"}, size=1, type="temperature_celsius", explicit_convert=fromC}

-- see https://en.wikipedia.org/wiki/Fahrenheit
local fromF = function(val, unit)
    if unit=='C' then return units.dim((val.value - 32) * (5/9), "C") end
    if unit=='K' then return units.dim((val.value + 459.67) * (5/9), "K") end
    if unit=='R' then return units.dim(val.value + 459.67, "R") end
end

units.define{name="F", alias={"°F"}, size=1, type="temperature_farenheit", explicit_convert=fromF}

-- AMOUNT OF SUBSTANCE (MOL) TODO

-- ANGLE
units.define{name="turn", size=1, type="angle"} -- I am deviating from official definition to have circle as definition of angle units
units.define{name="rad", size=1/(2*math.pi), type="angle"} -- 2 pi radian = 1 circle
units.define{name="deg", size=1/360, type="angle"}

-- INFORMATION
units.define{name="b", size=1, type="information", SI_prefixes=true}
units.define{name="B", size=8, type="information", SI_prefixes=true}
-- TODO - sort out kiB vs kb etc... 1024-based units are mess


-- LUMINOUS INTENSITY (CANDELA) -- TODO define

--- derived units: 
-- big TODO - https://en.wikipedia.org/wiki/International_System_of_Units

-- AREA
units.define{name="m2", alias={"m²"}, size=1, type="area", SI_prefixes=true, SI_dimension=2}

-- VOLUME
units.define{name="m3", alias={"m³"}, size=1, type="volume", SI_prefixes=true, SI_dimension=3}
units.define{name="l", size=units.size.m3 * (1/1000), type="volume", SI_prefixes=true}

units.define{name="barrel", size=units.size.l * 158.987, type="volume"} -- for oil

-- FREQUENCY
units.define{name="Hz", size=1, type="frequency", SI_prefixes=true}
-- TODO - Hz to meters of wavelenght and vice versa -  https://commsbrief.com/wavelength-calculator-calculating-wavelength-of-radio-waves/

-- VELOCITY (aka SPEED)
units.define{name="m_s", alias={"m/s"}, size=1, type="velocity"}
units.define{name="km_h", alias={"km/h"}, size=units.size.km / units.size.h, type="velocity"}
units.define{name="mph", size=units.size.mi / units.size.h, type="velocity"}
units.define{name="mach", size=units.size.m_s * 331.46, type="velocity"} -- for fighter aircraft

-- TODO 
-- old czech units -  http://www.geneze.info/pojmy/subdir/stare_ceske_jednotky.htm, http://www.jankopa.cz/wob/PH_001.html a https://plzen.rozhlas.cz/loket-pid-nebo-latro-znate-stare-miry-a-vahy-6737273

-- TODO - musical units - BPM, PPQN

-- some sanity checks if logic it's not broken
local dim = units.dim
assert(dim(100, "cm") == dim(1, "m")) 
assert(dim(1, "m") + dim(6, "cm") == dim(106, "cm"))

return units