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


% average the gcamp and rcamp waveforms for the different manually
% identified syllable classes

syll.rearup = [30 14 6 27 28];
syll.reard = [16 7 23];
syll.runfwd = [18 4 21 35 15 3 33];
syll.movefwd = [39 37 36 8];
syll.pause = [2 1 20 10];
syll.scrunchl = [17 38 22 31];
syll.scrunch = [40 25 11 5 32 9 41];
syll.scrunchr = [26 34 29 12 24 19 13];

col=[1 1 1 2 1 2 2 2];
row=[1 2 3 3 4 1 4 2];

nboots = 1e3;
nshuffles= 1e3;
classes = fieldnames(syll);

rcamp_sessions=[model_starts.rcamp(1,:).session_idx];
gcamp_sessions=[model_starts.gcamp(1,:).session_idx];

% only take sessions w/both gcamp and rcamp
intersession=intersect(unique(rcamp_sessions),unique(gcamp_sessions));

use_gcamp=ismember(gcamp_sessions,intersession);
use_rcamp=ismember(rcamp_sessions,intersession);
opts=statset('UseParallel',true);
win_smps=[60 90];
max_lag=phan.options.max_lag;
tvec=[-win_smps(1):win_smps(2)]/phan.options.fs;

class_fig=schfigure();
class_fig.name='class_averages';
class_fig.dims='5x5';
class_fig.formats='eps,png,fig';

ax=[];

for i=1:length(classes)
    % go through each class and concatenate the gcamp and rcamp signals
    cls = classes{i};
    
    gcamp_stitch=phanalysis.nanzscore(cat(2,model_starts.gcamp(syll.(cls),use_gcamp).wins));
    rcamp_stitch=phanalysis.nanzscore(cat(2,model_starts.rcamp(syll.(cls),use_rcamp).wins));
    
    gcamp_stitch=gcamp_stitch(max_lag-win_smps(1):max_lag+win_smps(2),:);
    rcamp_stitch=rcamp_stitch(max_lag-win_smps(1):max_lag+win_smps(2),:);
        
    % derivative
    gcamp_stitch_dt=phanalysis.nanzscore(cat(2,model_starts.gcamp(syll.(cls),use_gcamp).wins_dt));
    rcamp_stitch_dt=phanalysis.nanzscore(cat(2,model_starts.rcamp(syll.(cls),use_rcamp).wins_dt));
    
    gcamp_stitch_dt=gcamp_stitch_dt(max_lag-win_smps(1):max_lag+win_smps(2),:);
    rcamp_stitch_dt=rcamp_stitch_dt(max_lag-win_smps(1):max_lag+win_smps(2),:);
    
    % bootstraps
    gcamp_stat = bootstrp(nboots, @nanmean, gcamp_stitch','options',opts);
    rcamp_stat = bootstrp(nboots, @nanmean, rcamp_stitch','options',opts);
   
    % derivative
    gcamp_stat_dt = bootstrp(nboots, @nanmean, gcamp_stitch_dt','options',opts);
    rcamp_stat_dt = bootstrp(nboots, @nanmean, rcamp_stitch_dt','options',opts);
    
    gcamp_shuffle=phanalysis.shuffle_statistic(@nanmean,gcamp_stitch',nshuffles,false)';
    rcamp_shuffle=phanalysis.shuffle_statistic(@nanmean,rcamp_stitch',nshuffles,false)';
    
    zgcamp=@(x) (x-mean(nanmean(gcamp_shuffle)))./max(nanstd(gcamp_shuffle));
    zrcamp=@(x) (x-mean(nanmean(rcamp_shuffle)))./max(nanstd(rcamp_shuffle));
    
    gcamp_shuffle_dt=phanalysis.shuffle_statistic(@nanmean,gcamp_stitch_dt',nshuffles,false)';
    rcamp_shuffle_dt=phanalysis.shuffle_statistic(@nanmean,rcamp_stitch_dt',nshuffles,false)';
    
    zgcamp_dt=@(x) (x-mean(nanmean(gcamp_shuffle_dt)))./max(nanstd(gcamp_shuffle_dt));
    zrcamp_dt=@(x) (x-mean(nanmean(rcamp_shuffle_dt)))./max(nanstd(rcamp_shuffle_dt));
    
    offset=(row(i)-1)*4;
    offset=offset+(col(i)-1)*2;
    
    ax(end+1)=subplot(max(row),max(col)*2,offset+1);
    schfigure.plot_trace_with_ci(tvec,zrcamp(rcamp_stitch'),zrcamp(rcamp_stat),...
        'face_color',[1 0 0]);
    schfigure.plot_trace_with_ci(tvec,zgcamp(gcamp_stitch'),zgcamp(gcamp_stat),...
        'face_color',[0 1 0]);
    
    
    limits1=ylim();
    edge=max(abs(limits1));
    limits1=[-edge edge];
%     ylim(limits);

    
%     schfigure.sparsify_axis(gca,[],[],[-2 0 3],[limits(1) 0 limits(2)]);
%     schfigure.outify_axis;
%     
    ax(end+1)=subplot(max(row),max(col)*2,offset+2);
    schfigure.plot_trace_with_ci(tvec,zrcamp_dt(rcamp_stitch_dt'),zrcamp_dt(rcamp_stat_dt),...
        'face_color',[1 0 0]);
    schfigure.plot_trace_with_ci(tvec,zgcamp_dt(gcamp_stitch_dt'),zgcamp_dt(gcamp_stat_dt),...
        'face_color',[0 1 0]);
    
    limits2=ylim();
    edge=max(abs(limits2));
    limits2=[-edge edge];    
    
    edge_all=max(abs([limits1(:);limits2(:)]));
    limits_all=[-edge_all edge_all];
    
    
    set(ax(end-1:end),'ylim',limits_all)         
    schfigure.sparsify_axis(ax(end),[],[],[-2 0 3],[limits_all(1) 0 limits_all(2)]);
    schfigure.sparsify_axis(ax(end-1),[],[],[-2 0 3],[limits_all(1) 0 limits_all(2)]);
    
    %set(ax(end),'ytick',[]);

    if row(i)<max(row)
        set(ax(end-1:end),'xtick',[]);
    end
    
    
end

schfigure.outify_axis;
linkaxes(ax,'x');
xlim([-2 3]);
%set(ax,'xtick',[-2 0 3]);


