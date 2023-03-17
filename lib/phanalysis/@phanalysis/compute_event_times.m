function compute_event_times(OBJ)
%
%
%
%
%

OBJ.stats.event_times = struct();
upd = kinect_extract.proc_timer(length(OBJ.photometry));
nanzscore = @(x) (x - nanmean(x)) ./ nanstd(x);
gcamp_counter = 1;
rcamp_counter = 1;

for i = 1:length(OBJ.photometry)

    if OBJ.session(i).has_photometry & OBJ.session(i).use_gcamp

        norm_gcamp = OBJ.normalize_trace(OBJ.photometry(i).traces(1).dff);
        norm_gcamp_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(1).dff, true);
        [~, gcamp_times] = findpeaks(nanzscore(norm_gcamp), 'minpeakheight', .5, 'minpeakdistance', 3);
        [~, gcamp_times_dt] = findpeaks(nanzscore(norm_gcamp_dt), 'minpeakheight', .5, 'minpeakdistance', 3);

        OBJ.stats.event_times.gcamp(gcamp_counter).raw = gcamp_times;
        OBJ.stats.event_times.gcamp(gcamp_counter).dt = gcamp_times_dt;

        gcamp_counter = gcamp_counter + 1;

    end

    if OBJ.session(i).has_photometry & OBJ.session(i).use_rcamp

        norm_rcamp = OBJ.normalize_trace(OBJ.photometry(i).traces(4).dff);
        norm_rcamp_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(4).dff, true);
        [~, rcamp_times] = findpeaks(nanzscore(norm_rcamp), 'minpeakheight', .5, 'minpeakdistance', 3);
        [~, rcamp_times_dt] = findpeaks(nanzscore(norm_rcamp_dt), 'minpeakheight', .5, 'minpeakdistance', 3);

        OBJ.stats.event_times.rcamp(rcamp_counter).raw = rcamp_times;
        OBJ.stats.event_times.rcamp(rcamp_counter).dt = rcamp_times_dt;

        rcamp_counter = rcamp_counter + 1;

    end

    upd(i)

end
