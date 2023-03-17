%% get averages and confidence intervals for changepoints

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/photometry_nac/phanalysis_object.mat');
    phan=phanalysis_object;
end

if ~exist('changepoints','var')
    phan.set_option('filter_trace',true);
    phan.set_option('filter_corners',.75);
    phan.set_option('filter_method','ellip');
    phan.set_option('rectify',false);
    phan.set_option('use_model_changepoints',true);
    changepoints=phan.slice_changepoints_neural;
end

%%

% plot using derivatives


% bootstrp the means

max_lag=phan.options.max_lag;
keep_win=[60 90];
offset=0;
fs=30;
nboots=phan.user_data.nboots;
%nboots=50;
nshuffles=phan.user_data.nshuffles;
tvec=[-keep_win(1):keep_win(2)]/fs;
chk_fields={'wins','wins_dt','wins_auto','wins_auto_dt'};
opts=statset('UseParallel',true);

%%

upd=kinect_extract.proc_timer(length(chk_fields));

% get the bootstrap standard error for each mean
rp_cat=struct();
rp_cat.tvec=tvec;
rp_cat.nshuffles=nshuffles;
nsamples=2e4;

for i=1:length(chk_fields)
  
    gcamp_cat=zscore(cat(2,changepoints.gcamp(:).(chk_fields{i})));
    rcamp_cat=zscore(cat(2,changepoints.rcamp(:).(chk_fields{i})));
    
    ntrials_gcamp=size(gcamp_cat,2);
    ntrials_rcamp=size(rcamp_cat,2);
    
    rndpool_gcamp=randperm(ntrials_gcamp);
    rndpool_rcamp=randperm(ntrials_rcamp);
    
    gcamp_cat=(gcamp_cat(max_lag-keep_win(1):max_lag+keep_win(2),:));
    rcamp_cat=(rcamp_cat(max_lag-keep_win(1):max_lag+keep_win(2),:));
    
    rp_cat.(chk_fields{i}).gcamp_mu=nanmean((gcamp_cat)');  
    rp_cat.(chk_fields{i}).rcamp_mu=nanmean((rcamp_cat)');
% 
     gcamp_boot=bootstrp(nboots,@nanmean,(gcamp_cat)','options',opts);
     rcamp_boot=bootstrp(nboots,@nanmean,(rcamp_cat)','options',opts);
%     
     gcamp_sem=std(gcamp_boot);
     rcamp_sem=std(rcamp_boot);
%    
    rp_cat.(chk_fields{i}).gcamp_ci=[rp_cat.(chk_fields{i}).gcamp_mu-gcamp_sem;rp_cat.(chk_fields{i}).gcamp_mu+gcamp_sem];
    rp_cat.(chk_fields{i}).rcamp_ci=[rp_cat.(chk_fields{i}).rcamp_mu-rcamp_sem;rp_cat.(chk_fields{i}).rcamp_mu+rcamp_sem];
%      
    gcamp_shuffle=phanalysis.shuffle_statistic(@nanmean,gcamp_cat',nshuffles,true);
    rcamp_shuffle=phanalysis.shuffle_statistic(@nanmean,rcamp_cat',nshuffles,true);
    
    rp_cat.(chk_fields{i}).gcamp_shuffle_ci=[prctile(gcamp_shuffle,[.5 99.5],2)'];
    rp_cat.(chk_fields{i}).rcamp_shuffle_ci=[prctile(rcamp_shuffle,[.5 99.5],2)'];
    
    
    rp_cat.(chk_fields{i}).gcamp_shuffle=gcamp_shuffle';
    rp_cat.(chk_fields{i}).rcamp_shuffle=rcamp_shuffle';
    
    rp_cat.(chk_fields{i}).gcamp=gcamp_cat';
    rp_cat.(chk_fields{i}).rcamp=rcamp_cat';
    
    upd(i);
    
end


%%

save('~/Desktop/phanalysis_images/changepoints_stats_nac.mat','tvec','rp_cat','-v7.3');
