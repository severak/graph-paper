-- simple GUI for Graph paper (LOVE 2D)
-- (c) Severák 2023
-- MIT licensed

-- This is not in any way feature complete GUI library.
-- 
-- It just works for my project.

-- TODO - have some form of recycling functions (extend etc)
-- TODO - do not click trough widgets

local push = table.insert

-- checks if GUI element is in BBOX
function in_bbox(x, y, bbox)
    return x>=bbox.x and x<=(bbox.x+bbox.w) and y>=bbox.y and y<=(bbox.y+bbox.h)
end

-- computes coordinates of widget
function fix_pos(def)
    def.visible = def.visible or true
    def.x = def.x or 0
    def.y = def.y or 0
    def.padding = def.padding or 2
    if def.x < 0 then
        def.x = love.graphics.getWidth() - def.w + def.x
    end
    if def.y < 0 then
        def.y = love.graphics.getHeight() - def.h + def.y
    end
    if def.padding then
        def.w = def.w + (def.padding * 2)
        def.h = def.h + (def.padding * 2)
    end
end

local gui = {}
gui.screens = {}
gui.focused = false
gui.font = love.graphics.getFont()
gui.blinktime = 0
gui.showcursor = false

-- DOS color scheme from https://www.colorbook.io/colorschemes/view/1475
gui.colors = {
    border = {r=85/255, g=85/255, b=85/255},
    background = {r=170/255, g=170/255, b=170/255},
    text = {r=0, g=0, b=0},
    input = {r=255/255, g=255/255, b=255/255},
    yellow = {r=255/255, g=255/255, b=85/255}
}

function gui.set_color(color)
    love.graphics.setColor(color.r, color.g, color.b)
end

-- label
local label = {}

function label.new(def)
    def.text = def.text or error "Label needs defined text!"
    def.w = def.w or gui.font:getWidth(def.text)
    def.h = def.h or gui.font:getHeight()
    fix_pos(def)
    return setmetatable(def, {__index=label})
end

function label:draw()
    if not self.visible then return end
    gui.set_color(self.color or gui.colors.text)
    love.graphics.print(self.text, self.x + self.padding, self.y + self.padding)
end

function label:mousereleased() end
function label:textinput() end
function label:keyreleased() end
-- no onclick etc as label is not interactive

-- button
local button = {}

function button.new(def)
    if def.text then
        def.w = def.w or gui.font:getWidth(def.text)
        def.h = def.h or gui.font:getHeight()
    elseif def.image then
        if type(def.image)=="string" then
            def.image = love.graphics.newImage(def.image)
        end
        def.w = def.image:getWidth()
        def.h = def.image:getHeight()
        def.padding = 0
    else
        error "Button needs to have image or text defined."
    end
    fix_pos(def)
    return setmetatable(def, {__index=button})
end

function button:on_click()
    -- nop
end

function button:draw()
    if not self.visible then return end
    gui.set_color(gui.colors.background)
    love.graphics.rectangle("fill",self.x, self.y, self.w, self.h)
    gui.set_color(gui.colors.border)
    love.graphics.rectangle("line",self.x, self.y, self.w, self.h)
    if self.text then
        gui.set_color(gui.colors.text)
        love.graphics.print(self.text, self.x + self.padding, self.y + self.padding)
    elseif self.image then
        love.graphics.draw(self.image, self.x, self.y)
    end
    -- TODO - drawing title
end

function button:mousereleased(x,y,button)
    if not self.visible then return end
    if in_bbox(x,y,self) then
        self:on_click()
        return true
    end
end

function button:textinput() end
function button:keyreleased() end -- TODO - shortcuts

-- input
local input = {}

function input.new(def)
    def.x = def.x or 0
    def.y = def.y or 0
    if def.placeholder then
        def.w = def.w or gui.font:getWidth(def.placeholder)
    elseif not def.w then
        def.w = gui.font:getWidth("brambora")
    end
    def.h = def.h or gui.font:getHeight()
    fix_pos(def)
    def.value = def.value or ""
    return setmetatable(def, {__index=input})
end

function input:draw()
    if not self.visible then return end
    gui.set_color(gui.colors.input)
    if gui.focused == self then
        gui.set_color(gui.colors.yellow)
    end
    love.graphics.rectangle("fill",self.x, self.y, self.w, self.h)
    gui.set_color(gui.colors.border)
    love.graphics.rectangle("line",self.x, self.y, self.w, self.h)
    if self.value ~= "" or gui.focused==self then
        gui.set_color(gui.colors.text)
        local cursor = ""
        if gui.focused == self and gui.showcursor then
            cursor = "|"
        end
        love.graphics.print(self.value .. cursor, self.x + self.padding, self.y + self.padding)
    elseif self.placeholder then
        gui.set_color(gui.colors.border)
        love.graphics.print(self.placeholder, self.x + self.padding, self.y + self.padding)
    end
