%%

if ~exist('phan','var')
    load('~/Desktop/workspace/1pimaging_dls/_analysis/phanalysis_object_manual_segmentation_v11.mat');
    phan=phanalysis_object;
end


%%

% parameters

% cluster parameters

use_cluster='o2';
wall_time='00:45:00';
queue_name='short';
mem_usage='4000M'; % this is per cpu, tried doing it the other way and all jobs failed under suspicious circumstances

% model parameters, loop over n(cells)

neuron_strides=[5:5:30];
%neuron_strides=10;
ntrees=2000;
min_leaf_size=1;
max_num_splits=1e3;
nrands=0;
nboots=100;
pool_size=0;
use_mice=[7];
nfolds=5;
trial_cut=15;
win=[-.2 .2];
shift=0;


phan.set_option('scalar_shift',shift);
phan.compute_scalars_correlation;



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


% build a psuedo-pop

mouse_groups={phan.session(:).group};

%idx=find(strcmp(mouse_groups,'d1cre')|strcmp(mouse_groups,'a2acre'));
% find one d1 cre and a2a cre to compare with our dual-pathway guys

idx=[1 12];

min_trials=trial_cut;
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

% merge logic: take the same number of trials per syllable per mouse (makes
% sense right?)

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

stream = RandStream('mrg32k3a'); % use a thread-safe rng, boot number is tied to a substream

counter=1;
counter2=1;

job_details='within animal decoding';

use_time=datestr(now,30);
save_dir=sprintf('/n/groups/datta/Jeff/workspace/analysis/decoding_results_imaging_withinanimal/%s',use_time);

if ~exist(save_dir,'dir')
    mkdir(save_dir);
end

save_dir2=sprintf('/n/groups/datta/Jeff/workspace/analysis/decoding_results_imaging_withinanimal_compare/%s',use_time);

if ~exist(save_dir2,'dir')
    mkdir(save_dir2);
end

save(fullfile(save_dir2,'job_details.mat'),'max_num_splits','min_leaf_size','ntrees',...
    'pseudo_pop','pseudo_pop_labels','pseudo_group','shift','-v7.3');

pseudo_group(strcmp(pseudo_group,'d1'))={'d1cre'};
pseudo_group(strcmp(pseudo_group,'d2'))={'a2acre'};

for i=1:length(use_mice)
    
    ca_data=phanalysis.nanzscore(phan.stats.corr_imaging(use_mice(i)).data);
    use_labels=phan.stats.corr_scalars(use_mice(i)).model_labels;
    cell_types={phan.imaging(use_mice(i)).traces(:).cell_type};
    
    ign=use_labels>phan.options.syllable_cutoff;
    use_labels(ign)=[];
    ca_data(ign,:)=[];
    
    d1_rois=find(strcmp(cell_types,'d1'));
    d2_rois=find(strcmp(cell_types,'d2'));
    
    tmp=accumarray(use_labels,ones(size(use_labels)));
    use_idx=find(tmp>trial_cut);
    
    newmat=[];
    newlabels=[];
    
    for j=1:length(use_idx)
        hits=find(use_labels==use_idx(j));
        newmat=[newmat;ca_data(hits(1:trial_cut),:)];
        newlabels=[newlabels;ones(trial_cut,1)*j];
    end
    
    newmat=newmat(:,[d1_rois d2_rois]);
    
    for j=1:nboots
        for k=1:length(neuron_strides)
            
            if neuron_strides(k)>size(newmat,2)
                counter=counter+1;
                continue;
            end
            
            cvobj=cvpartition(newlabels,'kfold',nfolds);
            
            metadata=struct();
            metadata.job_details=job_details;
            metadata.ncells=neuron_strides(k);
            metadata.cell_idx=k;
            metadata.boot_idx=j;
            metadata.mouse_idx=i;
            metadata.nboots=nboots;
            metadata.nfolds=nfolds;
            metadata.ntrees=ntrees;
            metadata.data=newmat;
            metadata.labels=newlabels;
            
            cvobj=cvpartition(newlabels,'kfold',nfolds);
            metadata.cvobj=cvobj;
            
            job_name=sprintf('rf_decoding_results_%05i.mat',counter);
            save_location=fullfile(save_dir,job_name);
            
            fprintf('Submitting job %i of %i within animal\n',counter,length(neuron_strides)*nboots*length(use_mice));
            
            batch(clust,@d1d2_decode_batch_withinanimal,0,...
                {newmat,newlabels,...
                'nrands',0,'save_location',save_location,'metadata',metadata,'ntrees',ntrees,...
                'min_leaf_size',min_leaf_size,'ncells',neuron_strides(k),'nboots',1,'cvobj',cvobj,...
                'max_num_splits',max_num_splits,'nfolds',nfolds,'rnd_stream',stream,'rnd_substream',j},...
                'AutoAttachFiles',false,'Pool',pool_size);
            
            counter=counter+1;
                        
            job_name=sprintf('rf_decoding_results_%05i.mat',counter2);
            save_location=fullfile(save_dir2,job_name);
            
            fprintf('Submitting job %i of %i compare animal\n',counter2,length(neuron_strides)*nboots*length(use_mice));
            
            metadata=struct();
            metadata.job_details=job_details;
            metadata.ncells=neuron_strides(k);
            metadata.cell_idx=k;
            metadata.boot_idx=j;
            metadata.mouse_idx=i;
            metadata.nboots=nboots;
            metadata.nfolds=nfolds;
            metadata.ntrees=ntrees;
            cvobj=cvpartition(pseudo_pop_labels,'kfold',nfolds);
            metadata.cvobj=cvobj;
            
            use_d1s=find(strcmp(pseudo_group,'d1cre'));
            use_d2s=find(strcmp(pseudo_group,'a2acre'));
            
            use_d1s=randsample(use_d1s,length(d1_rois),false);
            use_d2s=randsample(use_d2s,length(d2_rois),false);
            
            metadata.use_d1s=use_d1s;
            metadata.use_d2s=use_d2s;
            
            use_pseudo_pop=pseudo_pop(:,[use_d1s use_d2s]);
            
            batch(clust,@d1d2_decode_batch_withinanimal,0,...
                {use_pseudo_pop,pseudo_pop_labels,...
                'nrands',0,'save_location',save_location,'metadata',metadata,'ntrees',ntrees,...
                'min_leaf_size',min_leaf_size,'ncells',neuron_strides(k),'nboots',1,'cvobj',cvobj,...
                'max_num_splits',max_num_splits,'nfolds',nfolds,'rnd_stream',stream,'rnd_substream',j},...
                'AutoAttachFiles',false,'Pool',pool_size);
            
            counter2=counter2+1;
                                    
        end
        
    end
end

