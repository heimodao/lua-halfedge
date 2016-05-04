require 'ply'
math.randomseed(os.time())
function make_tetrahedron()
	local mesh={}
	mesh.points={
		{1,1,1},
		{-1,-1,1},
		{-1,1,-1},
		{1,-1,-1}
	}
	mesh.triangles={
		{2,1,0},
		{1,2,3},
		{3,2,0},
		{0,1,3}
	}
	return mesh
end
--save_mesh(make_tetrahedron(),"tetra.ply")
function to_triangles( model ) --from half-edge to ply compatable triangles (0 based tri index)
	local mesh={}
	mesh.points=model.points
	local pt_mapping={}
	for i,v in ipairs(model.points) do
		pt_mapping[v]=i
	end
	mesh.triangles={}
	for i,v in ipairs(model.faces) do
		local tri={}
		local e=v.edge
		repeat
			table.insert(tri,pt_mapping[e.vert]-1)
			e=e.next
		until e==v.edge
		if #tri>3 then
			for i,v in ipairs(tri) do
				print(i,v)
			end
			error(("Face %d has too many edges: %d"):format(i,#tri))
		end
		table.insert(mesh.triangles,tri)
	end
	return mesh
end
function prev_edge( edge )
	local cur=edge
	while cur.next do
		if cur.next==edge then
			return cur
		else
			cur=cur.next
		end
	end
end
function prev_vertex_edge( edge ) --not performant
	return prev_edge(edge).pair
end
function next_vertex_edge( edge )
	return edge.pair.next
end
function edge_end( edge )
	return edge.pair.vert
end

function make_edge( v1,v2 ,f1,f2)
	local e1={vert=v1,face=f1}
	local e2={vert=v2,face=f2}
	e1.pair=e2
	e2.pair=e1
	return e1,e2
end
function make_half_edge(vertex_count,radius)
	radius=radius or 1
	local points={}
	local edges_f={}
	local edges_r={}
	local angle_step=2*math.pi/vertex_count

	for i=1,vertex_count do
		points[i]={math.cos(angle_step*i)*radius,math.sin(angle_step*i)*radius,0}
	end

	local f1={}
	local f2={}
	for i=1,vertex_count do
		local this=points[i]
		local next_id=math.fmod(i,vertex_count)+1
		local next=points[next_id]

		local e1,e2=make_edge(this,next,f1,f2)
		edges_f[i]=e1
		edges_r[vertex_count-i+1]=e2
	end
	f1.edge=edges_f[1]
	f2.edge=edges_r[1]
	for i=1,vertex_count do
		local next=math.fmod(i,vertex_count)+1
		local e1=edges_f[i]
		e1.next=edges_f[next]
		local e2=edges_r[i]
		e2.next=edges_r[next]
	end

	local hf={points=points,edges={},faces={f1,f2}}
	for i,v in ipairs(edges_f) do
		table.insert(hf.edges,v)
	end
	for i,v in ipairs(edges_r) do
		table.insert(hf.edges,v)
	end

	return hf
end

function vertex_split(new_v,e_start,e_end,model ) --vertex split: add a new vertex and move some edges with it
	--[=[if e_end==nil then
		e_end=next_vertex_edge(e_start)
		--[[while e_end.pair.face~=e_start.face do
			e_end=next_vertex_edge(e_end)
		end]]
	end
	--]=]
	--find affected edges
	
	local affected={}
	local f2
	if e_end~=nil then
		local cur_edge=e_start
		while cur_edge~=e_end do
			cur_edge=next_vertex_edge(cur_edge)
			if cur_edge~=e_end then
				table.insert(affected,cur_edge)
			end
		end
		f2=e_end.pair.face
	end
	--gen two half edges
	local v=e_start.vert
	
	local e1,e2=make_edge(v,new_v,e_start.face,f2 or e_start.face)
	if #affected>0 then
		--set vertex
		for i,v in ipairs(affected) do
			v.vert=new_v
		end
		--link them in:
		assert(affected[1]==e_start.next)
		assert(affected[#affected].next==e_end.pair)

		e_end.pair.next=e1
		e1.next=affected[1] --prob e2 if empty
		affected[#affected].next=e2 --prob nothing if empty
		e2.next=e_start
	else
		--no edges are "dragged" with the new point
		local prev=prev_edge(e_start)
		
		prev.next=e1
		e1.next=e2
		e2.next=e_start
	end
	table.insert(model.points,new_v)
	table.insert(model.edges,e1)
	table.insert(model.edges,e2)
	return e1
end
--edge collapse (opossite to vertex split)
function face_split(hf1,hf2,model)
	-- add new he from hf1 to hf2
	assert(hf1~=hf2)
	assert(hf1.face==hf2.face) --nonsense
	local v1=hf1.vert
	local v2=hf2.vert
	assert(v1~=v2)
	assert(hf1.next~=hf2)-- this is a simple edge (face would have 0 edges?)
	local old_prev=prev_edge(hf1)
	local new_face={}
	local e1,e2=make_edge(v2,v1,new_face,hf1.face)
	local cur_edge=hf1
	while cur_edge.next~=hf2 do
		cur_edge.face=new_face
		cur_edge=cur_edge.next
	end
	cur_edge.face=new_face
	e1.next=hf1
	e2.next=hf2
	cur_edge.next=e1
	old_prev.next=e2

	new_face.edge=e1
	hf2.face.edge=hf2
	table.insert(model.edges,e1)
	table.insert(model.edges,e2)
	table.insert(model.faces,new_face)
	return new_face,e1
end
function face_normal_simple(face )
	local e1=face.edge.vert
	local e2=face.edge.next.vert
	local e3=face.edge.next.pair.vert
	local u={e1[1]-e2[1],e1[2]-e2[2],e1[3]-e2[3]}
	local v={e3[1]-e2[1],e3[2]-e2[2],e3[3]-e2[3]}

	local cross={u[2]*v[3]-u[3]*v[2],u[3]*v[1]-u[1]*v[3],u[1]*v[2]-u[2]*v[1]}
	local len=math.sqrt(cross[1]*cross[1]+cross[2]*cross[2]+cross[3]*cross[3])
	return {-cross[1]/len,-cross[2]/len,-cross[3]/len}
end
--more complex:
function extrude( face,vec ,model)
	vec=vec or 0
	if type(vec)=="number" then
		local n=face_normal_simple(face)
		local d=vec
		vec={n[1]*d,n[2]*d,n[3]*d}
	end
	--print_edges_for_face(face)
	local e=face.edge
	local edges={}
	while e.next~=face.edge do
		table.insert(edges,e)
		e=e.next
	end
	table.insert(edges,e)
	--print("Extruding:",#edges)
	local new_edges={}
	for i,v in ipairs(edges) do
		local nv={v.vert[1]+vec[1],v.vert[2]+vec[2],v.vert[3]+vec[3]}
		local ne=vertex_split(nv,v,nil,model)
		table.insert(new_edges,ne.pair)
	end
	--print_edges_for_face(face)
	for i=1,#new_edges-1 do
		local e1=new_edges[i]
		local e2=new_edges[i+1]
		face_split(e1,e2,model)
	end
	local first=new_edges[1]
	--print("First:",first.face,prev_vertex_edge(first).face,first.pair.face)
	--[[do
		local cur=first
		while next_vertex_edge(cur)~=first do
			print(cur.face)
			cur=next_vertex_edge(cur)
		end
	end]]

	local last=new_edges[#new_edges]
	--print("Last:",last.pair.face)
	--[[
	local last_edge
	do
		local cur=last
		while next_vertex_edge(cur)~=last do
			print(cur.face)
			if cur.face==first.face then
				last_edge=cur
				break
			end
			cur=next_vertex_edge(cur)
		end
		if last_edge==nil then
			error("failed to find edge to split face")
		end
	end]]

	face_split(e.next.next,prev_edge(e),model)
end
function triangulate_quads( model ,fail_on_poly)
	local quads={}
	for i,v in ipairs(model.faces) do
		local e=v.edge
		local edges={}
		while e.next~=v.edge do
			table.insert(edges,e)
			e=e.next
		end
		table.insert(edges,e)
		if #edges> 4 and fail_on_poly then
			error(("Face %d has more than 4 edges (%d)"):format(i,#edges))
		end
		if #edges==4 then
			table.insert(quads,v)
		end
		print(("Face %d edges %d"):format(i,#edges))
	end
	print("Triangulating "..#quads.." quads")
	for i,v in ipairs(quads) do
		local e=v.edge
		local edges={}
		while e.next~=v.edge do
			table.insert(edges,e)
			e=e.next
		end
		face_split(edges[1],edges[3],model)
	end
end
function triangulate_simple( model )
	local polygons={}
	for i,v in ipairs(model.faces) do
		local e=v.edge
		local edges={}
		while e.next~=v.edge do
			table.insert(edges,e)
			e=e.next
		end
		table.insert(edges,e)
		if #edges>=4 then
			table.insert(polygons,v)
		end
		
	end
	print("Triangulating "..#polygons.." polygons")
	for i,v in ipairs(polygons) do
		spike(v,0,model)
	end
end
function get_num( tbl,o )
	if tbl.next_num==nil then tbl.next_num=1 end
	if tbl[o]==nil then
		tbl[o]=tbl.next_num
		tbl.next_num=tbl.next_num+1
	end
	return tbl[o]
end
function check_invariants_he(he,name)
	assert(he==prev_edge(he.next),name) --prev(next(e))
	assert(he==prev_edge(he).next,name) --next(prev(e))
	assert(he==he.pair.pair,name) 
	assert(he.face==he.next.face,name)
end
function check_invariants_vert(v)
	--not used
end
function check_invariants_face( f ,name)
	assert(f.edge.face==f,name)
end

function check_model( model )
	print("Checking model")
	for i,v in ipairs(model.edges) do
		check_invariants_he(v,i)
	end
	for i,v in ipairs(model.faces) do
		check_invariants_face(v,i)
	end
end

function print_edges_for_face( face )
	print(" Face ",face," edges")
	local edge_numbers={}
	local vert_numbers={}
	local c_e = face.edge
	repeat
		
		print(get_num(edge_numbers,c_e),get_num(vert_numbers,c_e.vert))
		c_e=c_e.next
	until c_e==face.edge
end
function get_face_edges( face )
	local e=face.edge
	local edges={}
	while e.next~=face.edge do
		table.insert(edges,e)
		e=e.next
	end
	table.insert(edges,e)
	return edges
end
function spike( face,vec_offset,model )
	vec_offset=vec_offset or 0
	if type(vec_offset)=="number" then
		local n=face_normal_simple(face)
		local d=vec_offset
		vec_offset={n[1]*d,n[2]*d,n[3]*d}
	end
	local center={0,0,0}
	local e=get_face_edges(face)
	for i,v in ipairs(e) do
		center={center[1]+v.vert[1],center[2]+v.vert[2],center[3]+v.vert[3]}
	end
	center[1]=center[1]/#e+vec_offset[1]
	center[2]=center[2]/#e+vec_offset[2]
	center[3]=center[3]/#e+vec_offset[3]

	local e_n=vertex_split(center,e[1],nil,model)

	for i=1,#e-1 do
		local f,nn=face_split(e_n.pair,e_n.pair.next.next,model)
		e_n=nn
	end
end
--tri test:
do
	local hf=make_half_edge(3,1)
	save_mesh(to_triangles(hf),"tri.ply")
end
--tetrahedron test:
do
	local hf=make_half_edge(3,1)
	
	spike(hf.faces[1],{0,0,math.sqrt(2)},hf)
	--[[
	local e=hf.edges[1]
	print_edges_for_face(e.face)
	local e_n=vertex_split({0,0,1},e,next_vertex_edge(e),hf)
	print_edges_for_face(e_n.face)
	check_model(hf)
	local e_nn=e_n.next.next.next
	local nf,e_t=face_split(e_n.next,e_nn,hf)
	print_edges_for_face(nf)
	check_model(hf)

	face_split(e_t.pair,e_t.pair.next.next,hf)
	check_model(hf)
	--]]
	save_mesh(to_triangles(hf),"tetra.ply")
end
do
	local hf=make_half_edge(4,1)
	
	spike(hf.faces[1],{0,0,math.sqrt(2)},hf)
	spike(hf.faces[2],{0,0,-math.sqrt(2)},hf)
	save_mesh(to_triangles(hf),"rhombus.ply")
end
do
	local hf=make_half_edge(4,1)
	
	spike(hf.faces[1],{0,0,math.sqrt(2)},hf)
	spike(hf.faces[2],{0,0,-math.sqrt(2)},hf)
	extrude(hf.faces[math.random(1,#hf.faces)],0.2,hf)
	spike(hf.faces[math.random(1,#hf.faces)],0.2,hf)
	triangulate_quads(hf,true)
	save_mesh(to_triangles(hf),"rand.ply")
end
--square test:
do
	local hf=make_half_edge(4,1)
	--[[local e=hf.edges[1]
	face_split(e,e.next.next,hf)
	check_model(hf)
	face_split(e.pair,e.pair.next.next,hf)
	check_model(hf)]]
	triangulate_quads(hf,true)
	save_mesh(to_triangles(hf),"square.ply")
end
--prism test:
do

	local hf=make_half_edge(3,1)
	extrude(hf.faces[1],{0,0,1},hf)
	check_model(hf)
	triangulate_quads( hf,true)
	save_mesh(to_triangles(hf),"prism.ply")
end
--prism square test:
do

	local hf=make_half_edge(4,1)
	extrude(hf.faces[1],{0,0,1},hf)
	check_model(hf)
	triangulate_quads( hf,true)
	save_mesh(to_triangles(hf),"prism4.ply")
end
--prism square test:
do

	local hf=make_half_edge(4,1)
	extrude(hf.faces[1],{0,0,1},hf)
	check_model(hf)
	triangulate_quads( hf,true)
	save_mesh(to_triangles(hf),"prism4.ply")
end
--cylinder test:
do
	local hf=make_half_edge(16,1)
	extrude(hf.faces[1],{0,0,1},hf)
	triangulate_quads( hf,false)
	triangulate_simple( hf)
	save_mesh(to_triangles(hf),"cylinder.ply")
	
end