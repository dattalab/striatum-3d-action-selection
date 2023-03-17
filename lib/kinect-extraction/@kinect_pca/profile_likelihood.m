function LL = profile_likelihood(LATENT)
%
%
%
%
%

LL = nan(length(LATENT) - 1, 1);

for i = 1:length(LATENT) - 1

    pool1 = LATENT(1:i);
    pool2 = LATENT(i + 1:end);
    mu1 = mean(pool1);
    mu2 = mean(pool2);
    sig = std([pool1(:); pool2]);

    p1 = normpdf(pool1, mu1, sig);
    p2 = normpdf(pool2, mu2, sig);

    LL(i) = sum(log(p1 + eps)) + sum(log(p2 + eps));

end
