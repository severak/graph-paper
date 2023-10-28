-- units tracking and conversion library
-- (c) Severák 2023
-- MIT licensed

-- This code tracks your units and converts them automatically so your Mars Climate Orbiter does not crash
--
-- (or it crashes even more because of unit conversion errors below:)
-- 
-- Strongly inspired by Frink language (https://frinklang.org/) and Numbat calculator (https://numbat.dev/).

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

-- unit relations for multiplying and division
units.relations = {}

-- useful constants
units.const = {}

-- if this unit is just prefixed other one
units.is_prefixed = {}

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

function units.is_conformal(a, b)
    return units.is_unit(a) and units.is_unit(b) and units.type[a.unit]==units.type[b.unit]
end

units.conforms = units.is_conformal -- TODO: deprecate this when I am not lazy

function units.unpack(val)
    assert(units.is_unit(val), "Only units can be unpacked")
    return val.value, val.unit
end

function units.convert_value(val, unit)
    return val.value * units.size[val.unit] / units.size[unit]
end

function units.explain(val)
    if type(val)=="string" then
        val = units.dim(1, val)
    end
    assert(units.is_unit(val), "Only units can be converted!")
    if units.description[val.unit] then
        return val.unit .. " (" .. units.type[val.unit] .. " - " ..  units.description[val.unit] .. ")"
    end
    return val.unit .. " (" .. units.type[val.unit] .. ")"
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

function units.best(val, possible_units)
    assert(#possible_units>0, "Please provide units to choose from.")
    local prev = val
    for i, candidate in ipairs(possible_units) do
        if type(candidate)=='string' then
            possible_units[i] = units.dim(1, candidate)
        end
        assert(units.conforms(prev, candidate), "Possible units are not conformal.")
        prev = candidate
    end
    table.sort(possible_units, function(a, b) return a>b end)
    for i, candidate in ipairs(possible_units) do
        if val >= candidate then
            return units.convert(val, candidate.unit)
        end
    end
    return val
end

-- TODO - units.compound

function units.parse(val)
    -- TODO - syntax for time in day and angles
    local num, unit = string.match(val, "([%d%.]+)%s-(%S+)")
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

-- conversion to string (for printing)
function units_meta.__tostring(val)
    return string.format(units.format_string, val.value, val.unit)
end

-- comparing
function units_meta.__eq(a, b)
    if units.is_unit(a) and units.is_unit(b) and units.conforms(a,b) then
        return a.value == units.convert_value(b, a.unit)
    end
    return false
end

function units_meta.__lt(a, b)
    if units.is_unit(a) and units.is_unit(b) and units.conforms(a,b) then
        return a.value < units.convert_value(b, a.unit)
    end
    return false
end

function units_meta.__le(a, b)
    if units.is_unit(a) and units.is_unit(b) and units.conforms(a,b) then
        return a.value <= units.convert_value(b, a.unit)
    end
    return false
end

-- plus
function units_meta.__add(a, b)
    assert(units.is_unit(a) and units.is_unit(b), "Only units can be add together.")
    assert(units.conforms(a,b), "You cannot add " .. units.explain(a) .. " to " .. units.explain(b) .. ".")
    
    -- units are first converted to the smaller one to perform addition
    if units.size[a.unit] < units.size[b.unit] then
        b = units.convert(b, a.unit)    
    end

    if units.size[a.unit] > units.size[b.unit] then
        a = units.convert(a, b.unit)    
    end

    return units.dim(a.value + b.value, a.unit)
end

-- minus
function units_meta.__sub(a, b)
    assert(units.is_unit(a) and units.is_unit(b), "Only units can be subtracted.")
    assert(units.conforms(a,b), "You cannot subttract " .. units.explain(b) .. " from " .. units.explain(a) .. ".")

    -- units are first converted to the smaller one to perform subtraction
    if units.size[a.unit] < units.size[b.unit] then
        b = units.convert(b, a.unit)    
    end

    if units.size[a.unit] > units.size[b.unit] then
        a = units.convert(a, b.unit)    
    end

    return units.dim(a.value - b.value, a.unit)
end

local function find_multiplication_relations(a, b)
    for _, rel in ipairs(units.relations) do
        if a.unit==rel.a and b.unit==rel.b then
            return rel
        end
        if a.unit==rel.b and b.unit==rel.a then
            return rel
        end
        if units.type[a.unit]==units.type[rel.a] and units.type[b.unit]==units.type[rel.b] then
            return rel
        end
        if units.type[a.unit]==units.type[rel.b] and units.type[b.unit]==units.type[rel.a] then
            return rel
        end
    end
end

-- multiply
function units_meta.__mul(a, b)
    if units.is_unit(a) and tonumber(b) then
        return units.dim(a.value * tonumber(b), a.unit)
    end
    if units.is_unit(b) and tonumber(a) then
        return units.dim(b.value * tonumber(a), b.unit)
    end

    if units.is_unit(a) and units.is_unit(b) then
        local relation = find_multiplication_relations(a, b)
        if relation then
            return units.dim(units.convert_value(a, relation.a) * units.convert_value(b, relation.b), relation.c)
        end
        error('Multiplication of ' .. units.explain(a.unit) .. ' and ' .. units.explain(b.unit) .. ' is not defined.')
    end

    error("Multiplication of units by something else is not defined.")
end

local function find_division_relations(c, a_b)
    -- finds either a = c / b or b = c / a
    for _, rel in ipairs(units.relations) do
        -- a = c / b
        if c.unit==rel.c and a_b.unit==rel.b then
            return rel, "b"
        end
        -- b = c / a
        if c.unit==rel.c and a_b.unit==rel.a then
            return rel, "a"
        end
        -- same for conformals
        -- a = c / b
        if units.type[c.unit]==units.type[rel.c] and units.type[a_b.unit]==units.type[rel.b] then
            return rel, "b"
        end
        -- b = c / a
        if units.type[c.unit]==units.type[rel.c] and units.type[a_b.unit]==units.type[rel.a] then
            return rel, "a"
        end
    end
end

-- divide
function units_meta.__div(a, b)
    if units.is_unit(a) and tonumber(b) then
        return units.dim(a.value / tonumber(b), a.unit)
    end
    if units.is_unit(b) and tonumber(a) then
        return units.dim(b.value / tonumber(a), b.unit)
    end
    if units.conforms(a, b) then
        return units.convert_value(a, b.unit) / b.value
    end
    if units.is_unit(a) and units.is_unit(b) then
        local relation, div_by = find_division_relations(a, b)
        if relation then
            if div_by=='a' then
                -- b = c / a
                return units.dim(units.convert_value(a, relation.c) / units.convert_value(b, relation.a), relation.b)
            else
                -- a = c / b
                return units.dim(units.convert_value(a, relation.c) / units.convert_value(b, relation.b), relation.a)
            end
        end
        error('Division of ' .. units.explain(a.unit) .. ' by ' .. units.explain(b.unit) .. ' is not defined.')
    end

    error("Division of units by something else is not defined.")
end

-- unit definition
function units.define(def)
    assert(def.name, "Unit name not defined!")
    
    if units.size[def.name] and not def.redefine then
        error("Unit " .. def.name .. " is already defined!")
    end

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
            Q = 10^30,
            R = 10^27,
            Y = 10^24,
            Z = 10^21,
            E = 10^18,
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
            f = 10^-15,
            p = 10^-12,
            a = 10^-18,
            z = 10^-21,
            y = 10^-24,
            r = 10^-30,
        }

        for prefix, size in pairs(prefixes) do
            units.size[prefix .. def.name] = def.size * (size ^ def.SI_dimension)
            units.type[prefix .. def.name] = def.type
            units.is_prefixed[prefix .. def.name] = true
        end 
    end

    if def.binary_prefixes then
        -- https://en.wikipedia.org/wiki/Binary_prefix
        def.SI_dimension = def.SI_dimension or 1

        local prefixes = {
            Yi = 1024^8,
            Zi = 1024^7,
            Ei = 1024^6,
            Pi = 1024^5,
            Ti = 1024^4,
            Gi = 1024^3,
            Mi = 1024^2,
            Ki = 1024
        }

        for prefix, size in pairs(prefixes) do
            units.size[prefix .. def.name] = def.size * size
            units.type[prefix .. def.name] = def.type
            units.is_prefixed[prefix .. def.name] = true
        end 
    end
end

-- adds relation c = a * b
-- where a = c / b and b = c / a are also valid
function units.relate(a, b, c)
    -- TODO - check for nonsense relations
    units.relations[#units.relations+1] = {a=a, b=b, c=c}
end

-- pollutes _G with definited units and constants, enables ~ operator
function units.import_globals()
    for name, const in pairs(units.const) do
        _G[name] = const
    end
    
    for unit, size in pairs(units.size) do
        _G[unit] = units.dim(1, unit)
    end
    for unit, trueSize in pairs(units.alias) do
        _G[unit] = _G[trueSize]
    end

    -- defines ~ operator for unit conversion
    units_meta.__bxor = function(a, b)
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
-- Made more sensible using Wikipedia and https://github.com/sharkdp/purescript-quantities.
-- See also https://numbat.dev/doc/list-units.html

-- LENGTH

units.define{name="m", size=1, type="length", SI_prefixes=true, description="metre"}

-- imperial
units.define{name="in", alias={"inch"}, size=units.size.cm * 2.54, type="length", description="inch"}
units.define{name="ft", alias={"feet", "foot"}, size=units.size['in'] * 12, type="length", description="foot"}
units.define{name="yd", alias={"yard"}, size=0.9144, type="length", description="yard"}
units.define{name="mi", alias={"mile"}, size=units.size.ft * 5280, type="length", description="mile"}
units.define{name="nmi", size=1852, type="length", description="nautical mile"} 

-- astronomical unit
units.define{name="AU", size=149597870700, type="length", description="astronomical unit"}
units.define{name="ly", alias={"lightyear"}, size=9460730472580800, type="length", description="light-year"}
units.define{name="pc", alias={"parsec"}, size=30856775814913673, type="length", description="parserc"}

units.define{name="U", size=units.size.mm * 44.45, type="lenght", description="Rack unit"}

-- TODO - typographical units

-- TIME
units.define{name="s", alias={"second"}, size=1, type="time", SI_prefixes=true, description="second"}
units.define{name="min", alias={"minute"}, size=units.size.s * 60, type="time", description="minute"}
units.define{name="h", alias={"hour"}, size=units.size.min * 60, type="time", description="hour"}
units.define{name="day", size=units.size.h * 24, type="time", description="day"}
units.define{name="week", size=units.size.day * 7, type="time", description="week"}
units.define{name="year", size=units.size.day * 365.25, type="time", description="Julian year"}

-- we do not definte calendar operations in this library

-- MASS
units.define{name="g", size=1/1000, type="mass", SI_prefixes=true, description="gram"}
units.base.mass = "kg" -- base unit for weight is kilogram, but it got prefix so we need to force it to be base unit
units.description.kg = "kilogram"

units.define{name="t", size=units.size.kg * 1000, type="mass", description="metric ton"}

-- imperial (https://en.wikipedia.org/wiki/Avoirdupois)
units.define{name="lb", alias={"pound"}, size=units.size.kg * 0.45359237, type="mass", description="Avoirdupois pound"}
units.define{name="oz", alias={"ounce"}, size=units.size.lb * 1/16, type="mass", description="Avoirdupois ounce"}
-- https://en.wikipedia.org/wiki/Stone_(unit)#Modern_use
units.define{name="stone", size=units.size.kg * 6.350, type="mass", description="stone"}

-- https://en.wikipedia.org/wiki/Troy_weight
units.define{name="ozt", size=units.size.g * 31.10, alias={"oz t"}, type="mass", description="Troy ounce"} -- for gold

-- CURRENT
units.define{name="A", alias={"ampere", "amp"}, size=1, type="current", SI_prefixes=true, description="ampere"} -- ampere

-- TEMPERATURE
local fromK = function(val, unit)
    if unit=='_C' then return units.dim(val.value - 273.15, "C") end
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
    if unit=='_F' then return units.dim((val.value * (9/5)) + 32, "F") end
end

units.define{name="_C", alias={"°C"}, size=1, type="temperature Celsius", explicit_convert=fromC}

-- see https://en.wikipedia.org/wiki/Fahrenheit
local fromF = function(val, unit)
    if unit=='_C' then return units.dim((val.value - 32) * (5/9), "C") end
    if unit=='K' then return units.dim((val.value + 459.67) * (5/9), "K") end
    if unit=='R' then return units.dim(val.value + 459.67, "R") end
end

units.define{name="_F", alias={"°F"}, size=1, type="temperature Farenheit", explicit_convert=fromF, description="Farenheit"}

-- AMOUNT OF SUBSTANCE (MOL)
units.define{name="mol", size=1, type="amount of substance"}

-- ANGLE
units.define{name="turn", size=1, type="angle", description="full circle"} -- I am deviating from official definition to have circle as definition of angle units
units.define{name="rad", alias={"radian"}, size=1/(2*math.pi), type="angle", description="radian"} -- 2 pi radian = 1 circle
units.define{name="deg", alias={"°"}, size=1/360, type="angle", description="degree of arc"}
units.define{name="arcmin", alias={"'", "′"}, size=1/360, type="angle", description="arc minute"}
units.define{name="arcsec", alias={'"', '″'}, size=1/360, type="angle", description="arc second"}
units.define{name="gradian", alias={"gon", "grad", "grade"}, size=1/400, type="angle", description="gradian"}


-- INFORMATION
units.define{name="b", alias={"bit"}, size=1, type="information", SI_prefixes=true, binary_prefixes=true, description="bit"}
units.define{name="B", alias={"byte"}, size=8, type="information", SI_prefixes=true, binary_prefixes=true, description="byte"}

-- TODO https://en.wikipedia.org/wiki/Data-rate_units

-- LUMINOUS INTENSITY (CANDELA)
units.define{name="cd", alias={"candela"}, size=1, type="luminous intensity", description="candela"}

--- derived units: 
-- (based on https://en.wikipedia.org/wiki/International_System_of_Units#Derived_units)
-- (and https://en.wikipedia.org/wiki/File:Physics_measurements_SI_units.png)

-- AREA
units.define{name="m2", alias={"m²"}, size=1, type="area", SI_prefixes=true, SI_dimension=2, description="square metre"}
units.relate('m', 'm', 'm2')

-- VOLUME
units.define{name="m3", alias={"m³"}, size=1, type="volume", SI_prefixes=true, SI_dimension=3, description="cubic metre"}
units.relate('m2', 'm', 'm3')
units.define{name="cc", size=units.size.cm3, type="volume"} -- for motocycle engines :-)
units.define{name="l", alias={"liter", "litre"}, size=units.size.m3 * (1/1000), type="volume", SI_prefixes=true, description="litre"}

units.define{name="barrel", size=units.size.l * 158.987, type="volume"} -- for oil

-- FREQUENCY
units.define{name="Hz", alias={"cps"}, size=1, type="frequency", SI_prefixes=true, description="hertz"}
-- TODO - Hz to meters of wavelenght and vice versa -  https://commsbrief.com/wavelength-calculator-calculating-wavelength-of-radio-waves/

units.define{name="BPM", size=units.size.Hz/60, type="frequency", description="beats per minute"}
units.define{name="rpm", size=units.size.Hz/60, type="frequency", description="revolutions per minute"}

units.relate("rpm", "min", "turn")

-- VELOCITY (aka SPEED)
units.define{name="m_s", alias={"m/s"}, size=1, type="velocity", description="metre per second"}
units.relate('m_s', 's', 'm')
units.define{name="km_h", alias={"km/h"}, size=units.size.km / units.size.h, type="velocity", description="kilometer per hour"}
units.relate('km_h', 'h', 'km')
units.define{name="mph", size=units.size.mi / units.size.h, type="velocity", description="miles per hour"}
units.define{name="mach", size=units.size.m_s * 331.46, type="velocity"} -- for fighter aircraft
units.define{name="kn", alias={"knot"}, size=units.size.nmi / units.size.h, type="velocity", description="knot"} -- for aircraft and boats

units.const.c = units.dim(299792458, "m_s") -- https://en.wikipedia.org/wiki/Speed_of_light

-- ACCELERATION
units.define{name="m_s2", size=1, type="acceleration"} -- (https://en.wikipedia.org/wiki/Metre_per_second_squared) nobody uses this unit as it's hardly measurable 
units.relate('m_s2', 's', 'm_s') -- I have it there only for Newton definition

units.const.g = units.dim(9.80665, "m_s2")

-- FORCE
units.define{name="N", alias={"newton"}, size=1, type="force", SI_prefixes=true, description="newton"}
units.relate('kg', 'm_s2', 'N')

-- PRESSURE
units.define{name="Pa", alias={"pascal"}, size=1, type="pressure", SI_prefixes=true, description="pascal"}
units.relate("N", "Pa", "m2")
units.define{name="bar", size=units.size.kPa * 100, type="pressure", SI_prefixes=true}
units.define{name="atm", alias={"atmosphere"}, size=units.size.kPa*101.325, type="pressure", description="standard atmosphere"}
-- meterologists use mbar, aviators hPa, both means is the same quantity
units.define{name="psi", size=units.size.kPa * 6.894757, type="pressure", description="pound per square inch"}
units.define{name="ksi", size=units.size.MPa * 6.895, type="pressure", description="kilopound per square inch"}
units.define{name="Mpsi", size=units.size.GPa * 6.894757, type="pressure", description="megapound per square inch"}
units.define{name="Torr", size=units.size.atm / 760, type="pressure"}

-- ENERGY
units.define{name="J", alias={"joule"}, size=1, type="energy", SI_prefixes=true, description="joule"}
units.relate("N", "m", "J")
units.define{name="cal", alias={"c", "calorie"}, size=units.size.J * 4.1868, type="energy", description="calorie", SI_prefixes=true}
units.define{name="Wh", size=units.size.J * 3600, type="energy", SI_prefixes=true, description="Watt-hour"}
units.define{name="BTU", size=units.size.kJ * 1.0551, type="energy", description="British thermal unit"}

-- POWER
units.define{name="W", alias={"watt"}, size=1, type="power", SI_prefixes=true, description="watt"}
units.relate("W", "s", "J")

-- ELECTRICAL UNITS
units.define{name="C", alias={"Coulomb"}, size=1, type="electric charge", SI_prefixes=true, description="Coulomb"}
units.relate("A", "s", "C")

-- elementary charge
units.const.e = units.dim(1.602176634e-19, "C")

units.define{name="V", alias={"volt"}, size=1, type="electric potential", SI_prefixes=true, description="Volt"}
units.relate("J", "C", "V")
units.relate("W", "A", "V")

units.define{name="ohm", alias={"Ω"}, size=1, type="electric resistance", SI_prefixes=true, description="Ohm"}
units.relate("ohm", "A", "V")

units.define{name="S", alias={"siemens"}, size=1, type="electric conductance", SI_prefixes=true, description="Siemens"}
units.relate("S", "V", "A")

units.define{name="F", alias={"farad"}, size=1, type="electric conductance", SI_prefixes=true, description="Siemens"}
units.relate("F", "V", "C")

--[[
TODO

weber :=               V s         // magnetic flux
weber ||| magnetic_flux
Wb :=                  weber

henry :=               Wb/A        // inductance
henry ||| inductance
henries :=             henry       // Irregular plural
H :=                   henry

tesla :=               Wb/m^2      // magnetic flux density
tesla ||| magnetic_flux_density
T :=                   tesla

]]

-- TODO all radioactive units

-- some sanity checks if logic it's not broken
local dim = units.dim
assert(dim(100, "cm") == dim(1, "m")) 
assert(dim(1, "m") + dim(6, "cm") == dim(106, "cm"))

return units