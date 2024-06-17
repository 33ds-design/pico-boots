-- return copy of vector rotated by 90 degrees clockwise (for top-left origin)
function vector:rotated_90_cw()
  return vector(-self.y, self.x)
end

-- rotate vector by 90 degrees clockwise in-place
function vector:rotate_90_cw_inplace()
  self:copy_assign(self:rotated_90_cw())
end

-- return copy of vector rotated by 90 degrees counter-clockwise (for top-left origin)
function vector:rotated_90_ccw()
  return vector(self.y, -self.x)
end

-- rotate by 90 degrees counter-clockwise in-place
function vector:rotate_90_ccw_inplace()
  self:copy_assign(self:rotated_90_ccw())
end
