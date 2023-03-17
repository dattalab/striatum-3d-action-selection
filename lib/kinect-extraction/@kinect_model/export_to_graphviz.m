function export_to_graphviz(TRANS_MAT, varargin)
%
%
%

opts = struct( ...
    'output_file', 'new_graph.dot', ...
    'prune_weights', .1, ...
    'highlight_weights', .2, ...
    'use_weights', true, ...
    'node_color', 'lightblue2', ...
    'rankdir', 'UD', ...
    'width_scale', 40, ...
    'run_dot', false, ...
    'open_pdf', false, ...
    'read_coords', '', ...
    'export_txt', true, ...
    'layout', 'circo', ...
    'node_size', .3, ...
    'arrowhead', 'none', ...
    'arrowtail', 'none', ...
    'print_options', false, ...
    'name', 'kinect_model');

opts_names = fieldnames(opts);
nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    if any(strcmp(varargin{i}, opts_names))
        opts.(varargin{i}) = varargin{i + 1};
    end

end

TRANS_MAT(isnan(TRANS_MAT)) = 0;

dot_id = fopen(opts.output_file, 'wt');

if opts.print_options
    fprintf(dot_id, '# DOT file generated from MATLAB on %s\n', datestr(now));

    for i = 1:length(opts_names)

        if ischar(opts.(opts_names{i}))
            fprintf(dot_id, '# Option %s: %s\n', opts_names{i}, opts.(opts_names{i}));
        else
            fprintf(dot_id, '# Option %s: %g\n', opts_names{i}, opts.(opts_names{i}));
        end

    end

end

fprintf(dot_id, sprintf('digraph %s {\n', opts.name));
fprintf(dot_id, '\tgraph [layout = "%s",spline = "true"]\n', opts.layout);
fprintf(dot_id, '\tnode [color = "%s", style = "filled"]\n', opts.node_color)
fprintf(dot_id, '\tedge [arrowhead="%s",arrowtail="%s"]\n', opts.arrowhead, opts.arrowtail);
fprintf(dot_id, '\trankdir="%s";\n\tsize="7.75,10.25"\n', opts.rankdir); % changed rankdir from LR to UD

for i = 1:size(TRANS_MAT, 1)

    for j = 1:size(TRANS_MAT, 2)

        cur_edge = TRANS_MAT(i, j);

        if cur_edge < opts.prune_weights | isnan(cur_edge)
            continue;
        end

        if cur_edge < opts.highlight_weights
            fprintf(dot_id, '\t%i -> %i\t[penwidth = "%g",weight = "%g",color = "gray60"]', i, j, cur_edge, cur_edge);
        else
            fprintf(dot_id, '\t%i -> %i\t[penwidth = "%g",weight = "%g",color = "black"]', i, j, cur_edge * opts.width_scale, cur_edge);
        end

        fprintf(dot_id, '\n');

    end

end

if ~isempty(opts.read_coords) & exist(opts.read_coords, 'file')
    fprintf('Reading coordinates from %s\n', opts.read_coords);
    fid = fopen(opts.read_coords, 'rt');
    readdata = textscan(fid, '%s%[^\n]', 'commentstyle', '#', 'delimiter', ' ');
    tmp = readdata{2}(contains(readdata{1}, 'node'));

    % get x and y from data

    node_pos = zeros(numel(tmp), 2);

    for i = 1:length(tmp)
        splits = regexp(tmp{i}, ' ', 'split');
        node_idx = str2num(splits{1});
        node_x = str2num(splits{2});
        node_y = str2num(splits{3});
        node_pos(node_idx, :) = [node_x node_y];
    end

else
    node_pos = [];
end

if length(opts.node_size) == 1
    opts.node_size = repmat(opts.node_size, size(TRANS_MAT, 1));
end

for i = 1:size(TRANS_MAT, 1)

    if ~isempty(node_pos)
        fprintf(dot_id, ...
            '\t%i [fontsize="12",ranksep="2",nodesep="20",fixedsize="true",width="%g",height="%g",pos="%g,%g!"]\n', ...
            i, opts.node_size(i), opts.node_size(i), node_pos(i, 1), node_pos(i, 2));
    else
        fprintf(dot_id, '\t%i [fontsize="12",ranksep="2",nodesep="20",fixedsize="true",width="%g",height="%g"]\n', ...
            i, opts.node_size(i), opts.node_size(i));
    end

end

fprintf(dot_id, '}');
fclose(dot_id);

if opts.run_dot & isunix

    if ismac
        bash_path = getenv('PATH');
        setenv('PATH', [bash_path ':/usr/local/bin']);
    end

    [exit_code, msg] = system('type neato');

    if exit_code == 0
        is_dot = true;
        fprintf('Found neato, will create pdf...\n');
    else
        fprintf('Could not find dot in your path\n');
        return;
    end

    [pathname, filename, ext] = fileparts(opts.output_file);
    dot_output = sprintf('%s.pdf', fullfile(pathname, filename));
    txt_output = sprintf('%s.txt', fullfile(pathname, filename));
    dot_output2 = sprintf('%s.png', fullfile(pathname, filename));
    layout_output = sprintf('%s.dot', fullfile(pathname, filename));

    if opts.export_txt
        cmd = sprintf('neato "%s" -Tplain -o "%s" -Tpdf -o "%s"', opts.output_file, txt_output, dot_output);
        cmd2 = sprintf('neato "%s" -Tpng -o "%s"', opts.output_file, dot_output2);
    elseif ~isempty(node_pos)
        cmd = sprintf('neato -n "%s" -Tpdf -o "%s"', opts.output_file, dot_output);
        cmd2 = sprintf('neato "%s" -Tpng -o "%s"', opts.output_file, dot_output2);
    else
        cmd = sprintf('neato "%s" -Tpdf -o "%s"', opts.output_file, dot_output);
        cmd2 = sprintf('neato "%s" -Tpng -o "%s"', opts.output_file, dot_output2);
    end

    [exit_code, msg] = unix(cmd);
    [exit_code2, msg2] = unix(cmd2);

    unix(sprintf('dot "%s" > "%s"', opts.output_file, layout_output));

    if exit_code == 0
        fprintf('Dot run succesful, opening pdf...\n');

        if opts.open_pdf
            system(sprintf('open "%s"', dot_output));
        end

    else
        msg
    end

end
