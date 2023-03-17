function compute_usage_distance(OBJ)
%
%
%
%

cut = OBJ.options.syllable_cutoff;
OBJ.distance.pr = struct();
OBJ.distance.pr.jsd.zero = zeros(length(OBJ.behavior), length(OBJ.behavior));
OBJ.distance.pr.jsd.first = zeros(length(OBJ.behavior), length(OBJ.behavior));
trans_to_p = @(x) bsxfun(@rdivide, single(x), sum(single(x), 2));
trans_to_p_bigram = @(x) single(x) ./ sum(single(x(:)));

upd = kinect_extract.proc_timer(length(OBJ.behavior));

for i = 1:length(OBJ.behavior)
    p1 = trans_to_p_bigram(OBJ.behavior(i).transition_matrix(1:cut, 1:cut));

    for j = 1:length(OBJ.behavior)
        p2 = trans_to_p_bigram(OBJ.behavior(j).transition_matrix(1:cut, 1:cut));
        m = (p1 + p2) * .5;
        kl1 = nansum(p1(:) .* log((p1(:) ./ m(:))));
        kl2 = nansum(p2(:) .* log((p2(:) ./ m(:))));
        OBJ.distance.pr.jsd.first(i, j) = (kl1 + kl2) * .5;
    end

    upd(i);
end

upd(inf);
upd = kinect_extract.proc_timer(length(OBJ.behavior));

for i = 1:length(OBJ.behavior)
    %tmp=OBJ.behavior(i).get_syllable_usage;
    tmp = sum(OBJ.behavior(i).transition_matrix);
    p1 = tmp(1:cut) ./ sum(tmp(1:cut));

    for j = 1:length(OBJ.behavior)
        %tmp=OBJ.behavior(j).get_syllable_usage;
        tmp = sum(OBJ.behavior(j).transition_matrix);
        p2 = tmp(1:cut) ./ sum(tmp(1:cut));
        m = (p1 + p2) * .5;
        kl1 = nansum(p1(:) .* log((p1(:) ./ m(:))));
        kl2 = nansum(p2(:) .* log((p2(:) ./ m(:))));
        OBJ.distance.pr.jsd.zero(i, j) = (kl1 + kl2) * .5;
    end

    upd(i);
end

upd(inf);
