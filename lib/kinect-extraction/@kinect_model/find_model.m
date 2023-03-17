function [IDX, MAT] = find_model(METADATA, varargin)
% Rifles through the metadata and find the model of your choice!
%
%
%
%

opts = struct( ...
    'kappa', [], ...
    'gamma', [], ...
    'nu', []);

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

keywords = fields(opts);
to_del = false(size(keywords));

for i = 1:length(keywords)
    to_del(i) = isempty(opts.(keywords{i}));
end

keywords(to_del) = [];
MAT = false(length(keywords), length(METADATA.parameters));

if ~isempty(keywords)

    for i = 1:length(keywords)
        %values=cellfun(@(x) x.(keywords{i}),METADATA.scan_dicts);
        dist = abs(METADATA.parameters.(keywords{i}) - opts.(keywords{i}));
        [val, loc] = min(dist);
        loc = dist == val;
        MAT(i, loc) = true;
    end

end

IDX = find(all(MAT));
