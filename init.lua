local Swipe           = {}
Swipe.__index         = Swipe

-- Metadata
Swipe.name            = "Swipe"
Swipe.version         = "0.1"
Swipe.author          = "Michael Mogenson"
Swipe.homepage        = "https://github.com/mogenson/Swipe.spoon"
Swipe.license         = "MIT - https://opensource.org/licenses/MIT"

local gesture <const> = hs.eventtap.event.types.gesture
local doAfter <const> = hs.timer.doAfter

local Cache           = { id = 1, direction = nil, distance = 0, size = 0, touches = {} }

function Cache:clear()
    self.touches = {}
    self.size = 0
    self.direction = nil
    self.distance = 0
end

function Cache:none(touches)
    local absent = true
    for _, touch in ipairs(touches) do
        absent = absent and (self.touches[touch.identity] == nil)
    end
    return absent
end

function Cache:all(touches)
    local present = true
    for _, touch in ipairs(touches) do
        present = present and (self.touches[touch.identity] ~= nil)
    end
    return present
end

function Cache:set(touches)
    self:clear()
    for i, touch in ipairs(touches) do
        self.touches[touch.identity] = {
            x = touch.normalizedPosition.x,
            y = touch.normalizedPosition.y,
            dx = 0,
            dy = 0,
        }
        self.size = i
    end
    self.id = self.id + 1
    return self.id
end

function Cache:detect(touches)
    local left, right, up, down = true, true, true, true
    local distance = { dx = 0, dy = 0 }
    local size = 0
    for i, touch in ipairs(touches) do
        local id = touch.identity
        local x, y = touch.normalizedPosition.x, touch.normalizedPosition.y
        local dx, dy = x - assert(self.touches[id]).x, y - assert(self.touches[id]).y

        left = left and (touch.phase == "moved") and (dx < 0) and (math.abs(dx) > math.abs(dy))
        right = right and (touch.phase == "moved") and (dx > 0) and (math.abs(dx) > math.abs(dy))
        up = up and (touch.phase == "moved") and (dy > 0) and (math.abs(dy) > math.abs(dx))
        down = down and (touch.phase == "moved") and (dy < 0) and (math.abs(dy) > math.abs(dx))

        distance = { dx = distance.dx + dx, dy = distance.dy + dy }

        self.touches[id] = { x = x, y = y, dx = dx, dy = dy }
        size = i
    end

    assert(self.size == size)
    distance = { dx = distance.dx / size, dy = distance.dy / size }

    local direction = nil
    if left and not (right or up or down) then
        direction = "left"
        if self.direction == direction then self.distance = self.distance - distance.dx end
    elseif right and not (left or up or down) then
        direction = "right"
        if self.direction == direction then self.distance = self.distance + distance.dx end
    elseif up and not (left or right or down) then
        direction = "up"
        if self.direction == direction then self.distance = self.distance + distance.dy end
    elseif down and not (left or right or up) then
        direction = "down"
        if self.direction == direction then self.distance = self.distance - distance.dy end
    end

    if self.direction ~= direction then
        self.direction = direction
        self.distance = 0
    end

    return self.direction, self.distance, self.id
end

-- fingers: number of fingers for swipe (must be at least 2)
-- callback: function(direction, distance, id) end
--           direction is a string, either "left", "right", "up", "down"
--           distance is accumulated distance for swipe, beteeen 0.0 and 1.0
--           id is a unique integer across callbacks for the same swipe
function Swipe:start(fingers, callback)
    assert(fingers > 1)
    assert(callback)

    self.watcher = hs.eventtap.new({ gesture }, function(event)
        local type = event:getType(true)
        if type ~= gesture then return end
        local touches = event:getTouches()
        if #touches ~= fingers then return end

        if Cache:none(touches) then
            local id = Cache:set(touches)
            -- print("SWIPE BEGIN", id)
        elseif Cache:all(touches) then
            local direction, distance, id = Cache:detect(touches)
            if direction then
                doAfter(0, function()
                    -- print(string.format("SWIPE: %s DIST: %f ID: %d", string.upper(direction), distance, id))
                    callback(direction, distance, id)
                end)
            end
        end
    end)

    Cache:clear()
    self.watcher:start()
end

function Swipe:stop()
    if self.watcher then
        self.watcher:stop()
        self.watcher = nil
    end
end

return Swipe
