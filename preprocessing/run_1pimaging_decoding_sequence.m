

%%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end

%%
% parameters

% cluster parameters

use_cluster='local';
wall_time='01:00:00';
queue_name='short';
mem_usage='4000M'; % this is per cpu, tried doing it the other way and all jobs failed under suspicious circumstances

% model parameters, loop over n(cells)

neuron_strides=[10:10:60 100:50:600];
nfolds=5;
ntrees=2000;
min_leaf_size=1;
max_num_splits=1e3;
nrands=0;
nboots=100;
pool_size=0;

%% construct the pseudo pops

beh.get_transition_matrix;
trans_to_p=@(x,dim) bsxfun(@rdivide,x,sum(x,dim));
grps={phan.session(:).group};
%all_trans=cat(3,beh(contains(grps,'ctrl')).transition_matrix);
all_trans=cat(3,beh(:).transition_matrix);
all_trans=sum(all_trans,3);
%all_trans=all_trans(1:cutoff,1:cutoff);

all_trans_p_out=trans_to_p(all_trans+1,2);
all_trans_p_in=trans_to_p(all_trans+1,1);



% take the correlation stats output and use to construct a training set for
% decoding

all_data_x={};
all_data_y={};

lo_cutoff=50;
hi_cutoff=50;

syllable_cutoff=phan.options.syllable_cutoff;

in_cut_lo=nan(1,length(phan.stats.corr_scalars));
in_cut_hi=nan(size(in_cut_lo));
out_cut_lo=nan(size(in_cut_lo));
out_cut_hi=nan(size(in_cut_lo));

for i=1:syllable_cutoff
   p_in=[];
   p_out=[];
   for j=1:length(phan.stats.corr_scalars)
       tmp_idx=find(phan.stats.corr_scalars(j).model_labels==i);
       tmp_idx(tmp_idx==1)=[];
       tmp_idx(tmp_idx==length(phan.stats.corr_scalars(j).model_labels))=[];
       
       tmp_next=phan.stats.corr_scalars(j).model_labels(tmp_idx+1);
       tmp_prev=phan.stats.corr_scalars(j).model_labels(tmp_idx-1);
       
       to_del=isnan(tmp_idx)|isnan(tmp_next)|isnan(tmp_prev);
       
       tmp_idx(to_del)=[];
       tmp_prev(to_del)=[];
       tmp_next(to_del)=[];   
       
       tmp_in=all_trans_p_in(tmp_prev,i);
       tmp_out=all_trans_p_out(i,tmp_next);
        
       p_in=[p_in;tmp_in(:)];
       p_out=[p_out;tmp_out(:)];
   end
   
   in_cut_lo(i)=prctile(p_in,lo_cutoff);
   in_cut_hi(i)=prctile(p_in,hi_cutoff);
   out_cut_lo(i)=prctile(p_out,lo_cutoff);
   out_cut_hi(i)=prctile(p_out,hi_cutoff);
   
end

for i=1:length(phan.stats.corr_scalars)
    
    all_data_x{i}=[];
    all_data_y{i}=[];
    
    nsyllables=length(phan.stats.corr_scalars(i).model_labels);
    
    for j=1:syllable_cutoff
       
       tmp_idx=find(phan.stats.corr_scalars(i).model_labels==j);
       tmp_idx(tmp_idx==1)=[];
       tmp_idx(tmp_idx==length(phan.stats.corr_scalars(i).model_labels))=[];
       
       tmp_next=phan.stats.corr_scalars(i).model_labels(tmp_idx+1);
       tmp_prev=phan.stats.corr_scalars(i).model_labels(tmp_idx-1);
       
       to_del=isnan(tmp_idx)|isnan(tmp_next)|isnan(tmp_prev);
       
       tmp_idx(to_del)=[];
       tmp_prev(to_del)=[];
       tmp_next(to_del)=[];   
       
       p_in=all_trans_p_in(tmp_prev,j);
       p_out=all_trans_p_out(j,tmp_next);

       for k=1:length(tmp_idx)
          
           if p_in(k)<=in_cut_lo(j) & p_out(k)<=out_cut_lo(j)
               all_data_y{i}(end+1)=0; 
           elseif p_in(k)>in_cut_hi(j) & p_out(k)>out_cut_hi(j)
               all_data_y{i}(end+1)=1; 
           else
               continue;
           end
           
           all_data_x{i}(:,end+1)=phan.stats.corr_imaging(i).data(tmp_idx(k),:);
           
       end
       
    end
