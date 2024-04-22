-- create a new singleton from an init method, which can also be used as reset method in unit tests
-- the singleton is at the same time a class and its own instance
-- init takes a single `self` parameter
function singleton(init)
  local s = {}
  s.init = init
  s:init()
  return s
end

-- create a singleton from a base singleton and an optional derivedinit method, so it can extend
-- the functionality of a singleton while providing new static fields on the spot
-- derivedinit should *not* call base_singleton.init, as it is already done in the construct-time init
function derived_singleton(base_singleton, derivedinit)
  local ds = {}
  -- do not set __index to base_singleton in metatable, so ds never touches the members
  -- of the base singleton (if the base singleton is concrete or has other derived singletons,
  -- this would cause them to all share and modify the same members)
  setmetatable(ds, {
    -- __index allows the derived_singleton to access base_singleton methods
    -- never define an attribute on a singleton outside init (e.g. using s.attr = value)
    -- as the "super" init in ds:init would not be able to shadow that attr with a personal attr
    -- for the derived_singleton, which would access the base_singleton's attr via __index,
    -- effectively sharing the attr with all the other singletons in that hierarchy!
    __index = base_singleton,
  })
  function ds:init()
    base_singleton.init(self)
    if derivedinit then
      derivedinit(self)
    end
  end
  ds:init()
  return ds
end
