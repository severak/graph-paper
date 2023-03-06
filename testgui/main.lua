gui = require "severak.gui"

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

main_screen = gui.screen()
panel = main_screen:panel{y=400}
panel:label{text="Label on panel", w=300}
panel:button{text="Button on panel"}
panel:button{image="icon.png"}
panel:input{placeholder="...", w=100}
toggle = panel:button{text="toggle status"}

function toggle:on_click()
    status.visible = not status.visible
end

status = main_screen:label{text="Welcome to the demo...", y=-1, color={r=255/255, g=255/255, b=85/255}}

b1 = main_screen:button{text = "Click to move button to random place", padding=8, h=80, x=320, y=240}

incr = main_screen:button{x=60, y=60, text="Increment!"}
incr.val = 0;

function incr:on_click()
    incr.val = incr.val + 1
    status.text = "Incremented = " .. incr.val
end

exit = main_screen:button{x=-1, image="icon.png"}
exit.on_click = function()
    love.event.quit()
end

b1.on_click = function(self)
    self.x = math.random(love.graphics.getWidth() - self.w)
    self.y = math.random(love.graphics.getHeight() - self.h)
    status.text = "Moved demo button"
end

inp = main_screen:input{x=40, y=20, placeholder="enter..."}

-- TODO - 7GUI examples

gui.switch(main_screen)
love.window.setTitle("GUI test")

function love.draw()
    love.graphics.setColor(85/255, 85/255, 255)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    gui.draw()
end

function love.mousereleased(x, y, button)
    if gui.mousereleased(x, y, button) then
        status.text = string.format("click = %d, %d", x, y)
    end
end

function love.textinput(text)
    if gui.textinput(text) then
        status.text = "textinput: " .. text
    end
end

function love.keyreleased(key)
    if gui.keyreleased(key) then
        status.text = "keyreleased: " .. key
    end
end

function love.update(dt)
    gui.update(dt)
end

require "wincom"