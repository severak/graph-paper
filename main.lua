-- GRAPH PAPER vector graphics editor (prototype)
-- (c) Severák 2023
-- MIT licensed

local geom = require "severak.geom"
local gui = require "severak.gui"
local push = table.insert

-- data of our drawing
local model = {}
-- each item is table with {type=type, d=coordinate or coordinates}
-- with following types and coordinates:
-- point = {x=x, y=y}
-- line = {{x=x1,y=y1}, {x=x2, y=x2}}
-- circle = {x=x, y=y, r=r}
-- polygon = {{x=x1,y=y1}, {x=x2, y=x2}, ...}
-- rectangle = {x=x, y=y, w=width, h=height}
-- TODO dimension marker
-- TODO infinite line

local modes = {
    p = 'point', -- adding point
    l = 'line', -- adding lines by two points (or by point, size and another point to set direction)
    r = 'rectangle', -- adding rectangles
    c = 'circle', -- adding circles
    -- adding arcs
    -- adding dims
    -- selecting things
    -- deleting things
    -- move things around
    d = 'distance', -- measuring from point to point
}

local mode = 'intro'
local prev_point = false

local grid_spacing = 20

local selected = {}

screen = gui.screen()
gui.switch(screen)

menu = screen:panel{}
menu:label{text="Draw: "}
menu:button{text="point", on_click=function() set_mode"point" end}
menu:button{text="line", on_click=function() set_mode"line" end}
menu:button{text="rectangle", on_click=function() set_mode"rectangle" end}
menu:button{text="circle", on_click=function() set_mode"circle" end}
menu:label{text=" | other: "}
menu:button{text="Distance", on_click=function() set_mode"distance" end}
menu:button{text="Select", on_click=function() set_mode"select"; selected={} end}
menu:button{text="Grid size", on_click=function() cycle_grid_size() end}
menu:button{text="Exit", on_click=function() love.event.quit() end}

statusbar = screen:panel{y=-1, h=20}
status = statusbar:label{text="Welcome to Graph paper prototype"}
statusbar:label{text="|"}
size = statusbar:input{placeholder="enter size..."}
size.visible = false

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

function set_mode(new_mode)
    local helps = {
        point = 'Click to add a point...',
        line = 'Click two times to add line...',
        circle = 'Click to add circle...',
        rectangle = 'Click to add rectangle...',
        select = 'Click near objects to select them...'
    }
    if helps[new_mode] then
        status.text = helps[new_mode]
    end
    if new_mode=='line' then
        size.visible = true
    else
        size.visible = false
        size.value = ""
    end
    prev_point = false
    mode = new_mode
end

function cycle_grid_size()
    -- cycle trough grid spacings
    if grid_spacing==0 then 
        grid_spacing=10
    elseif grid_spacing==10 then
        grid_spacing=20
    elseif grid_spacing==20 then
        grid_spacing=40
    elseif grid_spacing==40 then 
        grid_spacing=80 
    elseif grid_spacing==80 then 
        grid_spacing=0
    end
end


function load_model(filename, offx, offy, zoom)
    offx=offx or 0
    offy=offy or 0
    zoom=zoom or 1
    local model = {}
    for line in io.lines(filename) do
        if line~="" and string.sub(line, 1, 1)~='#' then
            local coords = {}
            local tokcnt = 0
            local addtype = false
            local prev = false
            local toks = {}
            for token in string.gmatch(line, "[^%s]+") do
                if addtype=='L' then
                    if tokcnt % 2 == 1 then
                        prev = token
                    else
                        push(coords, {x=tonumber(prev)*zoom+offx, y=tonumber(token)*zoom+offy})
                    end
                end
                if tokcnt==0 then
                    addtype = token
                end
                tokcnt = tokcnt + 1
                push(toks, token)
            end
            if addtype=='L' then
                push(model, {type='line', d=coords})
            elseif addtype=='C' then
                push(model, {type='circle', d={x=tonumber(toks[2])*zoom+offx, y=tonumber(toks[3])*zoom+offy, r=tonumber(toks[4])*zoom}})
            end
        end
    end
    return model
end

