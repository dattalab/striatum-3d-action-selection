function [MU, SIG, LL] = kinect_em_estep(DATA, MU, SIG, varargin)
%
%
%
%
%

maxiter = 50;
epsilon = 1e-3;
diag_covar = false;
lambda = 4;

nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'maxiter'
            maxiter = varargin{i + 1};
        case 'epsilon'
            epsilon = varargin{i + 1};
        case 'diag_covar'
            diag_covar = varargin{i + 1};
        case 'lambda'
            lambda = varargin{i + 1};
        otherwise
    end

end

prev_likelihood = 1e-100;
LL = prev_likelihood;

[ndatapoints, ndims] = size(DATA);
SIG = cov_fix(SIG);

for i = 1:maxiter

    pxtheta = mvnpdf(DATA, MU, SIG);
    pxtheta = pxtheta ./ sum(pxtheta);

    MU = sum(DATA .* repmat(pxtheta, [1 3]));
    dx = (DATA - repmat(MU, [ndatapoints 1]))';
    SIG = (dx .* repmat(pxtheta, [1 3])') * dx' + lambda * eye(size(SIG));

    if diag_covar
        SIG = SIG .* eye(size(SIG));
    end

    SIG = cov_fix(SIG);

    LL = sum(log(pxtheta + 1e-300));
    deltalikelihood = (LL - prev_likelihood);

    if deltalikelihood >= 0 && deltalikelihood < epsilon * abs(prev_likelihood)
        break;
    end

    prev_likelihood = LL;

end
