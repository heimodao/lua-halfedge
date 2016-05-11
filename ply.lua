function save_mesh(mesh,filename)
	local f=io.open(filename,"w")
	local s=[[ply
format ascii 1.0
comment made by lua ply module
element vertex %d
property float x
property float y
property float z
element face %d
property list uchar int vertex_index
end_header
]]
	f:write(string.format(s,#mesh.points,#mesh.triangles))
	for i,v in ipairs(mesh.points) do
		f:write(string.format("%f %f %f\n",v[1],v[2],v[3]))
	end
	for i,v in ipairs(mesh.triangles) do
		f:write(string.format("3 %d %d %d\n",v[1],v[2],v[3]))
	end
end
function save_half_edge(mesh,filename,faces)
	local f=io.open(filename,"w")
	local s=[[ply
format ascii 1.0
comment made by lua ply module
element vertex %d
property float x
property float y
property float z
element face %d
property list uchar int vertex_index
end_header
]]
	local pt_counter = 0
	for v,_ in pairs(mesh.points) do pt_counter=pt_counter+1 end
	local face_counter=0
	for v,_ in pairs(mesh.faces) do face_counter=face_counter+1 end
	local face_count=face_counter
	if faces then face_count=#faces end

	f:write(string.format(s,pt_counter,face_count))

	local pt_mapping={} --point mapping for quick index lookup
	local count=1
	for v,_ in pairs(mesh.points) do
		f:write(string.format("%f %f %f\n",v[1],v[2],v[3]))
		pt_mapping[v]=count
		count=count+1
	end

	local save_face=function ( v )
		local s="%d"
			local count=0
			for e in v:edges() do
				s=s.." "..pt_mapping[e.point]-1
				count=count+1
			end
			s=s.."\n"
			f:write(string.format(s,count))
	end

	if faces==nil then
		for v,_ in pairs(mesh.faces) do
			save_face(v)
		end
	else
		for v,_ in pairs(faces) do
			save_face(v)
		end
	end
end

return {save=save_mesh,save_half_edge=save_half_edge}