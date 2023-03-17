function load_track_stats(OBJ, FORCE)
%
%
%
%

if nargin < 2 | isempty(FORCE)
    FORCE = false;
end

upd = kinect_extract.proc_timer(length(OBJ));

for i = 1:length(OBJ)

    if ~OBJ(i).status.track_stats
        fprintf('Track stats not complete, unable to load.\n');
        continue;
    end

    if ~isempty(OBJ(i).tracking) & ~FORCE
        %fprintf('Track stats already loaded');
        continue;
    end

    if OBJ(i).files.track_stats{2}
        load(OBJ(i).files.track_stats{1}, 'depth_stats_fixed');
        OBJ(i).tracking.centroid = cat(1, depth_stats_fixed(:).Centroid);

        if isfield(depth_stats_fixed(1), 'CorrectedOrientation')
            OBJ(i).tracking.orientation = cat(1, depth_stats_fixed(:).CorrectedOrientation);
        else
            OBJ(i).tracking.orientation = cat(1, depth_stats_fixed(:).Orientation);
        end

    end

    upd(i);
end
