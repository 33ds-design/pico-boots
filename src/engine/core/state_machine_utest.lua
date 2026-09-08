require("engine/test/bustedhelper")
local state_machine = require("engine/core/state_machine")

describe('state_machine', function ()

  describe('new', function ()

    it('should create a state machine with no current state and not started', function ()
      local sm = state_machine.new({
        idle = {},
        walk = {}
      })
      assert.is_not_nil(sm)
      assert.is_nil(sm.current_state)
      assert.is_false(sm._started)
    end)

  end)

  describe('start', function ()

    it('should set current_state to initial state and call on_enter', function ()
      local on_enter_spy = spy.new(function() end)
      local sm = state_machine.new({
        idle = {
          on_enter = on_enter_spy
        }
      })
      sm:start("idle")
      assert.are_equal("idle", sm.current_state)
      assert.is_true(sm._started)
      assert.spy(on_enter_spy).was_called(1)
      assert.spy(on_enter_spy).was_called_with(sm)
    end)

  end)

  describe('transition', function ()

    it('should switch to target state on valid transition event', function ()
      local sm = state_machine.new({
        idle = {
          transitions = { start_walk = "walk" }
        },
        walk = {}
      })
      sm:start("idle")
      sm:transition("start_walk")
      assert.are_equal("walk", sm.current_state)
    end)

    it('should call on_exit on current state and on_enter on target state', function ()
      local on_exit_called = false
      local on_exit_state = nil
      local on_enter_called = false
      local on_enter_state = nil
      local sm = state_machine.new({
        idle = {
          on_exit = function(self)
            on_exit_called = true
            on_exit_state = self.current_state
          end,
          transitions = { go = "walk" }
        },
        walk = {
          on_enter = function(self)
            on_enter_called = true
            on_enter_state = self.current_state
          end
        }
      })
      sm:start("idle")
      sm:transition("go")
      assert.is_true(on_exit_called)
      assert.are_equal("idle", on_exit_state)
      assert.is_true(on_enter_called)
      assert.are_equal("walk", on_enter_state)
      assert.are_equal("walk", sm.current_state)
    end)

    it('should not change state on invalid transition event', function ()
      local on_exit_spy = spy.new(function() end)
      local sm = state_machine.new({
        idle = {
          on_exit = on_exit_spy,
          transitions = { go = "walk" }
        },
        walk = {}
      })
      sm:start("idle")
      sm:transition("nonexistent_event")
      assert.are_equal("idle", sm.current_state)
      assert.spy(on_exit_spy).was_not_called()
    end)

  end)

  describe('update', function ()

    it('should call the current state update callback with dt', function ()
      local update_spy = spy.new(function() end)
      local sm = state_machine.new({
        idle = {
          update = update_spy
        }
      })
      sm:start("idle")
      sm:update(0.5)
      assert.spy(update_spy).was_called(1)
      assert.spy(update_spy).was_called_with(sm, 0.5)
    end)

  end)

end)
