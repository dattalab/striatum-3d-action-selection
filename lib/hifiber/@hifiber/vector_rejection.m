function [PROJ, RESIDUALS, RESCALED] = vector_rejection(SIG, REFERENCE)

use_samples = ~(SIG < 0 | REFERENCE < 0);
use_samples = ~(isnan(SIG) | isnan(REFERENCE)) & use_samples;

num = SIG(use_samples)' * REFERENCE(use_samples);
den = REFERENCE(use_samples)' * REFERENCE(use_samples);

PROJ = num / den;

RESCALED = REFERENCE * PROJ;
RESIDUALS = nansum((SIG - RESCALED) .^ 2);
