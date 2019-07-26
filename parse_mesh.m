function [nodes faces] = parse_mesh(fname)

% parses a .vtu mesh (assumes a tetrahedral mesh)

mesh_tree = xml2struct(fname);
nodes = mesh_tree.VTKFile.UnstructuredGrid.Piece.Points.DataArray.Text;
nodes = str2mat(strsplit(nodes));
nodes = str2num(nodes(:, 1:6));
nodes = [nodes(1:3:end) nodes(2:3:end) nodes(3:3:end)];
% mesh = mesh*10; % convert to mm

offsets = mesh_tree.VTKFile.UnstructuredGrid.Piece.Cells.DataArray{2}.Text;
offsets = str2mat(strsplit(offsets));
offsets = str2num(offsets(:, 1:end));
offsets = [0; offsets];

connectivity = mesh_tree.VTKFile.UnstructuredGrid.Piece.Cells.DataArray{1}.Text;
connectivity = str2mat(strsplit(connectivity));
connectivity = str2num(connectivity(:, 1:end));
connectivity = connectivity + 1; % matlab indexing

% based on the offsets determine correct connectivity (assuming
% tetrahedral elements)
i=1;
while offsets(i+1) - offsets(i) == 4
    faces(i, :) = connectivity(offsets(i)+1:offsets(i+1));
    i = i + 1;
end