# severak.units

This library is for unit conversion and tracking to Lua language. It adds units to your numbers and convert those automatically when you when you perform arithmetics on it and it ensures you don't add apples to oranges.

This is implemented in pure Lua using metatables.

## loading library

Call `units = require "severak.units"` to get reference to a library.

Then you can use `units.import_globals()` to bring specimen units to global scope (`m`, `km` etc). These are just units with size of one, created in this style: `_G.m = units.dim(1, "m")`.  This function also enables `~` unit conversion operator.

## unit creation

You can create units in three ways:

- using `units.dim(size, unit_name)` function, e.g. `meter = units.dim(1, "m")`
- using `units.parse(text)` function to parse user input, e.g. `meter = units.parse "1m"`
- by multiplying number with unit, e.g. `meter = 1*m` (when used `units.import_globals()` before)

While all three methods have same result I will use third option in rest of this documentation as it's more useful in command line calculations.

## supported units

Currently supported units are:

```
A (current - ampere)
AU (length - astronomical unit)
B (information - byte)
BPM (frequency - beats per minute)
BTU (energy - British thermal unit)
C (electric charge - Coulomb)
F (electric conductance - Siemens)
Hz (frequency - hertz)
J (energy - joule)
K (temperature - Kelvin)
Mpsi (pressure - megapound per square inch)
N (force - newton)
Pa (pressure - pascal)
R (temperature - Rankine)
S (electric conductance - Siemens)
Torr (pressure)
U (lenght - Rack unit)
V (electric potential - Volt)
W (power - watt)
Wh (energy - Watt-hour)
_C (temperature Celsius)
_F (temperature Farenheit - Farenheit)
arcmin (angle - arc minute)
arcsec (angle - arc second)
atm (pressure - standard atmosphere)
b (information - bit)
bar (pressure)
barrel (volume)
cal (energy - calorie)
cc (volume)
cd (luminous intensity - candela)
day (time - day)
deg (angle - degree of arc)
ft (length - foot)
g (mass - gram)
gradian (angle - gradian)
h (time - hour)
in (length - inch)
km_h (velocity - kilometer per hour)
kn (velocity - knot)
ksi (pressure - kilopound per square inch)
l (volume - litre)
lb (mass - Avoirdupois pound)
ly (length - light-year)
m (length - metre)
m2 (area - square metre)
m3 (volume - cubic metre)
m_s (velocity - metre per second)
m_s2 (acceleration)
mach (velocity)
mi (length - mile)
min (time - minute)
mol (amount of substance)
mph (velocity - miles per hour)
nmi (length - nautical mile)
ohm (electric resistance - Ohm)
oz (mass - Avoirdupois ounce)
ozt (mass - Troy ounce)
pc (length - parserc)
psi (pressure - pound per square inch)
rad (angle - radian)
rpm (frequency - revolutions per minute)
s (time - second)
stone (mass - stone)
t (mass - metric ton)
turn (angle - full circle)
week (time - week)
yd (length - yard)
year (time - Julian year)
```

## constants

Some useful values are provided as `units.const`:

- `c` - speed of light
- `e` - elementary charge
- `g` - gravity of earth (acceleration)

## arithmetics

You can use these units as if they were numbers:

```
> 3*m - 3*cm
297 cm
```

Units are changed automatically when it makes sense:

```
> 3*m * 2*m
6 m2
```

Sometimes units can also disappear during computation because they cancel each other:

```
> (3*m) / (1.5*m)
2.0
```

Note that I used parentheses to get correct result because  `/` and `*` operators [have the same precedence in Lua](https://www.lua.org/manual/5.3/manual.html#3.4.8) and without parentheses this will be understood (badly) in this way:

```
> 3*m / 1.5*m
2 m2
> ((3*m) / 1.5) * m
2 m2
```

I cannot prevent this error as I am not changing Lua syntax but I can prevent you from adding apples to oranges:

```
> 10*kg + 3*cm
.\severak\units.lua:172: You cannot add kg (mass - kilogram) to cm (length).
stack traceback:
        [C]: in function 'assert'
        .\severak\units.lua:172: in metamethod '__add'
        stdin:1: in main chunk
        [C]: in ?
```

## units conversion

Use `units.convert(val, unit_name)` to convert your `val` to specific `unit_name`, e.g. `units.convert(1*AU, "km")`.

If `units.import_globals()` function was called there is also `~` operator for easier conversion of units:

```
> 1*AU ~ km
149597870.7 km
```

If you want to display optimal unit for result of your computation use `units.best(val, possible_units)` function:

```
> units.best(3600*s, {day, h, min, s})
1 h
```

Note that first unit smaller than converted value is selected which can lead to decimal numbers, e.g.:

```
> units.best(1435*mm, {km, m, cm, mm})
1.435 m
```

*TBS - units.compound*

## functions reference

- `units.dim(value, unit_name)` - creates unit with value `value` and unit `unit_name`
- `value, unit_name = units.unpack(val)` - unpacks numeric `value` and `unit_name` from unit
- `units.is_unit(val)` - checks if `val` is unit
- `units.is_conformal(a, b)` - checks if units are conformal (if one can be converted to another)
- `units.convert(val, unit)` - converts `val` to other unit `unit`
- `units.convert_value(val, unit)` - converts `val` to other unit `unit` and returns numeric value only (useful for doing some more involved computation)
- `units.best(val, {possible_units...})` - chooses optimal unit for presentation
- `units.parse(val)` - parses unit from textual description, if it cannot parse it returns `nil`
- `units.define(def)` - defines new unit, see *custom units* below
- `units.relate(a, b, c)` - adds unit relation `c = a * b` where `a = c / b` and `b = c / a` are also valid
- `units.import_globals()` - import specimens units to globals, adds `~` operator for easier conversions

## custom units

In some cases new unit can be expressed as combination of existing units. For example you can define inch per second (for [audio tape speed measurement](https://en.wikipedia.org/wiki/Audio_tape_specifications#Tape_speeds)) in this way:

```
> ips = inch / second
> ips
0.0254 m_s
> reel2reel = 7.5 * ips
```

The problem is that you cannot convert to this unit:

```
> reel2reel ~ ips
0.1905 m_s
```

You need to define it's size relative to base unit of particular type and it's relation to other units:

```
> units.define{name="ips", size=0.0254, type="velocity"}
> units.relate('ips', 's', 'in')
```

After calling `units.import_globals()` this now works as expected:

```
> 19.05 * (cm/s) ~ ips
7.5 ips
```

There are more tricks hidden in `units.define` but those are not documented yet.

## internals

Unlike [Frink](https://frinklang.org/) and [Numbat](https://numbat.dev/) this library does not use [dimensional analysis](https://en.wikipedia.org/wiki/Dimensional_analysis) but simple data model and lot of decision tables. Units relations are not automatic and has to be defined.

This is more error-prone but leads to more natural feeling when doing simple calculations.

## practical examples

What is average speed of bus if it takes 35 minutes to travel 18 km?

```
> ((18*km) / (35*min)) ~ km_h
30.85714286 km_h
```

How many 20 liter buckets do I need to empty 10 cm of water from 3 by 4 meters long room?

```
> (3*m * 4*m * 10*cm) / (20*l)
60.0
```

How long does it take for light from Sun to reach the Earth?

```
> 1*AU / c ~ min
8.316746397 min
```

*TBD - speed of sound under the bridge*

*TBD distance to lightning*

*Grace Hooper wire*

http://dataphys.org/list/grace-hopper-nanoseconds/

*TBD - Mars Climate Orbiter - Ns vs lbf impulse*