end

% form pseudo-populations

ncells=cellfun(@(x) size(x,1),all_data_x);
group_idx=find(strcmp({phan.session.group},'d1cre')|strcmp({phan.session.group},'a2acre'));

npos=cellfun(@(x) sum(x==1),all_data_y(group_idx));
nneg=cellfun(@(x) sum(x==0),all_data_y(group_idx));
ntrials=min([npos(:);nneg(:)]);

total_trials=ntrials*2;

pseudo_pop=zeros(sum(ncells(group_idx)),total_trials);
pseudo_pop_labels=zeros(1,total_trials);
pseudo_group=cell(sum(ncells(group_idx)),1);

cell_idx=0;

for j=1:length(group_idx)

    cur_ncells=ncells(group_idx(j));
    pos_trials=find(all_data_y{group_idx(j)}==1);
    neg_trials=find(all_data_y{group_idx(j)}==0);

    pseudo_pop(cell_idx+1:cell_idx+cur_ncells,...
        1:ntrials)=all_data_x{group_idx(j)}(:,pos_trials(1:ntrials));            
    pseudo_pop(cell_idx+1:cell_idx+cur_ncells,...
        ntrials+1:end)=all_data_x{group_idx(j)}(:,neg_trials(1:ntrials));
    pseudo_group(cell_idx+1:cell_idx+cur_ncells)={phan.session(group_idx(j)).group};
    cell_idx=cell_idx+cur_ncells;

end

pseudo_pop_labels(1:ntrials)=1;
pseudo_pop_labels(ntrials+1:end)=0;

pseudo_pop=(pseudo_pop);

pseudo_pop=pseudo_pop';
pseudo_pop_labels=pseudo_pop_labels';
pseudo_group=pseudo_group;

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

save_dir=sprintf('~/Desktop/phanalysis_images/decoding_results_imaging_pseudo_sequence/%s',datestr(now,30));
job_details='pseudo population analysis of inscopix data';

if ~exist(save_dir,'dir')
    mkdir(save_dir);
end

save(fullfile(save_dir,'job_details.mat'),'max_num_splits','min_leaf_size','ntrees',...
    'pseudo_pop','pseudo_pop_labels','pseudo_group','-v7.3');

pseudo_group(strcmp(pseudo_group,'d1'))={'d1cre'};
pseudo_group(strcmp(pseudo_group,'d2'))={'a2acre'};
counter=1;
stream = RandStream('mrg32k3a'); % use a thread-safe rng, boot number is tied to a substream

for i=1:length(neuron_strides)
    for j=1:nboots
        metadata=struct();
        metadata.job_details=job_details;
        metadata.ncells=neuron_strides(i);
        metadata.boot_idx=j;
        metadata.cell_idx=i;
        metadata.nboots=nboots;
        metadata.nfolds=nfolds;
        metadata.ntrees=ntrees;
        cvobj=cvpartition(pseudo_pop_labels,'kfold',nfolds);
        metadata.cvobj=cvobj;

        job_name=sprintf('rf_decoding_results_%05i.mat',counter);
        save_location=fullfile(save_dir,job_name);

        fprintf('Submitting job %i of %i\n',counter,length(neuron_strides)*nboots);

        try
            batch(clust,@decode_batch_pseudo_pop,0,...
                {pseudo_pop,pseudo_pop_labels,pseudo_group,...
                'nrands',0,'save_location',save_location,'metadata',metadata,'ntrees',ntrees,...
                'min_leaf_size',min_leaf_size,'ncells',neuron_strides(i),'nboots',1,'cvobj',cvobj,...
                'max_num_splits',max_num_splits,'nfolds',nfolds,'rnd_stream',stream,'rnd_substream',j},...
                'AutoAttachFiles',false,'Pool',pool_size);
        catch
            disp('Encountered error, pausing for 5 seconds');
            pause(5);
            batch(clust,@decode_batch_pseudo_pop,0,...
                {pseudo_pop,pseudo_pop_labels,pseudo_group,...
                'nrands',0,'save_location',save_location,'metadata',metadata,'ntrees',ntrees,...
                'min_leaf_size',min_leaf_size,'ncells',neuron_strides(i),'nboots',1,'cvobj',cvobj,...
                'max_num_splits',max_num_splits,'nfolds',nfolds,'rnd_stream',stream,'rnd_substream',j},...
                'AutoAttachFiles',false,'Pool',pool_size);
        end 
        
        counter=counter+1;
    end
end