function CLUSTERS = cluster_behavior(OBJ, varargin)
%
%
%
%
%

opts = struct( ...
    'cutoff', 1.135, ...
    'nbehaviors', 40, ...
    'distance', 'kl', ...
    'linkage', 'average');

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

z = linkage(squareform(OBJ.distance.inter.(opts.use_distance)(1:opts.nbehaviors, 1:opts.nbehaviors), 'tovector'), opts.linkage);
CLUSTERS = cluster(z, 'cutoff', 1.135);
