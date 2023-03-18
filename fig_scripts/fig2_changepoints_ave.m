%% get averages and confidence intervals for changepoints

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/photometry_dls/phanalysis_object.mat');
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
chk_fields={'wins','wins_dt','wins_auto','wins_auto_dt','wins_deconv','wins_auto_deconv'};
%chk_fields={'wins','wins_dt','wins_auto','wins_auto_dt'};
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

save('~/Desktop/phanalysis_images/changepoints_stats_dls.mat','tvec','rp_cat','-v7.3');

%%

% plotting
plot_fields={'wins','wins_auto','wins_dt','wins_auto_dt','wins_deconv','wins_auto_deconv'};
%plot_fields={'wins','wins_auto','wins_dt','wins_auto_dt'};

changepoint_ave=schfigure([],false);
changepoint_ave.dims='4x4';
changepoint_ave.formats='eps,png,fig';
changepoint_ave.name='changepoint_ave_dls_zscore';
%tvec=rp_cat.tvec;

for i=1:length(plot_fields)
    
    subplot(3,2,i);
    
   
    gcamp_shuf_mu=nanmean(rp_cat.(plot_fields{i}).gcamp_shuffle);
    gcamp_shuf_sig=nanstd(rp_cat.(plot_fields{i}).gcamp_shuffle);
    rcamp_shuf_mu=nanmean(rp_cat.(plot_fields{i}).rcamp_shuffle);
    rcamp_shuf_sig=nanstd(rp_cat.(plot_fields{i}).rcamp_shuffle);
    
    zgcamp=@(x) (x-mean(gcamp_shuf_mu))./max(gcamp_shuf_sig);
    zrcamp=@(x) (x-mean(rcamp_shuf_mu))./max(rcamp_shuf_sig);
    
    if ~contains(plot_fields{i},'auto')
        
        changepoint_ave.shaded_errorbar(tvec,prctile(zgcamp(rp_cat.(plot_fields{i}).gcamp_shuffle),[.5 99.5]),[.75 .75 .75],'none');
        hold on;

        changepoint_ave.shaded_errorbar(tvec,zgcamp(rp_cat.(plot_fields{i}).gcamp_ci),[0 1 0],'none');
        plot(tvec,zgcamp(rp_cat.(plot_fields{i}).gcamp_mu),'k-');
        changepoint_ave.shaded_errorbar(tvec,prctile(zrcamp(rp_cat.(plot_fields{i}).rcamp_shuffle),[.5 99.5]),[.75 .75 .75],'none');
        changepoint_ave.shaded_errorbar(tvec,zrcamp(rp_cat.(plot_fields{i}).rcamp_ci),[1 0 0],'none');
        plot(tvec,zrcamp(rp_cat.(plot_fields{i}).rcamp_mu),'k-');
    else
        changepoint_ave.shaded_errorbar(tvec,prctile(zgcamp(rp_cat.(plot_fields{i}).gcamp_shuffle),[.5 99.5]),[.75 .75 .75],'none');
        hold on;        
        changepoint_ave.shaded_errorbar(tvec,zgcamp(rp_cat.(plot_fields{i}).gcamp_ci),[.25 .25 .25],'none');
        plot(tvec,zgcamp(rp_cat.(plot_fields{i}).gcamp_mu),'k-');
    end 
    
    
    
    xlim([-2 3]);
    ylim([-20 20 ]);
    ylims=ylim();
    schfigure.sparsify_axis([],[],[],[-2 0 3],[ylims(1) 0 ylims(2)]);
    changepoint_ave.outify_axis;
    plot([0 0],get(gca,'ylim'),'k-')
    plot(get(gca,'xlim'),[0  0],'k-');
    set(gca,'FontSize',8);
    %offsetAxes;
    
end

%%

save('~/Desktop/phanalysis_images/changepoints_stats_dls.mat','tvec','rp_cat','-v7.3');
