--- evaluates a single value generator into an array
--
-- @tparam function gen
-- @raise if `gen` is not a function
-- @return table tmp
local function toarray (gen)
  if type(gen) == 'function' then
    local tmp = {}

    for value in gen do
      table.insert(tmp, value)
    end

    return tmp
  else error('unsupported param type') end
end

--- creates a generator function for the values of `t`
--
-- @tparam table t
-- @raise if `t` is not table
-- @return function () callable that returns each value in `t` once
-- @usage gen = generator({2, 3, 4}); assert(gen() == 2); assert(gen() == 3); assert(gen() == 4);
local function generator (t)
  if type(t) == 'table' then
    local index, value

    return function ()
      index, value = next(t, index)
      return value
    end
  else error('unsupported param type') end
end

--- calls a function with the provided argument
-- also useful to force call a function reference
--
-- @tparam function fn arguments passed to `fn`
-- @param ... arguments passed to `fn`
-- @return any
local function call (fn, ...)
  return fn(...)
end

--- creates a new function that calls `fn_a` with the output of `fn_b`
--
-- @tparam function fn_a
-- @tparam function fn_b
-- @return new composed function
local function compose (fn_a, fn_b)
  return function (...)
    return fn_a(fn_b(...))
  end
end

--- gets the value of `t` in the `index` position 
--
-- @tparam table t
-- @return any
-- @usage assert(get(2, {5, 6, 7}) == 6)
local function get (index, t)
  return t[index]
end

--- map function
-- applies `fn` once to each value of `t`; return value is a generator.
--
-- @tparam function fn(v) called once for each value of `t`
-- @tparam array t
-- @return new array with the new values
-- @usage map({1, 2, 3}, tostring)  -- {'1', '2', '3'}
local function map (fn, t)
  local gen = type(t) == 'table' and generator(t) or t
  return function ()
    local v = gen()
    return v and fn(v) or nil
  end
end

--- fp filter function
-- creates a new array where each value is the result
-- of calling `fn` against a value of `t` if it is not falsy.
--
-- @tparam function fn(v) called once for each value of `t`
-- @tparam array t
-- @return new array with values for cases where `fn(value)` was not falsy
-- @usage filter({1, 2, 3}, function (v) return v < 3 end)  -- {1, 2}
local function filter (fn, t)
  local gen = type(t) == 'table' and generator(t) or t
  return function ()
    for v in gen do
      if fn(v) then return v end
    end
  end
end

--- fp reduce function
-- reduces `t` to a single element by applying `fn` against
-- each value of `t` in pairs. The first pair is always
-- the value of `init` against the first item of `t`. Keep
-- in mind that if not provided `init` is nil.
--
-- @tparam function fn (v1, v2)
-- @tparam array t
-- @tparam[opt] number init
-- @usage reduce({1, 2, 3}, function (a, b, 0) return a + b end)  -- 6
local function reduce (fn, t, init)
  local gen = type(t) == 'table' and generator(t) or t
  init = init or gen()
  
  for v in gen do
    init = fn(init, v)
  end

  return init
end

--- puts together each element of `t1` with a corresponding element of each table in `...`
-- for each key of `t1`, puts the value of `t1[key]` and `tx[key]`, where
-- tx is a table from `...`  together in an array. If `t1` and `tx` are uneven 
-- or keys in `t1` are not found in `tx`, the value of `t1` for such cases will be
-- an array with less than `#{...} + 1` elements.
--
-- @param table
-- @param ... variable number of tables
-- @return table where each key is a key of `t` and each value is
--         a array where the first element is a value of `t` and
--         and the others are values of elements of {...} for each
--         key of `t`.
local function zip (...)
  local tmp = toarray(map(generator, {...}))
  
  return function ()
    return table.unpack(toarray(map(call, tmp)))
  end
end

--- creates a new function with new defaults
--
-- @tparam function fn
-- @tparam ...
-- @return
-- @usage
--  local fn = partial(function (a, b) return a*b end, 2)
--  assert(fn(2) == 4)
--  assert(fn(3) == 6)
local function partial (fn, ...)
  local pargs = {...}

  return function (...)
    local args = {}
    
    for _, v in pairs({...}) do
      table.insert(args, v)
    end

    return fn(table.unpack(args))
  end
end

--- picks the nth item from a multi value input
--
-- @tparam int index
-- @param ...
-- @return 
-- @usage assert(pick(2, 5, 6, 7) == 6)
local function pick (index, ...)
  local args = {...}
  return args[index]
end

--- creates a function that returns the same value given the same input
--
-- @tparam function fn
-- @tparam table cache provide your own instance for custom cache behavior
-- @return ...
local function memoize (fn, cache)
  cache = cache or {}
  return function (...)
    local args = {...}
    local hashkey = string.dump(function () return args end)
    
    if cache[hashkey] == nil then
      cache[hashkey] = fn(...) 
    end

    return cache[hashkey]
  end
end

return {
  ["call"]=call,
  ["compose"]=compose,
  ["filter"]=filter,
  ["get"]=get,
  ["generator"]=generator,
  ["map"]=map,
  ["memoize"]=memoize,
  ["partial"]=partial,
  ["pick"]=pick,
  ["reduce"]=reduce,
  ["toarray"]=toarray,
  ["zip"]=zip,
}
