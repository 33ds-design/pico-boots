require("engine/test/bustedhelper")
local timer = require("engine/core/timer")

describe('timer', function ()

  describe('new', function ()
    it('should create a new timer instance with empty timer list', function ()
      local tm = timer.new()
      assert.is_not_nil(tm)
      assert.are_equal(0, #tm._timers)
    end)
  end)

  describe('after', function ()
    it('should fire callback after exact number of frames', function ()
      local tm = timer.new()
      local count = 0
      tm:after(3, function ()
        count = count + 1
      end)

      -- 2 frames: not yet fired
      tm:update()
      tm:update()
      assert.are_equal(0, count)

      -- 3rd frame: fired
      tm:update()
      assert.are_equal(1, count)
    end)

    it('should fire only once (one-shot)', function ()
      local tm = timer.new()
      local count = 0
      tm:after(2, function ()
        count = count + 1
      end)

      -- fire at frame 2
      tm:update()
      tm:update()
      assert.are_equal(1, count)

      -- subsequent frames: no more firing
      tm:update()
      tm:update()
      tm:update()
      assert.are_equal(1, count)
    end)

    it('should fire immediately when frames is 0', function ()
      local tm = timer.new()
      local count = 0
      tm:after(0, function ()
        count = count + 1
      end)

      tm:update()
      assert.are_equal(1, count)
    end)
  end)

  describe('every', function ()
    it('should fire repeatedly every N frames', function ()
      local tm = timer.new()
      local count = 0
      tm:every(3, function ()
        count = count + 1
      end)

      -- frame 1, 2: no fire
      tm:update()
      tm:update()
      assert.are_equal(0, count)

      -- frame 3: fire #1
      tm:update()
      assert.are_equal(1, count)

      -- frame 4, 5: no fire
      tm:update()
      tm:update()
      assert.are_equal(1, count)

      -- frame 6: fire #2
      tm:update()
      assert.are_equal(2, count)

      -- frame 9: fire #3
      tm:update()
      tm:update()
      tm:update()
      assert.are_equal(3, count)
    end)
  end)

  describe('clear', function ()
    it('should prevent all pending timers from firing', function ()
      local tm = timer.new()
      local count_a = 0
      local count_b = 0
      tm:after(2, function ()
        count_a = count_a + 1
      end)
      tm:every(3, function ()
        count_b = count_b + 1
      end)

      tm:update()  -- frame 1
      tm:clear()
      tm:update()  -- frame 2 (would fire after-2)
      tm:update()  -- frame 3 (would fire every-3)

      assert.are_equal(0, count_a)
      assert.are_equal(0, count_b)
      assert.are_equal(0, #tm._timers)
    end)
  end)

  describe('multiple timers', function ()
    it('should run independently without interfering', function ()
      local tm = timer.new()
      local count_a = 0
      local count_b = 0
      local count_c = 0

      tm:after(2, function ()
        count_a = count_a + 1
      end)
      tm:every(3, function ()
        count_b = count_b + 1
      end)
      tm:after(5, function ()
        count_c = count_c + 1
      end)

      -- frame 1
      tm:update()
      assert.are_equal(0, count_a)
      assert.are_equal(0, count_b)
      assert.are_equal(0, count_c)

      -- frame 2: after-2 fires
      tm:update()
      assert.are_equal(1, count_a)
      assert.are_equal(0, count_b)
      assert.are_equal(0, count_c)

      -- frame 3: every-3 fires #1
      tm:update()
      assert.are_equal(1, count_a)
      assert.are_equal(1, count_b)
      assert.are_equal(0, count_c)

      -- frame 4
      tm:update()
      assert.are_equal(1, count_a)
      assert.are_equal(1, count_b)
      assert.are_equal(0, count_c)

      -- frame 5: after-5 fires
      tm:update()
      assert.are_equal(1, count_a)
      assert.are_equal(1, count_b)
      assert.are_equal(1, count_c)

      -- after timers are gone, only every remains
      assert.are_equal(1, #tm._timers)
    end)
  end)

end)
