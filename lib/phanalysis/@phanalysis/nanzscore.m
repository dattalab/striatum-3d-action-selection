function DATA = nanzscore(DATA, MOD)
%
%

if nargin < 2
    MOD = false;
end

if ~MOD
    mu = nanmean(DATA);
    sigma = nanstd(DATA);
    sigma(sigma == 0) = 1;
    DATA = bsxfun(@minus, DATA, mu);
    DATA = bsxfun(@rdivide, DATA, sigma);
else
    mads = mad(DATA, 1);
    zs = mads <= eps;
    DATA = bsxfun(@minus, DATA, nanmedian(DATA));

    if isvector(DATA)
        DATA = DATA(:);
        DATA = DATA - nanmedian(DATA);

        if mads <= eps
            DATA = DATA ./ (1.253314 * mad(DATA, 0));
        else
            DATA = DATA ./ (1.4286 * mads);
        end

    else
        DATA(:, ~zs) = bsxfun(@rdivide, DATA(:, ~zs), 1.4286 * mads(~zs));
        DATA(:, zs) = bsxfun(@rdivide, DATA(:, zs), 1.253314 * mad(DATA(:, zs), 0));
    end

end
