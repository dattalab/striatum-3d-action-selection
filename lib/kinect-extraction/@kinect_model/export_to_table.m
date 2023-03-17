function export_to_table(TRANS_MAT, varargin)
%
%
%

opts = struct('output_file', 'new_graph.txt', ...
    'prune_weights', 0, ...
    'degree_threshold', [], ...
    'print_options', false, ...
    'autoload', true, ...
    'name', 'kinect_model', ...
    'edge_features', [], ...
    'force_edges', []);

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

sif_id = fopen(opts.output_file, 'wt');

% loop through the adjacency matrix, prune low p edges and get on with it
fprintf(sif_id, 'source\ttarget\tinteraction\tweight');

for i = 1:2:length(opts.edge_features)
    fprintf(sif_id, '\t%s', opts.edge_features{i});
end

fprintf(sif_id, '\n');

for i = 1:size(TRANS_MAT, 1)

    %fprintf(sif_id,'%i\t%i\t%s\t%g\n',i,i,'interaction',0);

    for j = 1:size(TRANS_MAT, 2)

        cur_edge = TRANS_MAT(i, j);
        skip_edge = false;

        if (abs(cur_edge) <= opts.prune_weights | isnan(cur_edge))
            skip_edge = true;
        end

        if ~isempty(opts.force_edges) & opts.force_edges(i, j)
            skip_edge = false;
        end

        if skip_edge | i == j
            continue;
        end

        fprintf(sif_id, '%i\t%i\t%s\t%g', i, j, 'interaction', cur_edge);

        for k = 2:2:length(opts.edge_features)
            fprintf(sif_id, '\t%g', opts.edge_features{k}(i, j));
        end

        fprintf(sif_id, '\n');

    end

end

fclose(sif_id);

% write a quick node attribute file...

[path, file, ext] = fileparts(opts.output_file);

node_id = fopen(fullfile(path, [file '_node.txt']), 'wt');

% weighted in/out degree and unweighted

fprintf(node_id, 'name\tshared name\tdegree\twdegree\n');

deg = sum(TRANS_MAT > opts.degree_threshold);
deg2 = sum(TRANS_MAT > opts.degree_threshold, 2);
degree = deg(:) + deg2(:);

wdeg = sum(TRANS_MAT);
wdeg2 = sum(TRANS_MAT, 2);
wdegree = wdeg(:) + wdeg2(:);

for i = 1:size(TRANS_MAT, 1)
    fprintf(node_id, '%i\t%i\t%g\t%g\n', i, i, degree(i), wdegree(i));
end

fclose(node_id);
