-- generic finite state machine (FSM) module
-- supports state callbacks (on_enter/on_exit/update) and event-driven transitions

local state_machine = {}
state_machine.__index = state_machine

-- create a new state machine from a states configuration table
-- states_config format:
--   {
--     state_name = {
--       on_enter    = function(self) ... end,   -- optional, called when entering state
--       on_exit     = function(self) ... end,   -- optional, called when exiting state
--       update      = function(self, dt) ... end, -- optional, called on update
--       transitions = {event_name = to_state, ...}  -- optional, event -> target state mapping
--     },
--     ...
--   }
function state_machine.new(states_config)
  local self = setmetatable({}, state_machine)
  self._states = states_config or {}
  self.current_state = nil
  self._started = false
  return self
end

-- start the state machine with an initial state
-- calls the initial state's on_enter callback
function state_machine:start(initial_state)
  assert(self._states[initial_state], "state_machine:start: initial state '"..initial_state.."' does not exist")
  assert(not self._started, "state_machine:start: state machine has already been started")
  self.current_state = initial_state
  self._started = true
  local state = self._states[initial_state]
  if state.on_enter then
    state.on_enter(self)
  end
end

-- trigger a transition by event name
-- if the current state has a transition for this event, switch to the target state,
--   calling on_exit on the current state and on_enter on the new state
-- if no matching transition exists, do nothing
function state_machine:transition(event_name)
  assert(self._started, "state_machine:transition: state machine has not been started")
  local state = self._states[self.current_state]
  if state.transitions and state.transitions[event_name] then
    local next_state = state.transitions[event_name]
    assert(self._states[next_state], "state_machine:transition: target state '"..next_state.."' does not exist")
    -- call on_exit on current state
    if state.on_exit then
      state.on_exit(self)
    end
    -- switch to next state
    self.current_state = next_state
    local next_state_data = self._states[next_state]
    -- call on_enter on new state
    if next_state_data.on_enter then
      next_state_data.on_enter(self)
    end
  end
end

-- update the current state by calling its update callback with dt
function state_machine:update(dt)
  assert(self._started, "state_machine:update: state machine has not been started")
  local state = self._states[self.current_state]
  if state.update then
    state.update(self, dt)
  end
end

return state_machine
