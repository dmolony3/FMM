function FMM_GUI

% GUI for determining the fractional myocardial mass. 

% create GUI
figure_dimensions = get(0, 'ScreenSize');
GUI.Fig = figure('position', figure_dimensions, 'menu','none');
background_color = get(GUI.Fig, 'color');
set(gcf, 'toolbar', 'figure' )
cameratoolbar('Show')
aspect_ratio = figure_dimensions(3)/figure_dimensions(4);
square = [0.25 0.25*aspect_ratio];
GUI.Ax1 = axes('Parent', GUI.Fig, 'Units', 'normalized', 'position', [0.05 0.4 1.75*square(1) 1.75*square(2)]);
axis(GUI.Ax1, 'equal')
xlabel(GUI.Ax1, 'x')
ylabel(GUI.Ax1, 'y')
zlabel(GUI.Ax1, 'z')

GUI.centerline_list = uicontrol('Parent',GUI.Fig,  'style', 'listbox', 'Units', 'normalized', 'string', {}, ...
    'Position',[0.525 0.6 0.175 0.3],'callback',@centerlineSelected1, 'Max', 10);
GUI.merge_list = uicontrol('Parent',GUI.Fig, 'style', 'listbox', 'Units', 'normalized', 'string', {}, ...
    'Position',[0.8 0.6 0.175 0.3], 'callback',@centerlineSelected2, 'Max', 10);

arrow = imread('arrow.png');
% get short axis and segment buttons
arrow1 = uicontrol('Parent', GUI.Fig, 'style','pushbutton', 'Units', 'normalized', 'position', [0.725 0.8 0.05 0.05], ...
    'callback', @add_centerlines, 'fontsize', 10, 'fontweight', 'bold');
arrow2 = uicontrol('Parent', GUI.Fig, 'style','pushbutton', 'Units', 'normalized', 'position', [0.725 0.65 0.05 0.05], ...
    'callback', @remove_centerlines, 'fontsize', 10, 'fontweight', 'bold');
set(arrow1, 'CData', arrow)
set(arrow2, 'CData', fliplr(arrow))
uicontrol('Parent', GUI.Fig, 'style','pushbutton', 'Units', 'normalized', 'position', [0.825 0.525 0.15 0.05], ...
    'callback', @merge_centerlines, 'string', 'Merge', 'fontsize', 10, 'fontweight', 'bold');
uicontrol('Parent', GUI.Fig, 'style','pushbutton', 'Units', 'normalized', 'position', [0.525 0.525 0.15 0.05], ...
    'callback', @FMM, 'string', 'FMM', 'fontsize', 10, 'fontweight', 'bold');


uicontrol('Parent', GUI.Fig, 'style','pushbutton', 'Units', 'normalized', 'position', [0.1 0.25 0.15 0.05], ...
    'callback', @load_centerlines,'string', 'Load Centerlines', 'fontsize', 10, 'fontweight', 'bold');
uicontrol('Parent', GUI.Fig, 'style','pushbutton', 'Units', 'normalized', 'position', [0.1 0.175 0.15 0.05], ...
    'callback', @load_myo, 'string', 'Load Myocardium', 'fontsize', 10, 'fontweight', 'bold');
uicontrol('Parent', GUI.Fig, 'style','pushbutton', 'Units', 'normalized', 'position', [0.1 0.1 0.15 0.05], ...
    'callback', @save_and_write, 'string', 'Save', 'fontsize', 10, 'fontweight', 'bold');

% text for the user interface
GUI.display_myo=uicontrol('Parent', GUI.Fig, 'style','checkbox', 'Units', 'normalized', 'position', [0.1 0.325 0.15 0.03], ...
     'callback', @toggle_myo, 'string', 'Display Myocardium', 'fontsize', 10, 'fontweight', 'bold', 'value', 1);

GUI.centerlines = {};
GUI.centerlines_idx1 = [];
GUI.centerlines_idx2 = [];

function load_centerlines(hObj, eventdata)
    [filename, pathname ] = uigetfile('*.vtp');
    interp = 1;
    split = 1;
    [centerline_interp radius_interp] = parse_centerlines(strcat(pathname, filename), interp, split);
    
    current_list = get(GUI.centerline_list, 'string');
    idx = length(current_list);
    for i = 1:length(centerline_interp)
        centerlines_list{i} = sprintf('Centerline %d', idx+i);
    end
    current_list = cat(1, current_list, centerlines_list(:));
    set(GUI.centerline_list, 'string', current_list)
    GUI.centerlines = cat(1, GUI.centerlines, centerline_interp(:));
    GUI.centerlines_idx1 = cat(2, GUI.centerlines_idx1, idx+1:idx+length(centerlines_list));
    display_scene;
end

