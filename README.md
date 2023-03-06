# graph-paper

simple vector editor / language / CAD for primitive technology

**Work in progress.** Not yet usable.

## idea and motivation

There is no intuitive CAD aimed at hobbyists. Idea is having something like virtual equivalent of good old graph paper. Click on one crossing get point A, on another and get point B and voila - you have your first line segment!

## implementation details

Firstly I will implement usable environment where you can use very simple language to draw your ideas.

Then I will create simple click and click GUI which will use aforementioned language as file format.

## TODO
- opening and saving files
- drawing object of specified size (implemented just for lines now)

### later

- intersections
- cutting objects
- zooming and moving
- export to SVG
- import from SVG (maybe using [svglover](https://github.com/globalcitizen/svglover))
- import from GeoJSON
- undo and redo
- drawing circle arcs
- styling of drawing
- symbols
- text
- grouping objects
- export for print