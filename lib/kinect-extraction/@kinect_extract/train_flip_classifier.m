function train_flip_classifier(OBJ)
%train_flip_classifier- Trains a random forest to classify flips from corrected data
%the flip classifier is then saved to _analysis/flip_detector.mat
%
% Usage: obj.train_flip_classifier
%
% note that a single object or object array can be used here, frames will be chosen at random from all objects.
%
% Inputs:
%   None
%
% Options (obj.options.flip):
%   max_frames (int): maximum number of frames to include for training (default: 1e5)
%   training_fraction (float, 0-1): fraction of frames to use for train split (test on 1-training_fraction) (default: .75)
%
% Example:
%   obj.train_flip_classifier;
%

if
    ~exist(OBJ(1).options.common.analysis_dir, 'dir')
    mkdir(OBJ(1).options.common.analysis_dir);
end

CATDATA = OBJ.load_oriented_frames_cat('max_frames', OBJ(1).options.flip.max_frames, ...
    'raw', false, 'use_transform', false, 'missing_value', 0);
[data labels names model_names] = ...
    OBJ.prepare_data_for_flip_classifier(CATDATA, OBJ(1).options.flip.training_fraction);

fprintf('Training random forest with %g of the data\n', OBJ(1).options.flip.training_fraction);
rnd_forest = TreeBagger(100, single(cat(1, data.train{:})), labels.train);

% compactify, don't want to save the forest along with the training data!

% use this to get a rough left-out error rate
fprintf('Computing error rate\n');

rnd_forest = compact(rnd_forest);
[test_prediction, test_proba] = predict(rnd_forest, single(cat(1, data.test{:})));

% now train on everything

test_prediction = str2num(cat(1, test_prediction{:}));
test_labels = labels.test;
err_rate = sum(test_prediction ~= test_labels) / numel(test_labels);
fprintf('Error rate on test data: %g percent\n', err_rate * 1e2);

fprintf('Training random forest on all data\n');
rnd_forest = TreeBagger(100, single([cat(1, data.train{:}); cat(1, data.test{:})]), ...
    [labels.train; labels.test]);
rnd_forest = compact(rnd_forest);

for i = 1:length(OBJ)
    OBJ(i).flip_model = rnd_forest;
end

rnd_forest_id = char(java.util.UUID.randomUUID);

fprintf('Saving random forest\n');
save(fullfile(OBJ(1).options.common.analysis_dir, 'flip_detector.mat'), ...
    'test_prediction', 'test_proba', 'rnd_forest', 'rnd_forest_id', ...
    'model_names', 'test_labels', '-v7.3');
