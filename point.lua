-- point.lua
-- A class representing vectors in 3D
-- (for class.lua, see SimpleLuaClasses)
local class=require 'class'

local Point = class(function(pt,x,y,z)
   pt:set(x,y,z or 0)
 end)

local function eq(x,y)
  return x == y
end

--function Point.__eq(p1,p2)
--  return eq(p1[1],p2[1]) and eq(p1[2],p2[2]) and eq(p1[3],p2[3])
--end

function Point.get(p)
  return p[1],p[2],p[3]
end

-- vector addition is '+','-'
function Point.__add(p1,p2)
  return Point(p1[1]+p2[1], p1[2]+p2[2], p1[3]+p2[3])
end

function Point.__sub(p1,p2)
  return Point(p1[1]-p2[1], p1[2]-p2[2], p1[3]-p2[3])
end

-- unitary minus  (e.g in the expression f(-p))
function Point.__unm(p)
  return Point(-p[1], -p[2], -p[3])
end

-- scalar multiplication and division is '*' and '/' respectively
function Point.__mul(s,p)
  return Point( s*p[1], s*p[2], s*p[3] )
end

function Point.__div(p,s)
  return Point( p[1]/s, p[2]/s, p[3]/s )
end

-- dot product is '..'
function Point.__concat(p1,p2)
  return p1[1]*p2[1] + p1[2]*p2[2] + p1[3]*p2[3]
end

-- cross product is '^'
function Point.__pow(p1,p2)
   return Point(
     p1[2]*p2[3] - p1[3]*p2[2],
     p1[3]*p2[1] - p1[1]*p2[3],
     p1[1]*p2[2] - p1[2]*p2[1]
   )
end

function Point.normalize(p)
  local l = p:len()
  p[1] = p[1]/l
  p[2] = p[2]/l
  p[3] = p[3]/l
end

function Point.set(pt,x,y,z)
  if type(x) == 'table'  then --and getmetatable(x) == Point
     local po = x
     x = po[1]
     y = po[2]
     z = po[3]
  end
  pt[1] = x
  pt[2] = y
  pt[3] = z 
end

function Point.translate(pt,x,y,z)
   pt[1] = pt[1] + x
   pt[2] = pt[2] + y
   pt[3] = pt[3] + z 
end

function Point.__tostring(p)
  return string.format('(%f,%f,%f)',p[1],p[2],p[3])
end

local function sqr(x) return x*x end

function Point.len(p)
  return math.sqrt(sqr(p[1]) + sqr(p[2]) + sqr(p[3]))
end
function Point.len_sq(p)
  return sqr(p[1]) + sqr(p[2]) + sqr(p[3])
end
--2d only!
function Point.rotate(p,angle,pivot)
  local s = math.sin(angle);
  local c = math.cos(angle);
  local ret
  pivot=pivot or Point(0,0)
  
  ret=Point(p[1]-pivot[1],p[2]-pivot[2])
  
  local xnew = ret[1] * c - ret[2] * s;
  local ynew = ret[1] * s + ret[2] * c;

  
  ret[1]=xnew+pivot[1]
  ret[2]=ynew+pivot[2]
  return ret
end

return Point