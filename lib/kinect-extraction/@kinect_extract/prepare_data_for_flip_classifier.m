function [DATA LABELS NAMES MODEL_NAMES] = prepare_data_for_flip_classifier(CATDATA, TRAINING_FRACTION)
% Takes concatenated frames and formats for training a TreeBagger
%
%
%%% flip fixing test

% compare various classifiers in a simple TASK

% in current folder, list all .mat files and concatenate

% recall nframes won't scale nicely...2.5e5 is roughly 50 GB of RAM
% since we need to convert features to singles

edge_size = size(CATDATA, 1);
nframes = size(CATDATA, 3);
all_idx = 1:nframes;

train_idx = randsample(all_idx, round(TRAINING_FRACTION * nframes), false);
test_idx = all_idx(setdiff(all_idx, train_idx));

train_data = CATDATA(:, :, train_idx);
test_data = CATDATA(:, :, test_idx);

nframes_train = numel(train_idx);
nframes_test = numel(test_idx);

DATA.train{1} = reshape(train_data, edge_size ^ 2, [])';
DATA.train{2} = reshape(flipud(train_data), edge_size ^ 2, [])';
DATA.train{3} = reshape(fliplr(train_data), edge_size ^ 2, [])';
DATA.train{4} = reshape(fliplr(flipud(train_data)), edge_size ^ 2, [])';

clear train_data;

DATA.test{1} = reshape(test_data, edge_size ^ 2, [])';
DATA.test{2} = reshape(flipud(test_data), edge_size ^ 2, [])';
DATA.test{3} = reshape(fliplr(test_data), edge_size ^ 2, [])';
DATA.test{4} = reshape(flipud(fliplr(test_data)), edge_size ^ 2, [])';

clear test_data;

NAMES{1} = 'raw';
NAMES{2} = 'yflip';
NAMES{3} = 'xflip';
NAMES{4} = 'xyflip';

MODEL_NAMES{1} = {'1', 'not flipped'};
MODEL_NAMES{2} = {'0', 'flipped'};

% uniformly sample fraction across all frames

LABELS.train = [ones(nframes_train * 2, 1); zeros(nframes_train * 2, 1)];
LABELS.test = [ones(nframes_test * 2, 1); zeros(nframes_test * 2, 1)];
