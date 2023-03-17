function decode_photometry(TRAIN_X,TRAIN_Y,TEST_X,TEST_Y,varargin)
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
  'nboots',0,...
  'boot_size',0,...
	'prior','uniform',...
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
classes=unique(TRAIN_Y);
nclasses=length(classes);

fprintf('Training model...');
if opts.nboots>0

  upd=kinect_extract.proc_timer(opts.nboots);

  prediction=nan(test_sz,opts.nboots);
  prediction_probas=nan(test_sz,nclasses,opts.nboots);
  tmp_performance=nan(1,opts.nboots);

  for i=1:nboots

    rand_pool=randperm(ndims);
    rand_sel=rand_pool(1:opts.boot_size);

    mdl=TreeBagger(opts.ntrees,TRAIN_X(:,rand_sel),TRAIN_Y,'prior',opts.prior,...
    	'minleafsize',opts.min_leaf_size,'maxnumsplits',opts.max_num_splits);
    [tmp,prediction_probas(:,:,i)]=mdl.predict(TEST_X(:,rand_sel));
    prediction(:,i)=str2double(tmp);
    tmp_performance(i)=mean(TEST_Y(:)==prediction(:,i));
    upd(i);

  end

  fprintf('done. average \n%g %% correct\n',mean(tmp_performance)*1e2);

else

  mdl=TreeBagger(opts.ntrees,TRAIN_X,TRAIN_Y,'prior',opts.prior,...
  	'minleafsize',opts.min_leaf_size,'maxnumsplits',opts.max_num_splits);

  fprintf('done.\nPredicting test data...');

  [prediction,prediction_probas]=mdl.predict(TEST_X);
  prediction=str2double(prediction);
  tmp_performance=mean(TEST_Y(:)==prediction(:));
end

fprintf('done.\n%g %% correct\n',tmp_performance*1e2);

% randomly permute the rows of our test data (id shuffle)

rand_prediction=nan(test_sz,opts.nrands);
rand_prediction_probas=nan(test_sz,size(prediction_probas,2),opts.nrands);
tmp_performance_rnd=nan(1,opts.nrands);

if opts.nrands>0
	fprintf('Computing shuffles...');
end

for i=1:opts.nrands
	 [tmp,rand_prediction_probas(:,:,i)]=mdl.predict(TEST_X(randperm(test_sz),:));
	 rand_prediction(:,i)=str2double(tmp);
	 tmp_performance_rnd(i)=mean(TEST_Y(:)==rand_prediction(:,i));
end

if opts.nrands>0
	fprintf('done\naverage shuffle performance %g %%\n',mean(tmp_performance_rnd)*1e2);
end

fprintf('Saving data at %s',opts.save_location);

obs_classes=TEST_Y;
metadata=opts.metadata;

save(opts.save_location,'prediction','rand_prediction','obs_classes','metadata','prediction_probas','rand_prediction_probas');
