local model=require 'halfedge'
local ply=require 'ply'
local point=require 'point'
local inf=math.huge

local mesh=ply.load('230-2-1_L.ply')
local points=mesh.points
print("Loaded:",#points," points")

function find_bbox( pts )
	local min=point(inf,inf,inf)
	local max=point(-inf,-inf,-inf)
	for i,v in ipairs(pts) do
		for i=1,3 do
			if min[i]>v[i] then min[i]=v[i] end
			if max[i]<v[i] then max[i]=v[i] end
		end
	end
	return min,max
end

local min,max=find_bbox(points)

local mesh=model()
mesh:gen_disk(4,1)
local top=next(mesh.faces)
--set points
do
	local e=top.edge
	local p=e.point
	p:set{min[1],min[2],min[3]}

	e=e.next
	p=e.point
	p:set{max[1],min[2],min[3]}

	e=e.next
	p=e.point
	p:set{max[1],max[2],min[3]}

	e=e.next
	p=e.point
	p:set{min[1],max[2],min[3]}
end
top=mesh:extrude(top,max[3]-min[3])
function distance_to_plane( plane,p )
	return (plane[1]..p)+plane[2]
end
function face_distance( face,pts ,max_counted)
	local plane=face:plane_simple()
	local sum=0
	local count=0
	for i,v in ipairs(pts) do
		local d=distance_to_plane(plane,point(v[1],v[2],v[3]))
		if math.abs(d)<max_counted then
			--if d>0 then d=d*(-100) end
			sum=sum+d*d
			count=count+1
		end
	end
	return math.sqrt(sum),count
end
function vertex_count(edge)
	local sum=0
	local count=0

	for e in edge:point_edges() do
		local s,c=face_distance(e.face,points,100)
		sum=sum+s
		count=count+c
	end

	return sum,count
end
function rand_pt()
	return point((math.random()*2-1),(math.random()*2-1),(math.random()*2-1))
end
function simulated_annealing( edge, dist, max_steps,T)

	local p=edge.point+point(0,0,0) --copy the point
	local function temperature( t )
		return 2-t*2
	end
	local w=function ( e )
		local s,c=vertex_count(e)
		return s/math.sqrt(c)
	end
	local best_w=w(edge)
	for i=1,max_steps do
		local T=temperature(i/max_steps)
		local np=p+dist*rand_pt()

		edge.point:set(np)
		local new_w=w(edge)
		local delta_w=new_w-best_w
		local chance_worse=math.exp(-(delta_w)/T)--(max_steps-i+1)/max_steps
		if delta_w>0 then
			print("i:",i,"Chance:",chance_worse,"Delta:",delta_w)
		end

		if delta_w<0 or chance_worse>math.random() then
			--print("Step:",i,"new w:",best_w)
			best_w=new_w
			p=np
		end
	end
	edge.point:set(p)
end
print(vertex_count(top.edge))
local move_dist=10
local step_count=100
local e=top.edge
for i=1,4 do
	simulated_annealing(e,move_dist,step_count)
	e=e.next
end


--mesh:triangulate_simple()
ply.save_half_edge(mesh,"shrink.ply")