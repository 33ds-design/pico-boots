require("engine/test/bustedhelper")
local gameapp = require("engine/application/gameapp")

local coroutine_runner = require("engine/application/coroutine_runner")
local flow = require("engine/application/flow")
local manager = require("engine/application/manager")
local input = require("engine/input/input")

describe('gameapp', function ()

  describe('init', function ()

    it('should set empty managers table, new coroutine runner, nil initial gamestate', function ()
      local app = gameapp(30)
      assert.are_same({{}, coroutine_runner(), 30, 1 / 30, nil},
        {app.managers, app.coroutine_runner, app.fps, app.delta_time, app.initial_gamestate})
    end)

  end)

  describe('(with default app using 30 fps)', function ()

    local app

    local mock_manager_class1 = derived_class(manager)
    mock_manager_class1.type = ':mock1'
    mock_manager_class1.start = spy.new(function () end)
    mock_manager_class1.update = spy.new(function () end)
    mock_manager_class1.render = spy.new(function () end)

    local mock_manager_class2 = derived_class(manager)
    mock_manager_class2.type = ':mock2'
    mock_manager_class2.initially_active = false  -- to test no update/render
    mock_manager_class2.start = spy.new(function () end)
    mock_manager_class2.update = spy.new(function () end)
    mock_manager_class2.render = spy.new(function () end)

    before_each(function ()
      app = gameapp(30)
      mock_manager1 = mock_manager_class1()
      mock_manager2 = mock_manager_class2()
    end)

    describe('instantiate_managers', function ()

      it('should return {} with default implementation', function ()
        assert.are_same({}, app:instantiate_managers())
      end)

    end)

    describe('register_managers', function ()

      it('should inject itself as app in each manager', function ()
        app:register_managers({mock_manager1, mock_manager2})
        assert.are_equal(app, mock_manager1.app)
        assert.are_equal(app, mock_manager2.app)
      end)

      it('should register each manager', function ()
        app:register_managers({mock_manager1, mock_manager2})
        assert.are_same({[':mock1'] = mock_manager1, [':mock2'] = mock_manager2}, app.managers)
      end)

    end)

    describe('instantiate_and_register_managers', function ()

      local fake_manager1 = {"manager1"}
      local fake_manager2 = {"manager2"}

      setup(function ()
        stub(gameapp, "register_managers")
      end)

      teardown(function ()
        gameapp.register_managers:revert()
      end)

      before_each(function ()
        -- quick way to override method
        -- without having to derive a class from gameapp, then instantiate it
        function app:instantiate_managers()
          return {fake_manager1, fake_manager2}
        end
      end)

      it('should register all the managers returned by instantiate_managers', function ()
        app:instantiate_and_register_managers()

        local s = assert.spy(gameapp.register_managers)
        s.was_called(1)
        s.was_called_with(match.ref(app), {{"manager1"}, {"manager2"}})
      end)

    end)

    describe('instantiate_gamestates', function ()

      it('should return {} with default implementation', function ()
        assert.are_same({}, app:instantiate_gamestates())
      end)

    end)

    describe('register_gamestates', function ()

      local fake_gamestate1
      local fake_gamestate2

      setup(function ()
        stub(flow, "add_gamestate")
      end)

      teardown(function ()
        flow.add_gamestate:revert()
      end)

      before_each(function ()
        fake_gamestate1 = {"gamestate1"}
        fake_gamestate2 = {"gamestate2"}
      end)

      after_each(function ()
        flow.add_gamestate:clear()
      end)

      it('should inject itself as app in each gamestate', function ()
        app:register_gamestates({fake_gamestate1, fake_gamestate2})

        assert.are_equal(app, fake_gamestate1.app)
        assert.are_equal(app, fake_gamestate2.app)
      end)

      it('should add all gamestates returned by instantiate_gamestates to flow', function ()
        app:register_gamestates({fake_gamestate1, fake_gamestate2})

        local s1 = assert.spy(flow.add_gamestate)
        s1.was_called(2)
        s1.was_called_with(match.ref(flow), match.ref(fake_gamestate1))
        s1.was_called_with(match.ref(flow), match.ref(fake_gamestate2))
      end)

    end)

    describe('instantiate_and_register_gamestates', function ()

      -- we won't even try calling on_enter, etc. so empty tables are enough
      local fake_gamestate1 = {"gamestate1"}
      local fake_gamestate2 = {"gamestate2"}

      setup(function ()
        stub(gameapp, "register_gamestates")
      end)

      teardown(function ()
        gameapp.register_gamestates:revert()
      end)

      after_each(function ()
        gameapp.register_gamestates:clear()
      end)

      before_each(function ()
        -- quick way to override method
        -- without having to derive a class from gameapp, then instantiate it
        function app:instantiate_gamestates()
          return {fake_gamestate1, fake_gamestate2}
        end
      end)

      it('should add all gamestates returned by instantiate_gamestates to flow', function ()
        app:instantiate_and_register_gamestates()

        local s = assert.spy(gameapp.register_gamestates)
        s.was_called(1)
        s.was_called_with(match.ref(app), {{"gamestate1"}, {"gamestate2"}})
      end)

    end)

    describe('(with mock_manager1 and mock_manager2 registered)', function ()

      before_each(function ()
        -- relies on register_managers being correct
        app:register_managers({mock_manager1, mock_manager2})
      end)

      describe('start', function ()

        setup(function ()
          spy.on(gameapp, "instantiate_and_register_managers")
          spy.on(gameapp, "instantiate_and_register_gamestates")
          spy.on(gameapp, "on_pre_start")
          spy.on(gameapp, "on_post_start")
          stub(flow, "query_gamestate_type")
        end)

        teardown(function ()
          gameapp.instantiate_and_register_managers:revert()
          gameapp.instantiate_and_register_gamestates:revert()
          gameapp.on_pre_start:revert()
          gameapp.on_post_start:revert()
          flow.query_gamestate_type:revert()
        end)

        after_each(function ()
          gameapp.instantiate_and_register_managers:clear()
          gameapp.instantiate_and_register_gamestates:clear()
          gameapp.on_pre_start:clear()
          gameapp.on_post_start:clear()
          flow.query_gamestate_type:clear()

          mock_manager1.start:clear()
          mock_manager2.start:clear()
        end)

        it('should assert if initial_gamestate is not set', function ()
          assert.has_error(function ()
            app:start()
          end, "gameapp:start: gameapp.initial_gamestate is not set")
        end)

        describe('(initial gamestate set to "dummy")', function ()

          before_each(function ()
            app.initial_gamestate = "dummy"
          end)

          it('should call start on_pre_start', function ()
            app:start()

            local s = assert.spy(gameapp.on_pre_start)
            s.was_called(1)
            s.was_called_with(match.ref(app))
          end)

          it('should call instantiate_and_register_managers', function ()
            app:start()

            assert.spy(gameapp.instantiate_and_register_managers).was_called(1)
            assert.spy(gameapp.instantiate_and_register_managers).was_called_with(match.ref(app))
          end)

          it('should call instantiate_and_register_gamestates', function ()
            app:start()

            assert.spy(gameapp.instantiate_and_register_gamestates).was_called(1)
            assert.spy(gameapp.instantiate_and_register_gamestates).was_called_with(match.ref(app))
          end)

          it('should call flow:query_gamestate_type with self.initial_gamestate', function ()
            app.initial_gamestate = "dummy_state"

            app:start()

            local s = assert.spy(flow.query_gamestate_type)
            s.was_called(1)
            s.was_called_with(match.ref(flow), "dummy_state")
          end)

          it('should call start on each manager', function ()
            app:start()

            local s1 = assert.spy(mock_manager1.start)
            s1.was_called(1)
            s1.was_called_with(match.ref(mock_manager1))

            local s2 = assert.spy(mock_manager2.start)
            s2.was_called(1)
            s2.was_called_with(match.ref(mock_manager2))
          end)

          it('should call start on_post_start', function ()
            app:start()

            local s = assert.spy(gameapp.on_post_start)
            s.was_called(1)
            s.was_called_with(match.ref(app))
          end)

          it('should call on_pre_start before on_post_start', function ()
            local call_order = {}

            -- override on_pre_start to track call order
            function app:on_pre_start()
              add(call_order, "on_pre_start")
            end
            -- override on_post_start to track call order
            function app:on_post_start()
              add(call_order, "on_post_start")
            end

            app:start()

            assert.are_same({"on_pre_start", "on_post_start"}, call_order)
          end)

        end)  -- (initial gamestate set to "dummy")

      end)

      describe('reset', function ()

        setup(function ()
          stub(coroutine_runner, "stop_all_coroutines")
          stub(input, "init")
          stub(flow, "init")
          spy.on(gameapp, "on_reset")
        end)

        teardown(function ()
          coroutine_runner.stop_all_coroutines:revert()
          input.init:revert()
          flow.init:revert()
          gameapp.on_reset:revert()
        end)

        after_each(function ()
          coroutine_runner.stop_all_coroutines:clear()
          input.init:clear()
          flow.init:clear()
          gameapp.on_reset:clear()
        end)

        it('should call coroutine_runner:stop_all_coroutines', function ()
          app:reset()

          assert.spy(coroutine_runner.stop_all_coroutines).was_called(1)
          assert.spy(coroutine_runner.stop_all_coroutines).was_called_with(match.ref(app.coroutine_runner))
        end)

        it('should call input:init', function ()
          app:reset()

          assert.spy(input.init).was_called(1)
          assert.spy(input.init).was_called_with(match.ref(input))
        end)

        it('should call flow:init', function ()
          app:reset()

          assert.spy(flow.init).was_called(1)
          assert.spy(flow.init).was_called_with(match.ref(flow))
        end)

        it('should call on_reset', function ()
          app:reset()

          assert.spy(gameapp.on_reset).was_called(1)
          assert.spy(gameapp.on_reset).was_called_with(match.ref(app))
        end)

      end)

      describe('update', function ()

        setup(function ()
          stub(input, "process_players_inputs")
          stub(coroutine_runner, "update_coroutines")
          stub(flow, "update")
          spy.on(gameapp, "on_update")
        end)

        teardown(function ()
          input.process_players_inputs:revert()
          coroutine_runner.update_coroutines:revert()
          flow.update:revert()
          gameapp.on_update:revert()
        end)

        after_each(function ()
          input.process_players_inputs:clear()
          coroutine_runner.update_coroutines:clear()
          flow.update:clear()
          gameapp.on_update:clear()

          mock_manager1.update:clear()
          mock_manager2.update:clear()
        end)

        it('should call input:process_players_inputs', function ()
          app:update()

          local s = assert.spy(input.process_players_inputs)
          s.was_called(1)
          s.was_called_with(match.ref(input))
        end)

        it('should update coroutines via coroutine runner', function ()
          app:update()

          local s = assert.spy(coroutine_runner.update_coroutines)
          s.was_called(1)
          s.was_called_with(match.ref(app.coroutine_runner))
        end)

        -- bugfix history:
        -- + forget self. in front of managers
        it('should update all registered managers that are active', function ()
          app:update()

          local s1 = assert.spy(mock_manager1.update)
          s1.was_called(1)
          s1.was_called_with(match.ref(mock_manager1))

          local s2 = assert.spy(mock_manager2.update)
          s2.was_not_called()
        end)

        it('should update the flow', function ()
          app:update()

          local s2 = assert.spy(flow.update)
          s2.was_called(1)
          s2.was_called_with(match.ref(flow))
        end)

        it('should call on_update', function ()
          app:update()

          local s2 = assert.spy(app.on_update)
          s2.was_called(1)
          s2.was_called_with(match.ref(app))
        end)

      end)

      describe('draw', function ()

        setup(function ()
          stub(_G, "cls")
          stub(flow, "render")
          stub(flow, "render_post")
        end)

        teardown(function ()
          cls:revert()
          flow.render:revert()
          flow.render_post:revert()
        end)

        after_each(function ()
          cls:clear()
          flow.render:clear()
          flow.render_post:clear()

          mock_manager1.render:clear()
          mock_manager2.render:clear()
        end)

        it('should clear screen', function ()
          app:draw()
          assert.spy(cls).was_called(1)
        end)

        -- bugfix history:
        -- + forget self. in front of managers
        it('should render all registered managers that are active', function ()
          app:draw()

          local s1 = assert.spy(mock_manager1.render)
          s1.was_called(1)
          s1.was_called_with(match.ref(mock_manager1))
          local s2 = assert.spy(mock_manager2.render)
          s2.was_not_called()
        end)

        it('should call flow:render', function ()
          app:draw()

          local s = assert.spy(flow.render)
          s.was_called(1)
          s.was_called_with(match.ref(flow))
        end)

        it('should call flow:render_post', function ()
          -- call order: should be after manager render,
          -- but we cannot easily test that
          app:draw()

          local s = assert.spy(flow.render_post)
          s.was_called(1)
          s.was_called_with(match.ref(flow))
        end)

      end)

      describe('lifecycle (start -> update -> draw)', function ()

        setup(function ()
          -- stub start dependencies
          spy.on(gameapp, "instantiate_and_register_managers")
          spy.on(gameapp, "instantiate_and_register_gamestates")
          stub(flow, "query_gamestate_type")
          -- stub update dependencies
          stub(input, "process_players_inputs")
          stub(coroutine_runner, "update_coroutines")
          stub(flow, "update")
          spy.on(gameapp, "on_update")
          -- stub draw dependencies
          stub(_G, "cls")
          stub(flow, "render")
          stub(flow, "render_post")
        end)

        teardown(function ()
          gameapp.instantiate_and_register_managers:revert()
          gameapp.instantiate_and_register_gamestates:revert()
          flow.query_gamestate_type:revert()
          input.process_players_inputs:revert()
          coroutine_runner.update_coroutines:revert()
          flow.update:revert()
          gameapp.on_update:revert()
          cls:revert()
          flow.render:revert()
          flow.render_post:revert()
        end)

        before_each(function ()
          app.initial_gamestate = "dummy"
        end)

        after_each(function ()
          gameapp.instantiate_and_register_managers:clear()
          gameapp.instantiate_and_register_gamestates:clear()
          flow.query_gamestate_type:clear()
          input.process_players_inputs:clear()
          coroutine_runner.update_coroutines:clear()
          flow.update:clear()
          gameapp.on_update:clear()
          cls:clear()
          flow.render:clear()
          flow.render_post:clear()

          mock_manager1.start:clear()
          mock_manager1.update:clear()
          mock_manager1.render:clear()
          mock_manager2.start:clear()
          mock_manager2.update:clear()
          mock_manager2.render:clear()
        end)

        it('should complete a full lifecycle frame with correct call counts', function ()
          app:start()

          -- after start: managers should be started once
          assert.spy(mock_manager1.start).was_called(1)
          assert.spy(mock_manager2.start).was_called(1)

          -- run 3 update + draw cycles
          for i = 1, 3 do
            app:update()
            app:draw()
          end

          -- update should have been called 3 times for active manager
          assert.spy(mock_manager1.update).was_called(3)
          -- update should not be called for inactive manager
          assert.spy(mock_manager2.update).was_not_called()

          -- render should have been called 3 times for active manager
          assert.spy(mock_manager1.render).was_called(3)
          -- render should not be called for inactive manager
          assert.spy(mock_manager2.render).was_not_called()

          -- flow update and render should each be called 3 times
          assert.spy(flow.update).was_called(3)
          assert.spy(flow.render).was_called(3)
          assert.spy(flow.render_post).was_called(3)

          -- on_update should have been called 3 times
          assert.spy(gameapp.on_update).was_called(3)
        end)

      end)  -- lifecycle

    end)  -- (with mock_manager1 and mock_manager2 registered)

    describe('start_coroutine', function ()

      local function coroutine_fun(arg)
        yield()
      end

      setup(function ()
        stub(coroutine_runner, "start_coroutine")
      end)

      teardown(function ()
        coroutine_runner.start_coroutine:revert()
      end)

      it('should delegate start to coroutine runner', function ()
        app:start_coroutine(coroutine_fun, 99)

        local s = assert.spy(coroutine_runner.start_coroutine)
        s.was_called(1)
        s.was_called_with(match.ref(app.coroutine_runner), coroutine_fun, 99)
      end)

    end)

    describe('stop_all_coroutines', function ()

      local function coroutine_fun(arg)
        yield()
      end

      setup(function ()
        stub(coroutine_runner, "stop_all_coroutines")
      end)

      teardown(function ()
        coroutine_runner.stop_all_coroutines:revert()
      end)

      it('should delegate stop to coroutine runner', function ()
        app:stop_all_coroutines()

        local s = assert.spy(coroutine_runner.stop_all_coroutines)
        s.was_called(1)
        s.was_called_with(match.ref(app.coroutine_runner))
      end)

    end)

    describe('stop_all_coroutines (with real coroutines)', function ()

      local function long_running_async()
        yield_delay(60)
      end

      after_each(function ()
        app:stop_all_coroutines()
      end)

      it('should clear all running coroutines', function ()
        app:start_coroutine(long_running_async)
        app:start_coroutine(long_running_async)

        assert.are_equal(2, #app.coroutine_runner.coroutine_curries)

        app:stop_all_coroutines()

        assert.are_equal(0, #app.coroutine_runner.coroutine_curries)
      end)

      it('should prevent further updates from resuming stopped coroutines', function ()
        local test_var = 0
        local function set_var_async()
          yield_delay(10)
          test_var = 1
        end

        app:start_coroutine(set_var_async)
        assert.are_equal(1, #app.coroutine_runner.coroutine_curries)

        app:stop_all_coroutines()
        assert.are_equal(0, #app.coroutine_runner.coroutine_curries)

        -- updating after stop should not resume any coroutines
        app.coroutine_runner:update_coroutines()
        assert.are_equal(0, #app.coroutine_runner.coroutine_curries)
        assert.are_equal(0, test_var)
      end)

    end)

    describe('yield_delay_s', function ()

      -- we won't even try calling on_enter, etc. so empty tables are enough
      local dummy_state1 = {}
      local dummy_state2 = {}

      setup(function ()
        stub(_G, "yield_delay")
      end)

      teardown(function ()
        yield_delay:revert()
      end)

      after_each(function ()
        yield_delay:clear()
      end)

      it('should call yield_delay with the equivalent in frames (ceiled)', function ()
        app:yield_delay_s(1)

        local s = assert.spy(yield_delay)
        s.was_called(1)
        s.was_called_with(30)
      end)

      it('should call yield_delay with the equivalent in frames, ceiled', function ()
        app:yield_delay_s(0.15)

        local s = assert.spy(yield_delay)
        s.was_called(1)
        s.was_called_with(5)
      end)

    end)

    describe('wait_and_do', function ()

      local callback_spy
      local test_var = 0

      setup(function ()
        stub(input, "process_players_inputs")
        stub(flow, "update")
      end)

      teardown(function ()
        input.process_players_inputs:revert()
        flow.update:revert()
      end)

      before_each(function ()
        test_var = 0
        callback_spy = spy.new(function (val)
          test_var = val or 1
        end)
      end)

      after_each(function ()
        input.process_players_inputs:clear()
        flow.update:clear()
        app:stop_all_coroutines()
      end)

      it('should call callback after waiting the specified duration in seconds', function ()
        -- 30 fps, so 1 second = 30 frames
        -- yield_delay(30) does 29 yields, and coroutine starts suspended (not run on start),
        -- so we need 30 updates to complete the delay and fire the callback
        app:wait_and_do(1, callback_spy, 42)

        -- after 29 updates, callback not yet called
        for t = 1, 29 do
          app:update()
        end
        assert.spy(callback_spy).was_not_called()
        assert.are_equal(0, test_var)

        -- after 30 updates, callback is called with the passed argument
        app:update()
        assert.spy(callback_spy).was_called(1)
        assert.spy(callback_spy).was_called_with(42)
        assert.are_equal(42, test_var)
      end)

      it('should call callback almost immediately for very short delay (ceil to 1 frame)', function ()
        -- 0.01s at 30fps = 0.3 frames, ceiled to 1 frame
        -- yield_delay(1) does 0 yields (for frame = 1, 0 do end),
        -- so coroutine finishes on the very first update
        app:wait_and_do(0.01, callback_spy)

        app:update()
        assert.spy(callback_spy).was_called(1)
      end)

    end)

  end)  -- (with default app)

end)
