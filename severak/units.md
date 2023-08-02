# severak.units

This library is for unit conversion and tracking to lua language. It adds units to your numbers and convert it automatically when you when you perform arithmetics on it and it ensures you don't add apples to oranges.

## loading library

Call `units = require "severak.units"` to get reference to a library.

Then you can use `units.import_globals()` to bring specimen units to global scope (`m`, `km` etc). These are just units with size one, created in this style: `_G.m = units.dim(1, "m")`.  This function also enables `~` unit conversion operator.

## unit creation

You can create units in three ways:

- using `units.dim(size, unit_name)` function, e.g. `meter = units.dim(1, "m")`
- using `units.parse(text)` function to parse user input, e.g. `units.parse "1m"`
- by multiplying number with unit, e.g. `meter = 1*m` (when used `units.import_globals()` before)

While all three methods have same result I will use third option in rest of this documentation as it's more useful in command line calculations.

## arithmetics

You can use these units as if they were numbers:

```
> 3*m - 3*cm
297 cm
```

Units is changed automatically when it makes sense:

```
> 3*m * 2*m
6 m2
```

Sometimes units can also disappear during computation because they cancel each other:

```
> (3*m) / (1.5*m)
2.0
```

Note that parentheses were used to get correct result as `/` and `*` operators [have same precedence in Lua](https://www.lua.org/manual/5.3/manual.html#3.4.8) and without parentheses this will be understood (badly) like this:

```
> 3*m / 1.5*m
2 m2
> ((3*m) / 1.5) * m
2 m2
```

I cannot prevent this error as I am not changing Lua syntax but I can prevent you from adding apples to oranges:

```
> 1*kg + 2*m
.\severak\units.lua:130: Only conformal units can be added. Cannot add apples to oranges.
stack traceback:
        [C]: in function 'assert'
        .\severak\units.lua:130: in metamethod '__add'
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

This will be optimised in the future.

## functions reference

- `units.dim(value, unit_name)` - creates unit with value `value` and unit `unit_name`
- `value, unit_name = units.unpack(val)` - unpacks numeric `value` and `unit_name` from unit
- `units.is_unit(val)` - checks if `val` is unit
- `units.conforms(a, b)` - checks if units are conformal (if one can be converted to another)
- `units.convert(val, unit)` - converts `val` to other unit `unit`
- `units.convert_value(val, unit)` - converts `val` to other unit `unit` and returns numeric value only ()
- `units.parse(val)` - parses unit from textual description, if it cannot parse it returns `nil`
- `units.define(def)` - defines new unit, see *custom units* below
- `units.relate(a, b, c)` - adds unit relation `c = a * b` where `a = c / b` and `b = c / a` are also valid
- `units.import_globals()` - import specimens units to globals, addds `~` operator for easier conversions

## custom units

*TBD*

## internals

Unlike [Frink](https://frinklang.org/) and [Insect](https://insect.sh/) this library does not use [dimensional analysis](https://en.wikipedia.org/wiki/Dimensional_analysis) but simple data model and lot of decision tables. Units relations are not automatic and have to be defined.

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

*TBD - Mars Climate Orbiter - Ns vs lbf impulse*