function centerlineSelected1(hObj, eventdata)
    selected_centerlines = get(GUI.centerline_list, 'Value');
    centerline_idx = GUI.centerlines_idx1(selected_centerlines);
    centerlines = GUI.centerlines(centerline_idx);
    display_scene;
    for i = 1:length(centerlines)
        plot3(centerlines{i}(:, 1), centerlines{i}(:, 2), centerlines{i}(:, 3), 'm', 'linewidth', 6, 'Parent', GUI.Ax1)
    end
end

function centerlineSelected2(hObj, eventdata)
    selected_centerlines = get(GUI.merge_list, 'Value');
    centerline_idx = GUI.centerlines_idx2(selected_centerlines);
    centerlines = GUI.centerlines(centerline_idx);
    display_scene;
    for i = 1:length(centerlines)
        plot3(centerlines{i}(:, 1), centerlines{i}(:, 2), centerlines{i}(:, 3), 'b', 'linewidth', 6, 'Parent', GUI.Ax1)
    end
end


function add_centerlines(hObj, eventdata)
    % moves selected centerlines into second listbox
    all_centerlines  = get(GUI.centerline_list, 'string');
    selected_centerlines = get(GUI.centerline_list, 'Value');
    centerline_idx = GUI.centerlines_idx1(selected_centerlines);
    keep_centerlines = ones(length(all_centerlines), 1);
    keep_centerlines(selected_centerlines) = 0;
    
    centerlines_list2 = all_centerlines(selected_centerlines);
    centerlines_list1 = all_centerlines(find(keep_centerlines));
    
    set(GUI.centerline_list,'Value',1);
    set(GUI.merge_list,'Value',1);
    centerlines_list2 = cat(1, get(GUI.merge_list, 'string'), centerlines_list2);
    set(GUI.centerline_list, 'string', centerlines_list1)
    set(GUI.merge_list, 'string', centerlines_list2)
    GUI.centerlines_idx2 = cat(2, GUI.centerlines_idx2, centerline_idx);
    GUI.centerlines_idx1(selected_centerlines) = [];
    
end

function remove_centerlines(hObj, eventdata)
    % moves selected centerlines back into first listbox
    all_centerlines  = get(GUI.merge_list, 'string');
    selected_centerlines = get(GUI.merge_list, 'Value');
    centerline_idx = GUI.centerlines_idx2(selected_centerlines);
    keep_centerlines = ones(length(all_centerlines), 1);
    keep_centerlines(selected_centerlines) = 0;
    
    centerlines_list1 = all_centerlines(selected_centerlines);
    centerlines_list2 = all_centerlines(find(keep_centerlines));

    set(GUI.centerline_list,'Value',1);
    set(GUI.merge_list,'Value',1);
    centerlines_list1 = cat(1, get(GUI.centerline_list, 'string'), centerlines_list2);
    set(GUI.centerline_list, 'string', centerlines_list1)
    set(GUI.merge_list, 'string', centerlines_list2)
    GUI.centerlines_idx1 = cat(2, GUI.centerlines_idx1, centerline_idx);
    GUI.centerlines_idx2(selected_centerlines) = [];
end

function load_myo(hObj, eventdata)
    % read in myocardium volumeric mesh
    [filename, pathname ] = uigetfile('*.vtu');
    [nodes, faces] = parse_mesh(strcat(pathname, filename));
    GUI.nodes = nodes;
    GUI.faces = faces;
    GUI.volumes_idx = ones(length(faces), 1);
    display_scene();
end

function merge_centerlines(hObj, eventdata)

    all_centerlines = get(GUI.merge_list, 'String');
    selected_centerlines = get(GUI.merge_list, 'Value');
    selected_idx = GUI.centerlines_idx2(selected_centerlines);
    centerlines = GUI.centerlines(selected_idx);
    % remove centerlines
    GUI.centerlines_idx2(selected_centerlines) = [];
%     GUI.centerlines(selected_centerlines) = [];
    % update merge list
    all_centerlines(selected_centerlines) = [];
    set(GUI.centerline_list,'Value',1);
    set(GUI.merge_list,'Value',1);
    set(GUI.merge_list, 'string', all_centerlines);
    title = inputdlg('Enter new centerline name', 'New Centerline');
    GUI.centerlines{end+1} = cell2mat(centerlines);
    centerline_list1 = get(GUI.centerline_list, 'String');
    centerline_list1 = cat(1, centerline_list1, title);
    set(GUI.centerline_list, 'string', centerline_list1);
    GUI.centerlines_idx1(end+1) = length(GUI.centerlines);
end

function toggle_myo(hObj, eventdata)
    display_scene()
end


