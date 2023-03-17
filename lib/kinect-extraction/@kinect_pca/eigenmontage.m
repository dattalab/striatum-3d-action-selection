function AX = eigenmontage(OBJ, varargin)
% formats left singular vectors into an image and plots
%
%
%
%
%

normalize = true;
clip = 80;
k = 20;
ncols = nan;

nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'clip'
            clip = varargin{i + 1};
        case 'normalize'
            normalize = varargin{i + 1};
        case 'k'
            k = varargin{i + 1};
        case 'ncols'
            ncols = varargin{i + 1};
        otherwise
    end

end

eigenmice = OBJ.coeffs;
[m, n] = size(eigenmice);
edge = sqrt(m);

% eigenmice=zscore(eigenmice);
% clip=prctile(abs(eigenmice(:)),clip);
% eigenmice(abs(eigenmice)<clip)=0;

% scale

for i = 1:min(k, n)
    eigenmice(:, i) = eigenmice(:, i) ./ (sqrt(OBJ.details.latent(i) + 1e-8));
end

eigenmice = zscore(eigenmice);
min_val = prctile(eigenmice(:), .5);
max_val = prctile(eigenmice(:), 99.5);

eigenmice(eigenmice > max_val) = max_val;
eigenmice(eigenmice < min_val) = min_val;
eigenmice = (eigenmice - min_val) ./ (max_val - min_val);
eigenmice = uint16(eigenmice * 256);
eigenmice = reshape(eigenmice, edge, edge, 1, []);

AX = montage(eigenmice(:, :, 1, 1:min(k, n)), bone(256), 'size', [nan ncols]);