end

function input:mousereleased(x,y,button)
    if not self.visible then return end
    if in_bbox(x,y,self) then
        gui.focused = self
        return true
    end
end

function input:textinput(text)
    if not self.visible then return end
    if gui.focused==self then
        self.value = self.value .. text
        return true
    end
end

function input:keyreleased(key)
    if not self.visible then return end
    if gui.focused==self then
        if key=="backspace" then
            self.value = string.sub(self.value, 1, -2) -- TODO utf8
        elseif key=="return" or key=="tab" or key=="escape" then
            gui.focused = false
        end
        return true
    end
end

local panel = {}

function panel.new(def)
    def.children = {}
    if not def.w then
        def.w = love.graphics.getWidth()
    end
    def.h = def.h or gui.font:getHeight()
    fix_pos(def)
    setmetatable(def, {__index=panel})
    return def
end

function panel:next_x()
    if #self.children > 0 then
        local last = self.children[#self.children]
        return last.x + last.w + self.padding
    end
    return 0
end

function panel:label(def)
    def.x = self:next_x()
    def.y = self.y
    local widget = label.new(def)
    push(self.children, widget)
    if widget.h > self.h then 
        self.h = widget.h
    end
    return widget
end

function panel:button(def)
    def.x = self:next_x()
    def.y = self.y
    local widget = button.new(def)
    push(self.children, widget)
    if widget.h > self.h then 
        self.h = widget.h
    end
    return widget
end

function panel:input(def)
    def.x = self:next_x()
    def.y = self.y
    local widget = input.new(def)
    push(self.children, widget)
    if widget.h > self.h then 
        self.h = widget.h
    end
    return widget
end

function panel:draw()
    if not self.visible then return end
    gui.set_color(gui.colors.background)
    love.graphics.rectangle("fill",self.x, self.y, self.w, self.h)
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function panel:mousereleased(x,y,button)
    if not self.visible then return end
    local done = false
    for _, child in ipairs(self.children) do
        done = child:mousereleased(x, y, button) or done
    end
    if in_bbox(x,y,self) then
        return true
    end
    return done
end

function panel:textinput(text)
    if not self.visible then return end
    local done = false
    for _, child in ipairs(self.children) do
        done = child:textinput(text) or done
    end
    return done
end

function panel:keyreleased(key)
    if not self.visible then return end
    local done = false
    for _, child in ipairs(self.children) do
        done = child:keyreleased(key) or done
    end
    return done
end

-- TODO dialog which obscures rest of the screen

-- screen
local screen = {}

function screen:label(def)
    local b = label.new(def)
    push(self.children, b)
    return b
end

function screen:button(def)
    local b = button.new(def)
    push(self.children, b)
    return b
end

function screen:input(def)
    local b = input.new(def)
    push(self.children, b)
    return b
end

function screen:panel(def)
    local b = panel.new(def)
    push(self.children, b)
    return b
end

function screen:draw()
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function screen:mousereleased(x, y, button)
    local done = false
    for _, child in ipairs(self.children) do
        done = child:mousereleased(x, y, button) or done
    end
    return done
end

function screen:textinput(text)
    local done = false
    for _, child in ipairs(self.children) do
        done = child:textinput(text) or done
    end
    return done
end

function screen:keyreleased(key)
    local done = false
    for _, child in ipairs(self.children) do
        done = child:keyreleased(key) or done
    end
    return done
end

-- main gui functions:
function gui.screen()
    local s = {}
    s.active = false
    s.children = {}
    setmetatable(s, {__index=screen})
    push(gui.screens, s)
    return s
end

function gui.switch(screen)
    for _, scr in ipairs(gui.screens) do
        scr.active = screen==scr
    end
end

-- these will be called from LOVE2D

function gui.draw()
    gui.font = love.graphics.getFont()
    for _, scr in ipairs(gui.screens) do
        if scr.active then
            scr:draw()
        end
    end
end

function gui.mousereleased(x, y, button)
    local done = false
    gui.focused = false
    for _, scr in ipairs(gui.screens) do
        if scr.active then
            done = scr:mousereleased(x, y, button) or done
        end
    end
    return not done
end

function gui.textinput(text)
    local done = false
    for _, scr in ipairs(gui.screens) do
        if scr.active then
            done = scr:textinput(text) or done
        end
    end
    return not done
end

function gui.keyreleased(key)
    local done = false
    for _, scr in ipairs(gui.screens) do
        if scr.active then
            done = scr:keyreleased(key) or done
        end
    end
    return not done
end

function gui.update(dt)
    gui.blinktime = gui.blinktime + dt
    -- print(gui.blinktime)
    if gui.blinktime > 1 then
        gui.blinktime = 0
    end
    gui.showcursor = gui.blinktime < 0.5
end

return gui