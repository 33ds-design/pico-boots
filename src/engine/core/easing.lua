-- easing functions module
-- all functions take t in [0, 1] and return a value in [0, 1]

local easing = {}

-- linear easing: no acceleration or deceleration
function easing.linear(t)
  return t
end

-- ease in: starts slow, accelerates
-- power: the exponent (default 2 for quadratic)
function easing.ease_in(t, power)
  power = power or 2
  return t ^ power
end

-- ease out: starts fast, decelerates
-- power: the exponent (default 2 for quadratic)
function easing.ease_out(t, power)
  power = power or 2
  return 1 - (1 - t) ^ power
end

-- ease in-out: starts slow, accelerates, then decelerates
-- power: the exponent (default 2 for quadratic)
function easing.ease_in_out(t, power)
  power = power or 2
  if t < 0.5 then
    return (2 ^ (power - 1)) * (t ^ power)
  else
    return 1 - ((-2 * t + 2) ^ power) / 2
  end
end

-- ease out bounce: decelerates with a bouncing effect
function easing.ease_out_bounce(t)
  if t < 1 / 2.75 then
    return 7.5625 * t * t
  elseif t < 2 / 2.75 then
    t = t - 1.5 / 2.75
    return 7.5625 * t * t + 0.75
  elseif t < 2.5 / 2.75 then
    t = t - 2.25 / 2.75
    return 7.5625 * t * t + 0.9375
  else
    t = t - 2.625 / 2.75
    return 7.5625 * t * t + 0.984375
  end
end

return easing
