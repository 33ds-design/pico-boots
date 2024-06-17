function vector.unit_from_angle(angle)
  return vector(cos(angle), sin(angle))
end

-- return copy of vector rotated by angle degrees
function vector:rotated(angle)
  -- in PICO-8, no need to handle angles of 0, 0.25, 0.5, 0.75
  --  with a manual copy, rotated_90_ccw, * -1, rotated_90_cw
  --  for perfect precision thx to the fixed point precision
  -- but in busted utests, expect cos/sin to be imprecise and check for almost_equal
  local sa = sin(angle)
  local ca = cos(angle)
  return vector(ca * self.x - sa * self.y, sa * self.x + ca * self.y)
end
