function compute_intrabehavior_distance(OBJ)
% this is currently non-functional, requires some fixes to work again...
%
%
%

cut = OBJ.options.syllable_cutoff;
chk_scalars = {'width', 'length', 'height_ave', 'velocity_mag'};

OBJ.distance.intra = struct();
OBJ.distance.intra.scalars = zeros(length(OBJ.behavior), length(OBJ.behavior), cut);

nfeatures = length(chk_scalars);

sliced_scalars = OBJ.slice_syllables_scalars(chk_scalars, 1:cut);
upd = kinect_extract.proc_timer(cut);

for i = 1:cut

    for j = 1:length(OBJ.behavior)

        % get the feature vector for object j
        idx1 = sliced_scalars(i).obj_idx == j;
        nsamples1 = sum(idx1);
        features1 = zeros(nsamples1, nfeatures);

        for k = 1:nfeatures
            features1(:, k) = sliced_scalars(i).(chk_scalars{k})(idx1);
        end

        for k = 1:length(OBJ.behavior)

            idx2 = OBJ.stats.model_scalars(i).obj_idx == k;
            nsamples2 = sum(idx2);
            features2 = zeros(nsamples2, nfeatures);

            for l = 1:nfeatures
                features2(:, l) = sliced_scalars(i).(chk_scalars{l})(idx2);
            end

            tmp = pdist2(features1, features2);
            OBJ.distance.intra.scalars(j, k, i) = nanmedian(tmp(:));

        end

    end

    upd(i);
end