function snap(x, y)
    -- TODO - snapping prepinat i jinak nez gridem
    -- TODO - nefunguje snapping nad rozmer
    if grid_spacing > 0 then
        local fourth = grid_spacing / 4
        for ord, item in pairs(model) do
            if item.type=='point' or item.type=='circle' then
                if x>item.d.x-fourth and x<item.d.x+fourth and y>item.d.y-fourth and y<item.d.y+fourth then
                    return item.d.x, item.d.y
                end  
            elseif item.type=='line' then
                if x>item.d[1].x-fourth and x<item.d[1].x+fourth and y>item.d[1].y-fourth and y<item.d[1].y+fourth then
                    return item.d[1].x, item.d[1].y
                end
                if x>item.d[2].x-fourth and x<item.d[2].x+fourth and y>item.d[2].y-fourth and y<item.d[2].y+fourth then
                    return item.d[2].x, item.d[2].y
                end
            end
        end
        for ix=0,love.graphics.getWidth(), grid_spacing do
            for iy=0,love.graphics.getHeight(), grid_spacing do
                if x>ix-fourth and x<ix+fourth and y>iy-fourth and y<iy+fourth then
                    return ix, iy
                end
            end 
        end
    end
    return x, y
end

function love.load(args)
    love.window.setTitle("Graph paper (prototype)")
end

function love.draw()
    -- draw grid
    if grid_spacing > 0 then
        love.graphics.setColor(85/255,85/255,85/255)
        for x=0,love.graphics.getWidth(), grid_spacing do
            love.graphics.line(x, 0, x, love.graphics.getHeight())    
        end
        for y=0,love.graphics.getHeight(), grid_spacing do
            love.graphics.line(0, y, love.graphics.getWidth(), y)    
        end
    end
    
    -- drawing all drawn geometry
    for ord, item in ipairs(model) do
        love.graphics.setColor(255/255,255/255,255/255)
        if selected[item] then
            love.graphics.setColor(0/255,255/255,0/255)
        end
        if item.type=='point' then
            love.graphics.rectangle('fill', item.d.x-1, item.d.y-1, 3, 3)
        elseif item.type=='line' then
            love.graphics.line(item.d[1].x, item.d[1].y, item.d[2].x, item.d[2].y)
        elseif item.type=='rectangle' then
            love.graphics.rectangle('line', item.d.x, item.d.y, item.d.w, item.d.h)
        elseif item.type=='circle' then
            love.graphics.rectangle('line', item.d.x, item.d.y, 1, 1)
            love.graphics.circle('line', item.d.x, item.d.y, item.d.r)
        end
    end

    -- draw currently drawed geometry
    local mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x, mouse_y = snap(mouse_x, mouse_y)

    local obj_size = false
    if size.value~="" and tonumber(size.value) then
        obj_size = tonumber(size.value)
    end

    love.graphics.setColor(255/255,85/255,255/255)
    if mode=='line' and prev_point then
        if obj_size then
            -- if size is set
            local diff_x, diff_y = mouse_x-prev_point.x, mouse_y-prev_point.y
            if math.abs(diff_x)>math.abs(diff_y) then
                if diff_x>0 then
                    love.graphics.line(prev_point.x, prev_point.y, prev_point.x + obj_size, prev_point.y)
                else
                    love.graphics.line(prev_point.x, prev_point.y, prev_point.x - obj_size, prev_point.y)
                end
            else
                if diff_y>0 then
                    love.graphics.line(prev_point.x, prev_point.y, prev_point.x, prev_point.y + obj_size)
                else
                    love.graphics.line(prev_point.x, prev_point.y, prev_point.x, prev_point.y - obj_size)
                end
            end
            love.graphics.rectangle('fill', prev_point.x-1, prev_point.y-1, 3, 3)
        else
            love.graphics.line(prev_point.x, prev_point.y, mouse_x, mouse_y)
            love.graphics.rectangle('fill', prev_point.x-1, prev_point.y-1, 3, 3)
            love.graphics.rectangle('fill', mouse_x-1, mouse_y-1, 3, 3)
        end
    end
    if mode=='rectangle' and prev_point then
        love.graphics.rectangle('line', prev_point.x, prev_point.y, mouse_x-prev_point.x, mouse_y-prev_point.y)
    end
    if mode=='circle' and prev_point then
        love.graphics.rectangle('fill', prev_point.x-1, prev_point.y-1, 3, 3)
        love.graphics.circle('line', prev_point.x, prev_point.y, geom.distance(prev_point, {x=mouse_x, y=mouse_y}))
    end
    if mode=='distance' and prev_point then
        local mid = geom.midpoint(prev_point, {x=mouse_x, y=mouse_y})
        love.graphics.line(prev_point.x, prev_point.y, mouse_x, mouse_y)
        love.graphics.setColor(255/255,255/255,85/255)
        local txt = string.format("%g px", geom.distance(prev_point, {x=mouse_x, y=mouse_y}))
        love.graphics.print(txt, mid.x, mid.y)
    end

    -- draw program UI
    gui.draw()
