require("engine/test/bustedhelper")
require("engine/core/singleton")

describe('singleton', function ()

  local my_singleton = singleton(function (self)
    self.type = "custom"
  end)

  function my_singleton:_tostring()
    return "[my_singleton "..self.type.."]"
  end

  it('should define a singleton with unique members', function ()
    assert.are_equal("custom", my_singleton.type)
  end)

  describe('changing member', function ()

    setup(function ()
      my_singleton.type = "changed"
    end)

    teardown(function ()
      my_singleton.type = "custom"
    end)

    it('init should reinit the state vars', function ()
      my_singleton:init()
      assert.are_equal("custom", my_singleton.type)
    end)

  end)

  it('should support custom method: _tostring', function ()
    assert.are_equal("[my_singleton custom]", my_singleton:_tostring())
  end)

end)

describe('derived_singleton', function ()

  local my_singleton = singleton(function (self)
    self.types = { "custom" }  -- the table allows us to check if __index in derived_singleton reaches it by ref to change it
  end)

  function my_singleton:get_first_type()
    return self.types[1]
  end

  function my_singleton:_tostring()
    return "[my_singleton "..self.types[1].."]"
  end

  local my_derived_singleton = derived_singleton(my_singleton, function (self)
    self.subtype = "special"
  end)

  function my_derived_singleton:_tostring()
    return "[my_derived_singleton "..my_singleton._tostring(self)..", "..self.subtype.."]"
  end

  local my_derived_singleton_noinit = derived_singleton(my_derived_singleton)

  function my_derived_singleton_noinit:new_method()
    return 5
  end

  it('should define a derived_singleton with base members', function ()
    assert.are_equal("custom", my_derived_singleton.types[1])
  end)

  it('should define a derived_singleton with derived members using derivedinit', function ()
    assert.are_equal("special", my_derived_singleton.subtype)
  end)

  it('should define a derived_singleton with derived members with same init if none is provided', function ()
    assert.are_equal("special", my_derived_singleton_noinit.subtype)
  end)

  it('should define a derived_singleton with new methods', function ()
    assert.are_equal(5, my_derived_singleton_noinit.new_method())
  end)

  describe('changing base member copy', function ()

    before_each(function ()
      my_derived_singleton.types[1] = "changed"
    end)

    after_each(function ()
      my_derived_singleton.types[1] = "custom"
    end)

    it('should create a copy of base members on the derived singleton so they are never changed on the base singleton', function ()
      assert.are_equal("custom", my_singleton.types[1])
    end)

    describe('changing base member copy', function ()

      before_each(function ()
        my_derived_singleton.subtype = "subchanged"
      end)

      after_each(function ()
        my_derived_singleton.subtype = "special"
      end)

      it('init should reinit the state vars', function ()
        assert.are_equal("changed", my_derived_singleton.types[1])
        assert.are_equal("subchanged", my_derived_singleton.subtype)
        my_derived_singleton:init()
        assert.are_equal("custom", my_derived_singleton.types[1])
        assert.are_equal("special", my_derived_singleton.subtype)
      end)

    end)

  end)

  it('should access base method: get_first_type', function ()
    assert.are_equal("custom", my_derived_singleton:get_first_type())
  end)

  it('should support custom method: _tostring', function ()
    assert.are_equal("[my_derived_singleton [my_singleton custom], special]", my_derived_singleton:_tostring())
  end)

end)
