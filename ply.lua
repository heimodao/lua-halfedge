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