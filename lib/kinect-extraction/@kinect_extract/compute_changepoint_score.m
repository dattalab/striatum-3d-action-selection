function compute_changepoint_score(OBJ)
%
%
%
%

upd = kinect_extract.proc_timer(OBJ.get_frame_total);
counter = 0;

for i = 1:length(OBJ)

    if ~OBJ(i).status.projection_rp
        fprintf('Need to compute RPs first...\n');
        continue;
    end

    opts = OBJ(i).options.changepoints;
    % get delta coefficients, thresh abs value, sum then smooth
    deltac = kinect_extract.delta_coefficients(OBJ(i).projections.rp', opts.win);
    bin_score = abs(deltac) > opts.thresh;
    kernel = normpdf([round(-opts.smooth_sig * 6):round(opts.smooth_sig * 6)], 0, opts.smooth_sig);
    smooth_score = conv(mean(bin_score), kernel, 'same');
    OBJ(i).projections.changepoint_score = smooth_score(:);
    counter = counter + OBJ(i).metadata.nframes;
    upd(counter);

end
