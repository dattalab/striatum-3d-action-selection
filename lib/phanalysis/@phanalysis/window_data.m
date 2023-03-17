function [WINS WIN_T] = window_data(DATA, LOCS, WIN_SIZE)
%
%
%

if nargin < 3 | isempty(WIN_SIZE)
    WIN_SIZE = 50;
end

assert(isvector(LOCS), 'LOCS must be a vector of indices');
assert(ndims(DATA) < 3, 'DATA can only be a matrix or a vector')

if isvector(DATA)
    DATA = DATA(:);
end

[r, c] = size(DATA);

WIN_T = -WIN_SIZE:WIN_SIZE;
win_len = length(WIN_T);

% clear out windows on the edges

% LOCS((LOCS-WIN_SIZE)<=0)=[];
% LOCS((LOCS+WIN_SIZE)>r)=[];

% pad with nans, shift locations

pad = nan(WIN_SIZE, size(DATA, 2));
DATA = [pad; DATA; pad];
LOCS = LOCS + WIN_SIZE;

locs = num2cell(LOCS(:));
nlocs = length(locs);
locs = cellfun(@(x) (x - WIN_SIZE):(x + WIN_SIZE), locs, 'UniformOutput', false);

% cat the cell array, so now we have a vector of our window indices

locs = cat(2, locs{:})';
WINS = DATA(locs, :);

if isvector(DATA)
    WINS = reshape(WINS, [win_len nlocs]);
else
    WINS = reshape(WINS, [win_len nlocs c]);

    % permute dims so we have time x dims x trials

    WINS = permute(WINS, [1 3 2]);
end