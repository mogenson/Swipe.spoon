# Swipe.spoon
Swipe gesture detection for HammerSpoon

Example config:
```lua
-- use three finger swipe to focus nearby window
local current_id, threshold
Swipe = hs.loadSpoon("Swipe")
Swipe:start(3, function(direction, distance, id)
    if id == current_id then
        if distance > threshold then
            threshold = math.huge -- only trigger once per swipe

            -- use "natural" scrolling
            if direction == "left" then
                hs.window.focusedWindow():focusWindowEast()
            elseif direction == "right" then
                hs.window.focusedWindow():focusWindowWest()
            elseif direction == "up" then
                hs.window.focusedWindow():focusWindowSouth()
            elseif direction == "down" then
                hs.window.focusedWindow():focusWindowNorth()
            end
        end
    else
        current_id = id
        threshold = 0.2 -- swipe distance > 20% of trackpad
    end
end)
```

## Avoid conflicts with System gestures
Under `System Settings -> Trackpad -> More Gestures`:
- Set `Swipe between pages` to `Off` to avoid navigating back in Chrome and Safari.
- Set `Swipe between full-screen applications` to a different number of fingers than Swipe.spoon
- Set `Mission Control` to a different number of fingers than Swipe.spoon
