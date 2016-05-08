local model=require 'halfedge'
local ply=require 'ply'
local point=require 'point'

do
	local m=model()
	m:gen_disk(3)
	for e in m.faces[1]:edges() do
		print(e,e.point)
	end
	m:check_invariants()
	ply.save(m:make_tri_mesh(),"tri.ply")
end

do
	local m=model()
	m:gen_disk(3)
	m:spike(m.faces[1],1)
	m:check_invariants()
	ply.save_half_edge(m,"tetra.ply")
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
	local f=m:extrude(m.faces[1],1)
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
	local f=m:extrude(m.faces[1],3)
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
	local top=m:extrude(m.faces[1],1)
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
	m:bevel_edge(m.faces[2].edge,0.05)
	m:bevel_edge(m.faces[2].edge.next.next,0.05)
	local f1=top.edge.next.pair.face
	local f2=top.edge.next.next.next.pair.face
	f1=m:bevel_face(f1,0.02)
	f2=m:bevel_face(f2,0.02)

	m:check_invariants()
	m:triangulate_quads(false)
	m:triangulate_simple()
	ply.save_half_edge(m,"cube.ply")

end
