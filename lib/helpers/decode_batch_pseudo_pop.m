function d1d2_decode_batch_pseudo_pop(X,Y,IDS,varargin)
%
%
%
%

assert(size(X,1)==size(Y,1),'nobservations must match in X and Y');

opts=struct(...
  'save_location','decoder_performance.mat',...
  'nrands',0,...
  'ntrees',2000,...
  'min_leaf_size',1,...
  'max_num_splits',100,...
  'cvobj',[],...
  'nfolds',5,...
  'nboots',1,...
  'ncells',100,...
  'prior','uniform',...
  'rnd_stream',[],...
  'rnd_substream',[],...
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


fprintf('Will use %i cv-folds\n',opts.nfolds);
fprintf('Will use %i bootstraps\n',opts.nboots);
fprintf('Will use %i cells\n',opts.ncells);
fprintf('RForest parameters: %i trees\n',opts.ntrees);



model_perf=struct();
model_prediction=struct();

model_prediction_d1=cell(opts.nboots,opts.nfolds);
model_prediction_d2=cell(opts.nboots,opts.nfolds);
model_prediction_both=cell(opts.nboots,opts.nfolds);
model_obs_classes=cell(opts.nboots,opts.nfolds);
model_perf_d1=nan(opts.nboots,opts.nfolds);
model_perf_d2=nan(opts.nboots,opts.nfolds);
model_perf_both=nan(opts.nboots,opts.nfolds);

counter=1;
use_cells=floor(opts.ncells/2);
has_stream=false;

if isa(opts.cvobj,'cvpartition')
  fprintf('Will use user supplied cvpartition object...\n');
  cvobj=opts.cvobj;
  opts.nfolds=cvobj.NumTestSets;
else
  cvobj=cvpartition(Y,'kfold',opts.nfolds);
end

if ~isempty(opts.rnd_stream) & ~isempty(opts.rnd_substream)
  fprintf('Setting random substream to %i\n',opts.rnd_substream);
  set(opts.rnd_stream,'Substream',opts.rnd_substream);
  has_stream=true;
end

upd=kinect_extract.proc_timer(opts.nboots*opts.nfolds);

for i=1:opts.nboots

  if has_stream
    use_d1s=randsample(opts.rnd_stream,find(strcmp(IDS,'d1cre')),use_cells*2,false);
    use_d2s=randsample(opts.rnd_stream,find(strcmp(IDS,'a2acre')),use_cells*2,false);

    %use_pop=[use_d1s(1:end/2) use_d2s(1:end/2)];
    use_pop=[randsample(opts.rnd_stream,find(strcmp(IDS,'d1cre')),use_cells,false) ...
      randsample(opts.rnd_stream,find(strcmp(IDS,'a2acre')),use_cells,false)];
  else
    use_d1s=randsample(find(strcmp(IDS,'d1cre')),use_cells*2,false);
    use_d2s=randsample(find(strcmp(IDS,'a2acre')),use_cells*2,false);

    %use_pop=[use_d1s(1:end/2) use_d2s(1:end/2)];
    use_pop=[randsample(find(strcmp(IDS,'d1cre')),use_cells,false) ...
      randsample(find(strcmp(IDS,'a2acre')),use_cells,false)];
  end

  tmp_prediction_d1=cell(1,opts.nfolds);
  tmp_prediction_d2=cell(1,opts.nfolds);
  tmp_prediction_both=cell(1,opts.nfolds);
  tmp_obs_classes=cell(1,opts.nfolds);

  tmp_perf_d1=nan(1,opts.nfolds);
  tmp_perf_d2=nan(1,opts.nfolds);
  tmp_perf_both=nan(1,opts.nfolds);



  for j=1:opts.nfolds

    tmp_obs_classes{j}=Y(cvobj.test(j));

    mdl=TreeBagger(opts.ntrees,X(cvobj.training(j),use_pop),Y(cvobj.training(j)),...
      'prior',opts.prior,'minleafsize',opts.min_leaf_size,'maxnumsplits',opts.max_num_splits);
    tmp=predict(mdl,X(cvobj.test(j),use_pop));
    tmp=str2double(tmp);
    tmp_prediction_both{j}=tmp;
    tmp_perf_both(j)=mean(tmp==Y(cvobj.test(j)));

    mdl=TreeBagger(opts.ntrees,X(cvobj.training(j),use_d1s),Y(cvobj.training(j)),...
      'prior',opts.prior,'minleafsize',opts.min_leaf_size,'maxnumsplits',opts.max_num_splits);
    tmp=predict(mdl,X(cvobj.test(j),use_d1s));
    tmp=str2double(tmp);
    tmp_prediction_d1{j}=tmp;
    tmp_perf_d1(j)=mean(tmp==Y(cvobj.test(j)));

    mdl=TreeBagger(opts.ntrees,X(cvobj.training(j),use_d2s),Y(cvobj.training(j)),...
      'prior',opts.prior,'minleafsize',opts.min_leaf_size,'maxnumsplits',opts.max_num_splits);
    tmp=predict(mdl,X(cvobj.test(j),use_d2s));
    tmp=str2double(tmp);
    tmp_prediction_d2{j}=tmp;
    tmp_perf_d2(j)=mean(tmp==Y(cvobj.test(j)));

    counter=counter+1;
    upd(counter);

  end

  model_prediction_d1(i,:)=tmp_prediction_d1;
  model_prediction_d2(i,:)=tmp_prediction_d2;
  model_prediction_both(i,:)=tmp_prediction_both;
  model_obs_classes(i,:)=tmp_obs_classes;

  model_perf_d1(i,:)=tmp_perf_d1;
  model_perf_d2(i,:)=tmp_perf_d2;
  model_perf_both(i,:)=tmp_perf_both;

end

upd(inf);

model_perf.d1=model_perf_d1;
model_perf.d2=model_perf_d2;
model_perf.both=model_perf_both;

model_prediction.d1=model_prediction_d1;
model_prediction.d2=model_prediction_d2;
model_prediction.both=model_prediction_both;
model_prediction.obs_classes=model_obs_classes;

fprintf('Saving data at %s\n',opts.save_location);
metadata=opts.metadata;
save(opts.save_location,'model_prediction','model_perf','metadata');
