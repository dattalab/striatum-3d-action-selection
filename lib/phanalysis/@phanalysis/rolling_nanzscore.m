function DATA = rolling_nanzscore(DATA, WIN, PADDING)
%
%
%
%
%

for i = 1:size(DATA, 2)
    use_data = DATA(:, i);
    use_data = use_data(:)';
    pad = nan(1, WIN - 1);
    use_data = [pad use_data];

    tmp = im2col(use_data, [1 WIN], 'sliding');
    mu = nanmean(tmp);
    sig = nanstd(tmp);
    use_data = (use_data(WIN:end) - mu) ./ sig;
    DATA(:, i) = use_data;
end
