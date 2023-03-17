function DELTAC = compute_deltas(CC, WIN, PAD)
%computes a sliding regression across the rows of matrix CC
%
%	CC
%	matrix
%
%	WIN
%	Window size
%
%	PAD
%	Zero pad to return vector same size as number of frames in
%	CC (default: 1, 2 uses edge padding)
%
% simple function that computes the delta coefficients

% if padding enabled, zero pad to return vector of same size

if nargin < 3 | isempty(PAD), PAD = 1; end
if nargin < 2 | isempty(WIN), WIN = 2; end
if nargin < 1, error('Need CC matrix to continue'); end

if isvector(CC)
    CC = CC(:)';
end

if PAD == 1
    CC = [zeros(size(CC, 1), WIN) CC zeros(size(CC, 1), WIN)];
elseif PAD == 2
    CC = [ones(size(CC, 1), WIN) .* repmat([CC(:, 1)], [1 WIN]) CC ones(size(CC, 1), WIN) .* repmat([CC(:, end)], [1 WIN])];
end

WIN = round(WIN);

[rows, columns] = size(CC);

% lose the edges via the window

DELTAC = zeros(rows, columns - (2 * (WIN + 1)));

for i = WIN + 1:columns - (WIN)

    deltanum = sum(repmat(1:WIN, [rows 1]) .* (CC(:, i + 1:i + WIN) - CC(:, i - WIN:i - 1)), 2);
    deltaden = 2 * sum([1:WIN] .^ 2);

    DELTAC(:, i - (WIN)) = deltanum ./ deltaden;

end
