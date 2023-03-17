%%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/photometry_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end

if ~exist('model_starts','var')
    phan.set_option('normalize_method','');
    phan.set_option('rectify',false);
    phan.set_option('filter_trace',false);
    model_starts=phan.slice_syllables_neural;    
end

%%

cut=phan.options.syllable_cutoff;
linkage_type='complete';
usemat=squareform(phan.distance.inter.ar(1:cut,1:cut),'tovector');
z=linkage(usemat,linkage_type);
win=[0 0];
warp_len=20;
use_field='win';

levels=[.01 .1:.1:1.7];
nrands=0;
nfolds=5;
max_num_splits=1e3;
min_leaf_size=1;
ntrees=2000;
job_details='decoding_dt_test';

%%

train_x=struct();

[train_x.all_w,train_y]=...
    decode_photometry_collect_waveforms(phan,model_starts,...
    'all_cut',cut,'window',win,'data_threshold',...
    -inf,'use_field','wins','use_duration','w',...
    'warp_length',warp_len);
[train_x.all_dt_w,~]=...
    decode_photometry_collect_waveforms(phan,model_starts,...
    'all_cut',cut,'window',win,'data_threshold',...
    -inf,'use_field','wins_dt','use_duration','w',...
    'warp_length',warp_len);

%%

% equalize number of trials

ntrials=accumarray(train_y,ones(size(train_y)));
trials_per_syllable=min(ntrials);

incl=[];

for i=1:cut
   idx=find(train_y==i);
   idx=idx(:);
   incl=[incl;idx(1:trials_per_syllable)];       
end

train_x.all_w=train_x.all_w(incl,:);
train_x.all_dt_w=train_x.all_dt_w(incl,:);
train_y=train_y(incl);

to_del=any(isnan(train_x.all_w'));

train_x.all_w(to_del,:)=[];
train_x.all_dt_w(to_del,:)=[];
train_y(to_del)=[];

train_x.gcamp_w=train_x.all_w(:,1:warp_len);
train_x.rcamp_w=train_x.all_w(:,warp_len+1:end);

train_x.gcamp_dt_w=train_x.all_dt_w(:,1:warp_len);
train_x.rcamp_dt_w=train_x.all_dt_w(:,warp_len+1:end);

%train_x.all_diff_w=[train_x.all_w (train_x.rcamp_w-train_x.gcamp_w)];

train_x.gcamp_dt_w_combined=[train_x.gcamp_w train_x.gcamp_dt_w];
train_x.rcamp_dt_w_combined=[train_x.rcamp_w train_x.rcamp_dt_w];
train_x.all_dt_w_combined=[train_x.all_w train_x.all_dt_w];


%%

wall_time='5:00:00';
queue_name='short';
mem_usage='5000';
use_cluster='local';

switch lower(use_cluster)

    case 'o2'

        ClusterInfo.setWallTime(wall_time);
        ClusterInfo.setQueueName(queue_name);
        ClusterInfo.setMemUsage(mem_usage);
        clust=parcluster;


    case 'local'

        clust=parcluster('local');

    otherwise

end
%%

counter=0;
cvobj=cvpartition(train_y,'kfold',nfolds);

model_labels_clust=cluster(z,'cutoff',levels,'criterion','distance');

nlevels=length(levels);
save_dir=sprintf('~/Desktop/phanalysis_images/decoding_results_photometry/%s',datestr(now,30));

if ~exist(save_dir,'dir')
    mkdir(save_dir);
end


use_fields=fieldnames(train_x);
save(fullfile(save_dir,'job_details.mat'),'train_x','train_y','levels','use_fields','nfolds','z','-v7.3');
nfields=length(use_fields);


for ii=1:length(use_fields)

    tmp_score=train_x.(use_fields{ii});

    for i=1:nlevels

        [clusts,~,tmp_map]=unique(model_labels_clust(:,i));

        % grab the cluster labels for the current cut

        use_y=tmp_map(train_y);
        cvobj=cvpartition(use_y,'kfold',nfolds);

        for j=1:nfolds

            batch_train_x=tmp_score(cvobj.training(j),:);
            batch_train_y=use_y(cvobj.training(j));

            batch_test_x=tmp_score(cvobj.test(j),:);
            batch_test_y=use_y(cvobj.test(j));

            job_name=sprintf('rf_decoding_results_%05i.mat',counter);
            save_location=fullfile(save_dir,job_name);

            metadata=struct();

            metadata.level=levels(i);
            metadata.level_idx=i;
            metadata.fold_idx=j;
            metadata.data_type=use_fields{ii};
            metadata.job_details=job_details;
            metadata.win=win;
            metadata.warp_len=warp_len;
            metadata.clust_map=tmp_map;

            fprintf('Submitting job %i of %i\n',counter+1,nfolds*nlevels*length(use_fields));

            try
                batch(clust,@decode_batch,0,...
                        {batch_train_x,batch_train_y,...
                         batch_test_x,batch_test_y,...
                        'nrands',nrands,'save_location',save_location,...
                        'metadata',metadata,'ntrees',ntrees,...
                        'min_leaf_size',min_leaf_size,'max_num_splits',max_num_splits},...
                        'AutoAttachFiles',false);
            catch
                pause(10);
                batch(clust,@decode_batch,0,...
                    {batch_train_x,batch_train_y,...
                     batch_test_x,batch_test_y,...
                    'nrands',nrands,'save_location',save_location,...
                    'metadata',metadata,'ntrees',ntrees,...
                    'min_leaf_size',min_leaf_size,'max_num_splits',max_num_splits},...
                    'AutoAttachFiles',false);
            end

            counter=counter+1;
            %upd(counter);

        end
    end
end
