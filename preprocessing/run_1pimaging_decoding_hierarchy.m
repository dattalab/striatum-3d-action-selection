%%


if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end

%%

% cluster parameters

use_cluster='local';
wall_time='01:00:00';
queue_name='short';
mem_usage='4000M';
pool_size=0;

% model parameters, loop over n(cells)

neuron_strides=600;
%nboots=100;
nboots=100;
nfolds=5;
ntrees=2000;
min_leaf_size=1;
max_num_splits=1e3;
nrands=0;
levels=[.01 .1:.1:2];
win=[-.2 .2];
shift=0;

%%

phan.set_option('scalar_shift',shift);
phan.compute_scalars_correlation;

%

% build a psuedo-pop

mouse_groups={phan.session(:).group};

idx=find(strcmp(mouse_groups,'d1cre')|strcmp(mouse_groups,'a2acre'));
min_trials=15;
cut=phan.options.syllable_cutoff;

% get number of trials per label per cell, then establish cutoffs to merge
% across mice
ntrials=nan(length(idx),cut);

nrois=nan(length(idx),1);

for i=1:length(idx)
    labels=phan.stats.corr_scalars(idx(i)).model_labels;
    labels(isnan(labels))=[];
    labels(labels>cut)=[];
    ntrials(i,:)=accumarray(labels,ones(size(labels)));
    nrois(i)=length(phan.imaging(idx(i)).traces);
end

% only add from a given mouse if we have the min number of trials

use_syllables=find(all(ntrials>min_trials));
pseudo_pop=nan(length(use_syllables)*min_trials,sum(nrois));
pseudo_pop_labels=nan(length(use_syllables)*min_trials,1);
pseudo_group=cell(1,sum(nrois));

roi_count=0;
trial_count=0;

for i=1:length(idx)
    
    use_labels=phan.stats.corr_scalars(idx(i)).model_labels;
    use_data=phanalysis.nanzscore(phan.stats.corr_imaging(idx(i)).data);
    tmp_rois=size(use_data,2);
    
    in_pool=ismember(use_labels,use_syllables);
    
    use_labels(~in_pool)=[];
    use_data(~in_pool,:)=[];
    trial_count=0;
    cur_group=mouse_groups{idx(i)};
    
    for j=1:length(use_syllables)
        
        hits=find(use_labels==use_syllables(j));
        keep_hits=hits(1:min_trials);
        pseudo_pop(trial_count+1:trial_count+min_trials,roi_count+1:roi_count+tmp_rois)=use_data(keep_hits,:);
        pseudo_pop_labels(trial_count+1:trial_count+min_trials)=use_syllables(j);
        trial_count=trial_count+min_trials;
        pseudo_group(roi_count+1:roi_count+tmp_rois)=repmat({cur_group},[1 tmp_rois]);
        
    end
    
    roi_count=roi_count+tmp_rois;
    
    
end



%%

switch lower(use_cluster)
    
    case 'o2'
        
        ClusterInfo.setWallTime(wall_time);
        ClusterInfo.setQueueName(queue_name);
        ClusterInfo.setMemUsage(mem_usage);
        %ClusterInfo.setUserDefinedOptions(sprintf('--mem=%s',mem_usage));
        clust=parcluster;
        
    case 'local'
        
        clust=parcluster('local');
        
    otherwise
        
end

%%

save_dir=sprintf('~/Desktop/phanalysis_images/decoding_results_imaging_pseudo_hierarchy/%s',datestr(now,30));
job_details='pseudo population analysis of inscopix data';

if ~exist(save_dir,'dir')
    mkdir(save_dir);
end

Z=linkage(squareform(phan.distance.inter.ar(1:phan.options.syllable_cutoff,1:phan.options.syllable_cutoff),'tovector'),'complete');

save(fullfile(save_dir,'job_details.mat'),'max_num_splits','min_leaf_size','ntrees',...
    'pseudo_pop','pseudo_pop_labels','pseudo_group','shift','-v7.3');

counter=1;
stream = RandStream('mrg32k3a'); % use a thread-safe rng, boot number is tied to a substream

for i=1:length(levels)
    
    model_labels_clust=cluster(Z,'cutoff',levels(i),'criterion','distance');
    [clusts,~,model_labels_clust]=unique(model_labels_clust);
    pseudo_use_labels=model_labels_clust(pseudo_pop_labels);
    
    for j=1:nboots
    
        metadata=struct();
        metadata.job_details=job_details;
        metadata.ncells=neuron_strides;
        metadata.boot_idx=j;        
        metadata.level_idx=i;
        metadata.nboots=nboots;
        metadata.nfolds=nfolds;
        metadata.ntrees=ntrees;
        metadata.level=levels(i);
        metadata.hierarchy_labels=model_labels_clust;
        cvobj=cvpartition(pseudo_use_labels,'kfold',nfolds);
        metadata.cvobj=cvobj;

        job_name=sprintf('rf_decoding_results_%05i.mat',counter);
        save_location=fullfile(save_dir,job_name);

        fprintf('Submitting job %i of %i\n',counter,length(levels)*nboots);
        try
            batch(clust,@decode_batch_pseudo_pop,0,...
                {pseudo_pop,pseudo_use_labels,pseudo_group,...
                'nrands',0,'save_location',save_location,'metadata',metadata,'ntrees',ntrees,...
                'min_leaf_size',min_leaf_size,'ncells',neuron_strides,'nboots',1,'cvobj',cvobj,...
                'max_num_splits',max_num_splits,'nfolds',nfolds,'rnd_stream',stream,'rnd_substream',j},...
                'AutoAttachFiles',false,'Pool',pool_size);
        catch
            pause(2);
            batch(clust,@decode_batch_pseudo_pop,0,...
                {pseudo_pop,pseudo_use_labels,pseudo_group,...
                'nrands',0,'save_location',save_location,'metadata',metadata,'ntrees',ntrees,...
                'min_leaf_size',min_leaf_size,'ncells',neuron_strides,'nboots',1,'cvobj',cvobj,...
                'max_num_splits',max_num_splits,'nfolds',nfolds,'rnd_stream',stream,'rnd_substream',j},...
                'AutoAttachFiles',false,'Pool',pool_size);
        end
            
        
        counter=counter+1;
    end    
end