function print_stats(FILE, P, NAMES, varargin)
%
%
%
%
%

% pretty-prints statistics

opts = struct( ...
    'precision', 10, ...
    'notes', '');

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

if isvector(P)
    P = P(:);
end

if isnumeric(P)
    [nrows, nvals] = size(P);
elseif isstruct(P)
    fields = fieldnames(P);
    tmp = P;
    nrows = length(fields);
    P = cell(size(fields));

    for i = 1:length(fields)
        P{i} = tmp.(fields{i});
        NAMES{i} = fields{i};
    end

    clear tmp;
elseif iscell(P)
    nrows = length(P);
end

if nrows ~= length(NAMES)
    error('P-values and NAMES must be same length');
end

if ~isstring(NAMES) & ~iscell(NAMES)
    error('Names must be cell or string array');
end

fid = fopen(FILE, 'wt');

for i = 1:length(NAMES)
    fprintf(fid, '%s:', NAMES{i});

    if iscell(P)

        for j = 1:length(P{i})
            fprintf(fid, ' %g', P{i}(j));
        end

    else

        for j = 1:nvals
            fprintf(fid, ' %g', P(i, j));
        end

    end

    fprintf(fid, '\n');
end

if ~isempty(opts.notes)
    fprintf(fid, '%s\n', opts.notes);
end

fclose(fid);
