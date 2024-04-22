--#if tostring
require("engine/core/stringify")
--#endif

-- generic new metamethod (requires init method)
local function new(class, ...)
  local self = setmetatable({}, class)  -- class as instance metatable
  self:init(...)
  return self
end

--#if tostring
-- generic concat metamethod (requires _tostring method on tables)
local function concat(lhs, rhs)
  -- SUPERSEDED by tostr(), see comment on stringify above
  -- note that concatenation should also use __tostring automatically,
  --  the only point of string conversion is to be safe with nil, numbers on lhs
  --  and tables without __tostring
  return stringify(lhs)..stringify(rhs)
end
--#endif

-- return a copy of a class instance 'self' (esp. for struct-like class)
-- this is a simplified version of deepcopy implementations and only support
--   classes referencing primitive types or classes (at least copy-able tables)
--   with no reference cycle
-- Generally speaking, we recommend to always use copy when initializing a class value
--   from another, just like you would copy construct in C++ / define class variable in C#.
-- This will avoid unwanted changes in the source class when modifying the new one.
-- Ex: new_value = source:copy()
--     new_value.x = 5  -- safe
-- Similarly, functions that return another class with modified content from an initial class,
-- but that sometimes don't do anything (e.g. clamp) should return `source:copy()`
-- instead of `source` (or `self:copy()` instead of `self` for methods) when nothing is done.
-- You can exceptionally keep a reference to the source class table, as you would
--   with a const & in C++, but only if you are sure you will not modify it.
--   In this case, we recommend naming the variable with a marker such as `_ref` to remember it.
-- ! This will not copy class members set to nil, as there is no way to detect them
--   You should either manually check for optional members, or follow the idea that classes
--   are POD and not use nil as a possible value in your class members.
local function copy(self)
  -- we can't access the class type from here so we get it back via getmetatable
  local copied = setmetatable({}, getmetatable(self))

  for key, value in pairs(self) do
--#if busted
    local force_shallow_copy = false
    --[[
    busted uses luaassert spies, which hijack functions by replacing them
      with tables, so unit tests relying on copying a class containing a spied function
      will assert here; so, exceptionally allow shallow copy of those (just use reference to spy)
    A spy is like this:
      {returnvals = {}, callback = [function], clear = [function], calls = {}, called = [function], called_with = [function], revert = [function], returned_with = [function]}
      but we just check a few elements not likely to exist on our own classes (and that copy doesn't exist to start with)
    --]]
    if type(value) == 'table' and value.copy == nil and type(value.callback) == 'function' and type(value.called_with) == 'function' then
      force_shallow_copy = true
    end
    if type(value) == 'table' and not force_shallow_copy then
--#else
--[[#pico8
    if type(value) == 'table' then
--#pico8]]
--#endif
--#if assert
      assert(type(value.copy) == 'function', "value "..nice_dump(value)..
        " is a table member of a class but it doesn't have expected copy method, so it's not a class itself")
--#endif
      -- deep copy the class member itself. never use circular references
      -- between classes or you'll get an infinite recursion
      copied[key] = value:copy()
    else
      copied[key] = value
    end
  end

  return copied
end

-- copy assign class members of 'from' to class members of 'self' (esp. for struct-like class)
-- from and to must be class instances of the same type
-- copy_assign is useful when manipulating a class instance reference whose content
--  must be changed in-place, because the function caller will continue using the same reference
-- Generally speaking, we recommend using copy_assign every time you assign you must copy a class
--   into an existing target class, just like you would copy assign in C++ / assign class in C#.
-- Ex: target:copy_assign(source)
--     target.x = 5  -- safe
-- You can exceptionally keep a reference to the source class table, as you would
--   with a const & in C++, but only if you are sure you will not modify it.
-- ! This will not copy class members set to nil (see same comment for copy)
local function copy_assign(self, from)
  assert(getmetatable(self) == getmetatable(from), "copy_assign: expected 'self' ("..self..") and 'from' ("..from..") to have the same class type")

  for key, value in pairs(from) do
    if type(value) == 'table' then
      -- recursively copy-assign the class members. never use circular references
      -- between classes that you intend to copy, or you'll get an infinite recursion
      self[key] = value:copy()
    else
      self[key] = value
    end
  end
end

--[[
Create and return a new class

Every class should implement
  - `:init()`,
  - if useful for logging, `:_tostring()`
  - if relevant, `.__eq()`

Since .__eq is manually implemented when needed, and copy/copy_assign is always defined,
there is no difference between classes and structs as found in other languages.
We simply call "struct-like classes" class that implement .__eq and for which we expect to use copy/copy_assign.

Note that most .__eq() definitions are only duck-typing lhs and rhs,
  so we can compare two instances of different classes (maybe related by inheritance)
  with the same members. slicing will occur when comparing a base instance
  and a derived instance with more members. add a class type member to simulate RTTI
  and make sure only objects of the same class are considered equal (but we often don't need this)
--]]
function new_class()
  local class = {}
  class.__index = class  -- 1st class as instance metatable
--#if tostring
  class.__concat = concat
--#endif
  class.copy = copy
  class.copy_assign = copy_assign

  setmetatable(class, {
    __call = new
  })

  return class
end

--[[
Create and return a new class derived from a base class

base_class should have itself been created with new_class or derived_class.

It behaves like new_class, but adds __index = base_class in the metatable
You must override `:init` and call `base_class.init(self, ...)` inside
  if you want to preserve base implementation
--]]
function derived_class(base_class)
  -- developer may inadvertently pass nil object when forgetting a require
  assert(base_class, "derived_class: no base class passed")

  local class = {}
  class.__index = class  -- 1st class as instance metatable
--#if tostring
  class.__concat = concat
--#endif

  setmetatable(class, {
    __index = base_class,
    __call = new
  })

  return class
end
