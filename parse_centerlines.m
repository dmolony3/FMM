function [centerline_interp radius_interp] = parse_centerlines(fname, interp, split)

% parses a .vtp centerline and return interpolated centerlines and radii
% split argument determine whether the returned centerlines for each vessel
% should be full source to target centerline (False) or split at branch
% point centerline (True)

% if interpolation argument not provided assume every 0.5mm
if nargin == 1
    interp = 0.5;
end

centerline_tree = xml2struct(fname);
centerline = centerline_tree.VTKFile.PolyData.Piece.Points.DataArray.Text;
centerline = str2mat(strsplit(centerline));
centerline = str2num(centerline(:, 1:6));
centerline = [centerline(1:3:end) centerline(2:3:end) centerline(3:3:end)];
% centerline = centerline*10; % convert to mm

try
    radius = centerline_tree.VTKFile.PolyData.Piece.PointData.DataArray{1}.Text;
catch
    radius = centerline_tree.VTKFile.PolyData.Piece.PointData.DataArray.Text;    
end
radius = str2mat(strsplit(radius));
radius = str2num(radius(:, 1:6));
% radius = radius.*10; % convert to mm

for i = 1:length(centerline_tree.VTKFile.PolyData.Piece.CellData.DataArray)
    if strcmp(centerline_tree.VTKFile.PolyData.Piece.CellData.DataArray{i}.Attributes.Name,  'CenterlineIds')
        centerline_idx = i;
    end
    if strcmp(centerline_tree.VTKFile.PolyData.Piece.CellData.DataArray{i}.Attributes.Name,  'GroupIds')
        group_idx = i;
    end
end
        
group_ids = centerline_tree.VTKFile.PolyData.Piece.CellData.DataArray{group_idx}.Text;
group_ids = str2mat(strsplit(group_ids));
group_ids = str2num(group_ids(:, 1:end));

centerline_ids = centerline_tree.VTKFile.PolyData.Piece.CellData.DataArray{centerline_idx}.Text;
centerline_ids = str2mat(strsplit(centerline_ids));
centerline_ids = str2num(centerline_ids(:, 1:end));

connectivity = centerline_tree.VTKFile.PolyData.Piece.Lines.DataArray{1}.Text;
connectivity = str2mat(strsplit(connectivity));
connectivity = str2num(connectivity(:, 1:end));
connectivity = [connectivity(1:2:end-1+mod(connectivity(end), 2)) connectivity(2:2:end-1+mod(connectivity(end), 2))];

offsets = centerline_tree.VTKFile.PolyData.Piece.Lines.DataArray{2}.Text;
offsets = str2mat(strsplit(offsets));
offsets = str2num(offsets(:, 1:end));
offsets = [1; offsets];

% reformat group ids with respect to offsets
group_ids2 = zeros(length(centerline), 1);
for i=1:length(offsets)-1
    idx=offsets(i:i+1);
    group_ids2(idx(1):idx(2)) = group_ids(i);
end

if split == 0
    % associate centerline id with group id
    for i =1:length(offsets)-1
        idx=offsets(i:i+1);
        centerline_group_id(i, :) = [centerline_ids(i) group_ids(i)];
    end

    for i = 0:max(centerline_ids)
        current_group = centerline_group_id(centerline_group_id(:, 1) == i, 2);
        group_idx = ismember(group_ids2, current_group);
        centerline_seg{i+1} = centerline(group_idx, :);
        radius_seg{i+1} = radius(group_idx);
    end    

    for i = 0:max(centerline_ids)
        current_group = centerline_group_id(centerline_group_id(:, 1) == i, 2);
        centerline_seg = {};
        eligible = find(centerline_group_id(:, 1) == i);
        for j=1:length(current_group)
            idx = find(group_ids == current_group(j));
            idx = eligible(ismember(eligible, idx));
            idx = offsets(idx)+1:offsets(idx+1);
            centerline_seg{j} = centerline(idx, :);
            radius_seg{j} = radius(idx);
        end
        % remove non unique entries
        centerline_temp1 = cell2mat(centerline_seg');
        [centerline_temp2, u1, u2] = unique(centerline_temp1, 'rows');
        centerline_temp2 = centerline_temp1(sort(u1), :);
        radius_temp = cell2mat(radius_seg');
        radius_temp = radius_temp(sort(u1));
        centerline_segments{i+1} = centerline_temp2;
        radius_segments{i+1} = radius_temp;
    end

elseif split == 1
    % reformat centerline ids with respect to offsets
    centerline_ids2 = zeros(length(centerline), 1);
    ready_for_next_zero = 0;
    zero_count = 0;
    for i=1:length(group_ids2)
        if group_ids2(i) == 0 
            if ready_for_next_zero == 1
                zero_count = zero_count + 1;
            end
            centerline_ids2(i) = zero_count;
            ready_for_next_zero = 0;
        else
            centerline_ids2(i) = zero_count;
            ready_for_next_zero = 1;
        end   
    end
    
    % separate the centerline into branches
    all_groups = [];
    figure, plot3(centerline(:, 1), centerline(:, 2), centerline(:, 3), '.')
    hold on
    colors = {'r', 'g', 'y', 'k', 'm', 'c', 'o'};
    colors = rand(max(centerline_ids)+1, 3);
    for i=1:max(centerline_ids) + 1
        idx1 = find(centerline_ids2 == i-1);
        if ~isempty(idx1)
            groups = unique(group_ids2(idx1));
            unique_groups = groups(~ismember(groups, all_groups));
            idx2 = [];
            for j = 1:length(unique_groups)
                idx2 = [idx2; find(group_ids2 == unique_groups(j))];
            end
            idx = idx1(1) + find(ismember(idx1, idx2));
            idx(idx > length(centerline)) = [];
    %         plot3(centerline(idx, 1), centerline(idx, 2), centerline(idx, 3), colors{i}, 'linewidth', 4)
            plot3(centerline(idx, 1), centerline(idx, 2), centerline(idx, 3), 'Color', colors(i, :), 'linewidth', 6)
            all_groups = [all_groups; groups];
            centerline_segments{i} = centerline(idx, :);
            radius_segments{i} = radius(idx);
            % remove non unique entries
            centerline_temp1 = centerline_segments{i};
            [centerline_temp2, u1, u2] = unique(centerline_temp1, 'rows');
            centerline_segments{i} = centerline_temp1(sort(u1), :);
            radius_temp = radius_segments{i};
            radius_segments{i} = radius_temp(sort(u1));
        end
    end
end

% interpolate centerlines at desired interval
for i = 1:length(centerline_segments)
    % determine centerline lengths
    dist = sqrt((centerline_segments{i}(2:end, 1) - centerline_segments{i}(1:end-1, 1)).^2 + ...
        (centerline_segments{i}(2:end, 2) - centerline_segments{i}(1:end-1, 2)).^2 + ...
        (centerline_segments{i}(2:end, 3) - centerline_segments{i}(1:end-1, 3)).^2);
    dist = cumsum([0; dist]);
    % interpolate at specified interval
    centerline_dist = linspace(0, dist(end), round(dist(end)/interp));
    centerline_interp{i} = interp1(dist, centerline_segments{i}, centerline_dist);
    radius_interp{i} = interp1(dist, radius_segments{i}, centerline_dist);
end