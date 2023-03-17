function d1d2_decode_batch_regress(TRAIN_X,TRAIN_Y,TEST_X,TEST_Y,varargin)
%
%
%
%

assert(size(TRAIN_X,2)==size(TEST_X,2),'nfeatures in the training and test sets are inconsistent')
assert(size(TRAIN_X,1)==size(TRAIN_Y,1),'nsamples in the training set is inconsistent');
assert(size(TEST_X,1)==size(TEST_Y,1),'nsamples in the test set is inconsistent');

opts=struct(...
	'save_location','decoder_performance.mat',...
	'nrands',0,...
	'ntrees',200,...
	'min_leaf_size',20,...
	'max_num_splits',100,...
	'metadata',struct());

opts_names=fieldnames(opts);
nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
  if any(strcmp(varargin{i},opts_names))
    opts.(varargin{i})=varargin{i+1};
  end
end

[test_sz,ndims]=size(TEST_X);
train_sz=size(TRAIN_X,1);

fprintf('Training model...');

mdl=TreeBagger(opts.ntrees,TRAIN_X,TRAIN_Y,...
	'minleafsize',opts.min_leaf_size,'maxnumsplits',opts.max_num_splits,'Method','regression');

fprintf('done.\nPredicting test data...');

prediction=mdl.predict(TEST_X);
tmp_performance=mean((TEST_Y(:)-prediction(:)).^2);

fprintf('done.\nmse %g\n',tmp_performance);

% randomly permute the rows of our test data (id shuffle)

rand_prediction=nan(test_sz,opts.nrands);
tmp_performance_rnd=nan(1,opts.nrands);

if opts.nrands>0
	fprintf('Computing shuffles...');
end

for i=1:opts.nrands
	 rand_prediction(:,i)=mdl.predict(TEST_X(randperm(test_sz),:));
	 tmp_performance_rnd(i)=mean((TEST_Y(:)-rand_prediction(:,i)).^2);
end

if opts.nrands>0
	fprintf('done\naverage shuffle mse %g\n',mean(tmp_performance_rnd));
end

fprintf('Saving data at %s',opts.save_location);

obs_classes=TEST_Y;
metadata=opts.metadata;

save(opts.save_location,'prediction','rand_prediction','obs_classes','metadata');