function display_scene()    
    cla(GUI.Ax1)
    centerlines = cell2mat(GUI.centerlines(:));
    plot3(centerlines(:, 1), centerlines(:, 2), centerlines(:, 3), '.', 'Parent', GUI.Ax1)
    hold(GUI.Ax1, 'on')
    if isfield(GUI, 'nodes')
        if get(GUI.display_myo, 'Value')
           patch('vertices', GUI.nodes, 'faces', GUI.faces, 'CData', GUI.volumes_idx, 'FaceColor', 'flat', 'EdgeColor', 'k', 'Parent', GUI.Ax1)
        end
    end
    axis(GUI.Ax1, 'equal')
end

function source = register(centerlines, nodes)
    % 'project' centerline onto mesh by identifying nearest node
    source = cell(length(centerlines), 1);
    for i = 1:length(centerlines)
        projected_dist = zeros(length(centerlines{i}), length(nodes(:, 1)));
        for j = 1:length(centerlines{i})
            projected_dist(j, :) = sqrt((centerlines{i}(j, 1) - nodes(:, 1)).^2 + ...
                (centerlines{i}(j, 2) - nodes(:, 2)).^2 + ...
                (centerlines{i}(j, 3) - nodes(:, 3)).^2);
        end
        [min_val, idx] = min(projected_dist, [], 2);
    %     centerline_dist{i} = [min_val, idx];
        % collect all centerline info into source points matrix - [LV idx, Vessel idx, point idx]
        source{i} = [idx ones(length(idx), 1)*i min_val];
    end
    source = cell2mat(source);

    % ignore points greater than 10mm from LV surface
    source(source(:, 3) > 10, :) = [];
end        

function FMM(hObj, eventdata)
    
    all_centerlines = 1:length(get(GUI.centerline_list, 'String'));
    selected_idx = GUI.centerlines_idx1(all_centerlines);
    centerlines = GUI.centerlines(selected_idx);
    source = register(centerlines, GUI.nodes);
    
    adjacency = sparse(length(GUI.nodes), length(GUI.nodes));
    dist = sparse(length(GUI.nodes), length(GUI.nodes));
    for i = 1:length(GUI.nodes)
        idx = find(sum(GUI.faces==i, 2));
        idx = unique(GUI.faces(idx, :));
        idx = idx(idx ~= i);
        adjacency(i, idx) = 1;
        distance = sqrt((GUI.nodes(i, 1) - GUI.nodes(idx, 1)).^2 + ...
            (GUI.nodes(i, 2) - GUI.nodes(idx, 2)).^2 + ...
            (GUI.nodes(i, 3) - GUI.nodes(idx, 3)).^2);
        dist(i, idx) = distance;
    end

    % compute shortest path to each point on the surface
    target = 1:length(GUI.nodes);
    [costs,paths] = dijkstra(adjacency,dist,source(:, 1), target,1);
    costs(costs == 0)= Inf;
    [min_idx, idx] = min(costs, [], 1);

    % convert surface idx to associated centerline idx
    LV_nodes_centerline_idx = source(idx, 2);

    % use majority voting to determine face centerline association
    LV_faces_centerline_idx = zeros(length(GUI.faces), 1);
    for i = 1:length(GUI.faces)
        LV_faces_centerline_idx(i) = mode(LV_nodes_centerline_idx(GUI.faces(i, :)));
    end

    % for each cell calculate the volume
    vol = zeros(length(GUI.faces), 1);
    for i = 1:length(GUI.faces)
        a = GUI.nodes(GUI.faces(i, 1), :);
        b = GUI.nodes(GUI.faces(i, 2), :);
        c = GUI.nodes(GUI.faces(i, 3), :);
        d = GUI.nodes(GUI.faces(i, 4), :);
        vol(i) = abs((dot(a - d, cross(b - d, c - d))))/6;
    end
    sprintf('Total volume is %f mm^3', sum(vol))

    GUI.volumes = zeros(length(centerlines), 1);
    for i = 1:length(GUI.volumes)
        GUI.volumes(i) = sum(vol(LV_faces_centerline_idx == i));
    end
    GUI.volumes_idx = LV_faces_centerline_idx;
    display_scene()
    
    % add colorbar to the scene
    colormap(GUI.Ax1, parula(length(GUI.centerline_list.String)))
    cbar = colorbar(GUI.Ax1);
    set(cbar, 'YTickLabel', GUI.centerline_list.String)
    set(cbar, 'YTick', 1:length(GUI.centerline_list.String))
end

function save_and_write(hObj, eventdata)
    fname = inputdlg('Enter Filename', 'Save');
    save(strcat(fname{1}, '.mat'), 'GUI')
    fid = fopen(strcat(fname{1}, '_FMM.txt'), 'w');
    fprintf(fid, 'Vessel\tVolume (mm^3)\n')
    for i = 1:length(GUI.volumes)
        fprintf(fid, '%s\t\t%f\n', GUI.centerline_list.String{i}, GUI.volumes(i))
    end
    fclose(fid);
end
    
end