end

function love.mousereleased(x, y, button)
    if not gui.mousereleased(x,y,button) then
        return
    end
    x, y = snap(x, y)
    mouse_x, mouse_y = x, y
    if mode=='point' then
        push(model, {type='point', d={x=x, y=y}})
    elseif mode=='line' then

        local obj_size = false
        if size.value~="" and tonumber(size.value) then
            obj_size = tonumber(size.value)
        end

        if prev_point then
            if obj_size then
                -- if size is set
                local diff_x, diff_y = mouse_x-prev_point.x, mouse_y-prev_point.y
                if math.abs(diff_x)>math.abs(diff_y) then
                    if diff_x>0 then
                        push(model, {type='line', d={{x=prev_point.x, y=prev_point.y}, {x=prev_point.x + obj_size, y=prev_point.y}}})
                    else
                        push(model, {type='line', d={{x=prev_point.x, y=prev_point.y}, {x=prev_point.x - obj_size, y=prev_point.y}}})
                    end
                else
                    if diff_y>0 then
                        push(model, {type='line', d={{x=prev_point.x, y=prev_point.y}, {x=prev_point.x, y=prev_point.y + obj_size}}})
                    else
                        push(model, {type='line', d={{x=prev_point.x, y=prev_point.y}, {x=prev_point.x, y=prev_point.y - obj_size}}})
                    end
                end
                prev_point = false
            else
                push(model, {type='line', d={{x=prev_point.x, y=prev_point.y}, {x=mouse_x, y=mouse_y}}})
                prev_point = false
            end
        else
            prev_point = {x=x, y=y}
        end
    elseif mode=='rectangle' then
        if prev_point then
            push(model, {type='rectangle', d={x=prev_point.x, y=prev_point.y, w=mouse_x-prev_point.x, h=mouse_y-prev_point.y}})
            prev_point = false
        else
            prev_point = {x=x, y=y}
        end    
    elseif mode=='circle' then
        if prev_point then
            push(model, {type='circle', d={x=prev_point.x, y=prev_point.y, r=geom.distance(prev_point, {x=mouse_x, y=mouse_y})}})
            prev_point = false
        else
            prev_point = {x=x, y=y}
        end
    elseif mode=='distance' then
        if prev_point then
            prev_point = false
        else
            prev_point = {x=x, y=y}
        end
    elseif mode=='select' then
        -- TODO - selecting by rectangle over objects
        local fourth = 2
        if grid_spacing==0 then
            fourth = grid_spacing / 4
        end
        for ord, item in pairs(model) do
            if item.type=='point' then
                if x>=item.d.x-1 and x<=item.d.x+1 and y>=item.d.y-1 and y<=item.d.y+1 then
                    selected[item] = true
                end
            elseif item.type=='line' then
                -- TODO - measure distance from clicked point to line, if d<fourth it was clicked
                if geom.almost_eq(geom.distance(item.d[1], item.d[2]), geom.distance(item.d[1], {x=x, y=y}) + geom.distance(item.d[2], {x=x, y=y}), fourth * 4) then
                    selected[item] = true
                end
            elseif item.type=='circle' then
                if geom.almost_eq(geom.distance(item.d, {x=x, y=y}), item.d.r, fourth) then
                    selected[item] = true
                end
            end
            -- TODO - select rectangles by clicking near them
        end
    end
end

function love.keyreleased(key)
    if not gui.keyreleased(key) then
        return
    end
    if key=='g' then
        cycle_grid_size()
    elseif key=='delete' then
        -- remove selected items
        local keep = {}
        for ord,item in ipairs(model) do
            if not selected[item] then
                push(keep, item)
            end
        end
        model = keep
        selected = {}
    elseif modes[key] then
        -- switches mode
        set_mode(modes[key])
    end
end

function love.textinput(text)
    gui.textinput(text)
end

function love.update(dt)
    gui.update(dt)
end

require "wincom"