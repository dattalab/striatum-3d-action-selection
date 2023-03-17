function [CLASS, DISTANCE] = predict(OBJ, DATA)
%
%
%
%

if nargin < 2
    error('Need data to predict!')
end

[ndims, nsamples] = size(DATA);

if ndims ~= OBJ.ndims
    error('Data dimensionality %i does not match model dimensionality %i', ndims, OBJ.ndims);
end

warning('off', 'stats:pdist2:ConstantPoints');
DATA = cast(DATA, 'like', OBJ.templates);
DISTANCE = pdist2(OBJ.templates', DATA', OBJ.options.distance);
[~, CLASS] = min(DISTANCE);
warning('on', 'stats:pdist2:ConstantPoints');
