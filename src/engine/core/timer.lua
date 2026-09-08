-- frame-based timer module
-- provides one-shot and repeating timers measured in update frames

local timer = {}
timer.__index = timer

-- create a new timer instance
function timer.new()
  local self = setmetatable({}, timer)
  self._timers = {}
  return self
end

-- register a one-shot timer that fires after `frames` frames
-- frames: number of frames to wait before calling callback (must be >= 0)
-- callback: function to call when the timer expires
function timer:after(frames, callback)
  assert(frames >= 0, "timer:after: frames must be >= 0")
  assert(type(callback) == "function", "timer:after: callback must be a function")
  local entry = {
    remaining = frames,
    callback = callback,
    periodic = false,
  }
  table.insert(self._timers, entry)
  return entry
end

-- register a repeating timer that fires every `frames` frames
-- frames: period in frames between each callback invocation (must be > 0)
-- callback: function to call each time the timer fires
function timer:every(frames, callback)
  assert(frames > 0, "timer:every: frames must be > 0")
  assert(type(callback) == "function", "timer:every: callback must be a function")
  local entry = {
    remaining = frames,
    period = frames,
    callback = callback,
    periodic = true,
  }
  table.insert(self._timers, entry)
  return entry
end

-- advance all timers by one frame
-- should be called exactly once per game update cycle
-- expired one-shot timers are removed after firing
-- periodic timers reset their countdown after firing
function timer:update()
  -- iterate backwards to safely remove entries while iterating
  for i = #self._timers, 1, -1 do
    local entry = self._timers[i]
    entry.remaining = entry.remaining - 1
    if entry.remaining <= 0 then
      entry.callback()
      if entry.periodic then
        entry.remaining = entry.period
      else
        table.remove(self._timers, i)
      end
    end
  end
end

-- remove all timers from this instance
function timer:clear()
  self._timers = {}
end

return timer
