local model=require 'halfedge'
local ply=require 'ply'
local point=require 'point'

do
	local m=model()
	m:gen_disk(3)
	m:check_invariants()
	ply.save(m:make_tri_mesh(),"tri.ply")
end
do
	local m=model()
	m:gen_disk(3)
	m:spike(next(m.faces),1)
	m:check_invariants()
	ply.save_half_edge(m,"tetra.ply")
end
function rounded_spike( m,face,height,steps )
	--TODO: think of a way to calculate w and h per step
	for i=1,steps-1 do
		face=m:bevel_face(face,w,h)
	end
	m:spike(face,h)
end
do
	local m=model()
	m:gen_disk(10)
	local top=next(m.faces)
	top=m:extrude(top,1)
	top=m:bevel_face(top,0.4,0.1)
	top=m:bevel_face(top,0.3,0.2)
	top=m:bevel_face(top,0.2,0.3)
	--top=m:bevel_face(top,0.1,0.4)
	for e in top:edges() do
		e.point:translate(0,0,-0.1)
	end
	m:spike(top,0.05)
	--top=m:bevel_face(top,0.2)
	--top=m:bevel_face(top,0.1)
	--top=m:bevel_face(top,0.05)
	--top=m:bevel_face(top,0.1)
	--[[for i=1,2 do
		top=m:bevel_face(top,1)
	end]]
	--m:triangulate_simple()
	ply.save_half_edge(m,"rounded.ply")
end
function bend(m, face,d ,edge_num)
	local top=m:extrude(face,0)
	local normal=top:normal_simple()
	local e=top.edge
	for i=1,edge_num-1 do
		e=e.next
	end
	e.point:set(e.point+d*normal)
	return top
end
function spin_face( m,face,angle,axis)
	if axis==nil then
		axis=face:normal_simple()
	end

	local center=point(0,0,0)
	local count=0
	for e in face:edges() do
		center=center+e.point
		count=count+1
	end
	center=center/count
	for e in face:edges() do
		local v=e.point-center
		local rotated=math.cos(angle)*v+math.sin(angle)*(axis^v)+(1-math.cos(angle))*(axis..v)*axis
		e.point:set(rotated+center)
	end
end
do
	local m=model()
	m:gen_disk(3)
	local f=m:extrude(next(m.faces),1)
	--[[local top=f
	local h=0
	local w=0.3
	for i=1,3 do
		top=m:bevel_face(top,h,w)
		top=m:extrude(top,0.4)
		h=h+0.1
		w=w-0.1
	end]]
	--[[f=m:bevel_face(,f,0.2,0.2,{[1]=true})
	m:triangulate_quads(true)
	f=m:extrude(f,0.3)
	f=m:bevel_face(f,0.2,0.2,{[2]=true})
	m:triangulate_quads(true)
	f=m:extrude(f,0.3)
	f=m:bevel_face(f,0.2,0.2,{[3]=true})
	m:triangulate_quads(true)]]
	for i=1,10 do
		if math.fmod(i,2)==1 then
			spin_face(m,f,math.pi/6)
		end
		f=m:extrude(f,1)
	end
	spin_face(m,f,math.pi/6)
	local ff=m:spike(f,1)
	for i,v in ipairs(ff) do
		local f=m:extrude(v,0.5)
		spin_face(m,f,0.2)
		m:spike(f,0.5)
	end
	--[[for i=1,11 do
		f=bend(m,f,0.2,i*2)
		f=m:extrude(f,0.3)
	end]]

	m:triangulate_simple()
	m:check_invariants()
	ply.save_half_edge(m,"prism.ply")
end
do
	local m=model()
	m:gen_disk(6,0.2)
	local f=m:extrude(next(m.faces),3)
	spin_face(m,f,math.pi/8,point(1,0,0))
	f=m:extrude(f,1)
	m:triangulate_simple()
	ply.save_half_edge(m,"flower.ply")
end
function print_face( f )
	print("Face:",f)
	for e in f:edges() do
		print(e)
	end
end

do
	local m=model()
	m:gen_disk(4,math.sqrt(2)/2)
	local first_face=next(m.faces)
	local second_face=next(m.faces,first_face)
	local top=m:extrude(first_face,1)
	--[[local p=top.edge.point+point(0,0,0.2)
	for e in top:edges() do
		print("Edge:",e)
		local c=e:next_point_edge()
		while c~=e do
			print(c)
			c=c:next_point_edge()
		end
	end
	local e_split=m:vertex_split(p,top.edge,top.edge:next_point_edge())]]
	m:bevel_edge(top.edge,0.05)
	m:bevel_edge(top.edge.next.next,0.05)
	m:bevel_edge(second_face.edge,0.05)
	m:bevel_edge(second_face.edge.next.next,0.05)
	local f1=top.edge.next.pair.face
	local f2=top.edge.next.next.next.pair.face
	f1=m:bevel_face(f1,0.02)
	f2=m:bevel_face(f2,0.02)

	m:check_invariants()
	m:triangulate_quads(false)
	m:triangulate_simple()
	ply.save_half_edge(m,"cube.ply")

end
