%%
%
%
%
%
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

if ~exist('model_scalars','var')
    model_scalars=phan.slice_syllables_scalars;
end

beh=phan.behavior;


%%

% take a subset of syllables, let's plot the averages according to the
% properties of the sequence they're embedded in:
%
%
% 1) try first sorting by OUTGOING syllable (so onset of syllable sorted by
% where it's going)
%
% 2) we can try ingoing but remember that the Ca2+ activity likely reflects
% kinematics of that syllable, so highly confounded

cutoff=phan.options.syllable_cutoff;

% maybe group the high and low probs?

low_prob=cell(1,length(cutoff));
high_prob=cell(1,length(cutoff));

% sum up all the transition matrices...

beh.get_transition_matrix;
% [trigrams,counts]=beh.get_ngram(3);

trans_to_p=@(x,dim) bsxfun(@rdivide,x,sum(x,dim));
grps={phan.session(:).group};
%all_trans=cat(3,beh(contains(grps,'ctrl')).transition_matrix);
all_trans=cat(3,beh(:).transition_matrix);
all_trans=sum(all_trans,3);
%all_trans=all_trans(1:cutoff,1:cutoff);

all_trans_p_out=trans_to_p(all_trans+1,2);
all_trans_p_in=trans_to_p(all_trans+1,1);


%%


rcamp_sessions=[model_starts.rcamp(1,:).session_idx];
gcamp_sessions=[model_starts.gcamp(1,:).session_idx];

intersession=intersect(unique(rcamp_sessions),unique(gcamp_sessions));
%intersession(~contains(grps(intersession),'ctrl'))=[];

use_gcamp=ismember(gcamp_sessions,intersession);
use_rcamp=ismember(rcamp_sessions,intersession);

peaks=struct();

% we're potentially seeing an effect using a win of 2 3

win=[10 10];
win_smps=round(win.*phan.options.fs);

win_scalars=[2 3];
win_smps_scalars=round(win_scalars.*phan.options.fs);

max_lag=phan.options.max_lag;
max_lag_scalars=phan.options.max_lag_scalars;

upd=kinect_extract.proc_timer(cutoff);

hi_cutoff=50;
lo_cutoff=50;
hi_cutoff_vel=50;
lo_cutoff_vel=50;

for i=1:cutoff
    
    tmp_next=cat(1,model_starts.rcamp(i,use_rcamp).next_label);
    tmp_prev=cat(1,model_starts.rcamp(i,use_rcamp).prev_label);
   
    tmp_rcamp=phanalysis.nanzscore([model_starts.rcamp(i,use_rcamp).wins]);
    tmp_gcamp=phanalysis.nanzscore([model_starts.gcamp(i,use_gcamp).wins]);
   
    session_idx=cat(1,model_starts.rcamp(i,use_rcamp).session_idx);
   
    tmp_vel=([model_scalars(i,session_idx).velocity_mag_3d]);
    
    %bad_idx=(tmp_next<=0|tmp_prev<=0)|(tmp_next>cutoff|tmp_prev>cutoff);
    bad_idx=(tmp_next<=0|tmp_prev<=0);
    
    tmp_rcamp(:,bad_idx)=[];
    tmp_gcamp(:,bad_idx)=[];
    tmp_vel(:,bad_idx)=[];
    tmp_next(bad_idx)=[];
    tmp_prev(bad_idx)=[];
    
    % high or low?
    
    trans_row=all_trans_p_out(i,:);
    
    trans_col=all_trans_p_in(:,i);
  
    window_next_trans_p=trans_row(tmp_next);
    window_prev_trans_p=trans_col(tmp_prev);
    
    p_hi_cutoff_prev=prctile(window_prev_trans_p,hi_cutoff);
    p_lo_cutoff_prev=prctile(window_prev_trans_p,lo_cutoff); 
    
    p_hi_cutoff_next=prctile(window_next_trans_p,hi_cutoff);
    p_lo_cutoff_next=prctile(window_next_trans_p,lo_cutoff); 
    
    vel_mu=nanmean(tmp_vel(max_lag_scalars-10:max_lag_scalars,:));
    vel_lo_cutoff=prctile(vel_mu,lo_cutoff_vel);
    vel_hi_cutoff=prctile(vel_mu,hi_cutoff_vel);
    
    window_hi=struct();
    window_lo=struct();
    
    window_hi.both=(window_prev_trans_p(:)>p_hi_cutoff_prev&window_next_trans_p(:)>p_hi_cutoff_next);
    window_lo.both=(window_prev_trans_p(:)<=p_lo_cutoff_prev&window_next_trans_p(:)<=p_lo_cutoff_next);
    
    window_hi.prev=(window_prev_trans_p(:)>p_hi_cutoff_prev);
    window_lo.prev=(window_prev_trans_p(:)<=p_lo_cutoff_prev);
    
    window_hi.next=(window_next_trans_p(:)>p_hi_cutoff_next);
    window_lo.next=(window_next_trans_p(:)<=p_lo_cutoff_next);
    
    window_hi.vel_lo_both=(vel_mu(:)<=vel_lo_cutoff)&window_hi.both;
    window_lo.vel_lo_both=(vel_mu(:)<=vel_lo_cutoff)&window_lo.both;
    
    window_hi.vel_hi_both=(vel_mu(:)>vel_hi_cutoff)&window_hi.both;
    window_lo.vel_hi_both=(vel_mu(:)>vel_hi_cutoff)&window_lo.both;
    
    window_hi.vel_lo_prev=(vel_mu(:)<=vel_lo_cutoff)&window_hi.prev;
    window_lo.vel_lo_prev=(vel_mu(:)<=vel_lo_cutoff)&window_lo.prev;
    
    window_hi.vel_hi_prev=(vel_mu(:)>vel_hi_cutoff)&window_hi.prev;
    window_lo.vel_hi_prev=(vel_mu(:)>vel_hi_cutoff)&window_lo.prev;
    
    use_names=fieldnames(window_hi);
    
    % use balanced trials
    
    for j=1:length(use_names)
        
        window_lo.(use_names{j})=find(window_lo.(use_names{j}));
        window_hi.(use_names{j})=find(window_hi.(use_names{j}));

        use_trials=min(length(window_hi.(use_names{j})),length(window_lo.(use_names{j})));

        window_hi.(use_names{j})=window_hi.(use_names{j})(1:use_trials);
        window_lo.(use_names{j})=window_lo.(use_names{j})(1:use_trials);

        peaks(i).(sprintf('gcamp_hi_%s',use_names{j}))=(tmp_gcamp(max_lag-win_smps(1):max_lag+win_smps(2),window_hi.(use_names{j})));
        peaks(i).(sprintf('gcamp_lo_%s',use_names{j}))=(tmp_gcamp(max_lag-win_smps(1):max_lag+win_smps(2),window_lo.(use_names{j})));

        peaks(i).(sprintf('rcamp_hi_%s',use_names{j}))=(tmp_rcamp(max_lag-win_smps(1):max_lag+win_smps(2),window_hi.(use_names{j})));
        peaks(i).(sprintf('rcamp_lo_%s',use_names{j}))=(tmp_rcamp(max_lag-win_smps(1):max_lag+win_smps(2),window_lo.(use_names{j})));
        
        peaks(i).(sprintf('vel_hi_%s',use_names{j}))=(tmp_vel(max_lag_scalars-win_smps_scalars(1):max_lag_scalars+win_smps_scalars(2),window_hi.(use_names{j})));
        peaks(i).(sprintf('vel_lo_%s',use_names{j}))=(tmp_vel(max_lag_scalars-win_smps_scalars(1):max_lag_scalars+win_smps_scalars(2),window_lo.(use_names{j})));
             
    end
    
 
    upd(i);
end




%%

% run statistical tests...easy peazy
use_fields={'both','prev','vel_lo_both','vel_lo_prev','vel_hi_both','vel_hi_prev'};

rcamp_shuffle_hi_mu=struct();
gcamp_shuffle_hi_mu=struct();
rcamp_shuffle_lo_mu=struct();
gcamp_shuffle_lo_mu=struct();
nshuffles=phan.user_data.nshuffles;

for i=1:length(use_fields)
    
    fprintf('Randomizing %s\n',use_fields{i});
    
    gcamp_lo=cat(2,peaks(:).(sprintf('gcamp_lo_%s',use_fields{i})));
    gcamp_hi=cat(2,peaks(:).(sprintf('gcamp_hi_%s',use_fields{i})));
    
    gcamp_shuffle_hi_mu.(use_fields{i})=phanalysis.shuffle_statistic(@nanmean,gcamp_hi',nshuffles,false);
    gcamp_shuffle_lo_mu.(use_fields{i})=phanalysis.shuffle_statistic(@nanmean,gcamp_lo',nshuffles,false);
%     gcamp_shuffle_hi_sig.(use_fields{i})=phanalysis.shuffle_statistic(@nanstd,gcamp_hi',nshuffles,false);
%     gcamp_shuffle_lo_sig.(use_fields{i})=phanalysis.shuffle_statistic(@nanstd,gcamp_lo',nshuffles,false);   
    
    rcamp_lo=cat(2,peaks(:).(sprintf('rcamp_lo_%s',use_fields{i})));
    rcamp_hi=cat(2,peaks(:).(sprintf('rcamp_hi_%s',use_fields{i})));

    rcamp_shuffle_hi_mu.(use_fields{i})=phanalysis.shuffle_statistic(@nanmean,rcamp_hi',nshuffles,false);
    rcamp_shuffle_lo_mu.(use_fields{i})=phanalysis.shuffle_statistic(@nanmean,rcamp_lo',nshuffles,false);
%     rcamp_shuffle_hi_sig.(use_fields{i})=phanalysis.shuffle_statistic(@nanstd,rcamp_hi',nshuffles,false);
%     rcamp_shuffle_lo_sig.(use_fields{i})=phanalysis.shuffle_statistic(@nanstd,rcamp_lo',nshuffles,false);  
    
end

%

%
use_fields={'both','prev','vel_lo_both','vel_lo_prev','vel_hi_both','vel_hi_prev'};

rcamp_shufflecat_hi_mu=struct();
gcamp_shufflecat_hi_mu=struct();
rcamp_shufflecat_lo_mu=struct();
gcamp_shufflecat_lo_mu=struct();
nshuffles=phan.user_data.nshuffles;

% shuffle categories instead of time, should be WAY faster

for i=1:length(use_fields)
    
    fprintf('Randomizing %s\n',use_fields{i});
    
    gcamp_lo=cat(2,peaks(:).(sprintf('gcamp_lo_%s',use_fields{i})));
    gcamp_hi=cat(2,peaks(:).(sprintf('gcamp_hi_%s',use_fields{i})));
     
    gcamp_all=[gcamp_lo gcamp_hi];
    trials=size(gcamp_all,2);
    trials_lo=size(gcamp_lo,2);
    trials_hi=size(gcamp_hi,2);
    
    [~,idx]=sort(randi(trials,[trials nshuffles]));

    upd=kinect_extract.proc_timer(nshuffles);
    
    for j=1:nshuffles
        gcamp_rnd_lo=gcamp_all(:,idx(1:trials_lo,j));
        gcamp_rnd_hi=gcamp_all(:,idx(trials_lo+1:end,j));
        gcamp_shufflecat_hi_mu.(use_fields{i})(:,j)=nanmean(gcamp_rnd_hi');
        gcamp_shufflecat_lo_mu.(use_fields{i})(:,j)=nanmean(gcamp_rnd_lo');
        upd(j);
    end
        
    rcamp_lo=cat(2,peaks(:).(sprintf('rcamp_lo_%s',use_fields{i})));
    rcamp_hi=cat(2,peaks(:).(sprintf('rcamp_hi_%s',use_fields{i})));
    
    rcamp_all=[rcamp_lo rcamp_hi];
    trials=size(rcamp_all,2);
    trials_lo=size(rcamp_lo,2);
    trials_hi=size(rcamp_hi,2);
      
    upd=kinect_extract.proc_timer(nshuffles);

    for j=1:nshuffles
        rcamp_rnd_lo=rcamp_all(:,idx(1:trials_lo,j));
        rcamp_rnd_hi=rcamp_all(:,idx(trials_lo+1:end,j));
        rcamp_shufflecat_hi_mu.(use_fields{i})(:,j)=nanmean(rcamp_rnd_hi');
        rcamp_shufflecat_lo_mu.(use_fields{i})(:,j)=nanmean(rcamp_rnd_lo');
        upd(j);
    end
        
end


%%

% check for statistical significance

use_fields={'both','prev','vel_lo_both','vel_lo_prev','vel_hi_both','vel_hi_prev'};
use_win=win_smps(1)-0:win_smps(1)+11;

for i=1:length(use_fields)

    gcamp_lo=cat(2,peaks(:).(sprintf('gcamp_lo_%s',use_fields{i})));
    gcamp_hi=cat(2,peaks(:).(sprintf('gcamp_hi_%s',use_fields{i})));
    
    gcamp_lo_mu=nanmean(gcamp_lo');
    gcamp_hi_mu=nanmean(gcamp_hi');
           
    rcamp_lo=cat(2,peaks(:).(sprintf('rcamp_lo_%s',use_fields{i})));
    rcamp_hi=cat(2,peaks(:).(sprintf('rcamp_hi_%s',use_fields{i})));
    
    rcamp_lo_mu=nanmean(rcamp_lo');
    rcamp_hi_mu=nanmean(rcamp_hi');
    
    tmp1=mean(abs(rcamp_shuffle_hi_mu.(use_fields{i})(use_win,:)-rcamp_shuffle_lo_mu.(use_fields{i})(use_win,:)));
    tmp2=mean(abs(rcamp_shufflecat_hi_mu.(use_fields{i})(use_win,:)-rcamp_shufflecat_lo_mu.(use_fields{i})(use_win,:)));
    tmp3=mean(abs(rcamp_lo_mu(use_win)-rcamp_hi_mu(use_win)));
    
    sum(tmp1>=tmp3)
    sum(tmp2>=tmp3)
    
    tmp1=mean(abs(gcamp_shuffle_hi_mu.(use_fields{i})(use_win,:)-gcamp_shuffle_lo_mu.(use_fields{i})(use_win,:)));
    tmp2=mean(abs(gcamp_shufflecat_hi_mu.(use_fields{i})(use_win,:)-gcamp_shufflecat_lo_mu.(use_fields{i})(use_win,:)));
    tmp3=mean(abs(gcamp_lo_mu(use_win)-gcamp_hi_mu(use_win)));
    
    sum(tmp1>=tmp3)
    sum(tmp2>=tmp3)
end


%%

use_fields={'both','prev'};
if exist('seq_plot','var')
    clear seq_plot;
end

seq_plot=schfigure();
seq_plot.name='sequence_prob_averages_zscore';
seq_plot.dims='2x3';
nboots=1000;

win=[10 10];
win_smps=round(win.*phan.options.fs);
win_scalars=[2 3];
win_smps_scalars=round(win_scalars.*phan.options.fs);
tvec=[-win_smps:win_smps]/phan.options.fs;

ax=[];
opts=statset('UseParallel',true);

for i=1:length(use_fields)
    
    rcamp_shuf_lo_mu=nanmean(rcamp_shuffle_lo_mu.(use_fields{i})');
    rcamp_shuf_lo_sig=nanstd(rcamp_shuffle_lo_mu.(use_fields{i})');
    rcamp_shuf_hi_mu=nanmean(rcamp_shuffle_hi_mu.(use_fields{i})');
    rcamp_shuf_hi_sig=nanstd(rcamp_shuffle_hi_mu.(use_fields{i})');
    
    gcamp_shuf_lo_mu=nanmean(gcamp_shuffle_lo_mu.(use_fields{i})');
    gcamp_shuf_lo_sig=nanstd(gcamp_shuffle_lo_mu.(use_fields{i})');
    gcamp_shuf_hi_mu=nanmean(gcamp_shuffle_hi_mu.(use_fields{i})');
    gcamp_shuf_hi_sig=nanstd(gcamp_shuffle_hi_mu.(use_fields{i})');
    
    zgcamp_lo=@(x) (x-mean(gcamp_shuf_lo_mu))./max(gcamp_shuf_lo_sig);
    zgcamp_hi=@(x) (x-mean(gcamp_shuf_hi_mu))./max(gcamp_shuf_hi_sig);

    zrcamp_lo=@(x) (x-mean(rcamp_shuf_lo_mu))./max(rcamp_shuf_lo_sig);
    zrcamp_hi=@(x) (x-mean(rcamp_shuf_hi_mu))./max(rcamp_shuf_hi_sig);
       
    rcamp_lo=cat(2,peaks(:).(sprintf('rcamp_lo_%s',use_fields{i})));
    rcamp_hi=cat(2,peaks(:).(sprintf('rcamp_hi_%s',use_fields{i})));
    
    rcamp_lo_mu=nanmean(rcamp_lo');
    rcamp_hi_mu=nanmean(rcamp_hi');
    
    rcamp_lo_boots=bootstrp(nboots,@nanmean,rcamp_lo','options',opts);
    rcamp_hi_boots=bootstrp(nboots,@nanmean,rcamp_hi','options',opts);
    
    rcamp_lo_sem=nanstd(rcamp_lo_boots);
    rcamp_hi_sem=nanstd(rcamp_hi_boots);
    
    rcamp_lo_ci=[rcamp_lo_mu-rcamp_lo_sem;rcamp_lo_mu+rcamp_lo_sem];
    rcamp_hi_ci=[rcamp_hi_mu-rcamp_hi_sem;rcamp_hi_mu+rcamp_hi_sem];
    
    ax(end+1)=subplot(length(use_fields),2,(i-1)*2+1);
    
    h=[];
    h(1)=schfigure.shaded_errorbar(tvec,zrcamp_lo(rcamp_lo_ci),[1 0 0],'none');
    hold on;
    plot(tvec,zrcamp_lo(rcamp_lo_mu),'k-');
    h(2)=schfigure.shaded_errorbar(tvec,zrcamp_hi(rcamp_hi_ci),[1 0 1],'none');
    plot(tvec,zrcamp_hi(rcamp_hi_mu),'k-');
    plot([0 0],[-20 20],'k--');

    text(0,.05,regexprep(sprintf('P(%s)',use_fields{i}),'_',' '));
    
    gcamp_lo=cat(2,peaks(:).(sprintf('gcamp_lo_%s',use_fields{i})));
    gcamp_hi=cat(2,peaks(:).(sprintf('gcamp_hi_%s',use_fields{i})));
    
    gcamp_lo_mu=nanmean(gcamp_lo');
    gcamp_hi_mu=nanmean(gcamp_hi');
    
    gcamp_lo_boots=bootstrp(nboots,@nanmean,gcamp_lo','options',opts);
    gcamp_hi_boots=bootstrp(nboots,@nanmean,gcamp_hi','options',opts);
    
    gcamp_lo_sem=nanstd(gcamp_lo_boots);
    gcamp_hi_sem=nanstd(gcamp_hi_boots);
    
    gcamp_lo_ci=[gcamp_lo_mu-gcamp_lo_sem;gcamp_lo_mu+gcamp_lo_sem];
    gcamp_hi_ci=[gcamp_hi_mu-gcamp_hi_sem;gcamp_hi_mu+gcamp_hi_sem];
    
    ax(end+1)=subplot(length(use_fields),2,(i-1)*2+2);
    
    h=[];
    h(1)=schfigure.shaded_errorbar(tvec,zgcamp_lo(gcamp_lo_ci),[0 1 0],'none');
    hold on;
    plot(tvec,zgcamp_lo(gcamp_lo_mu),'k-');    
    h(2)=schfigure.shaded_errorbar(tvec,zgcamp_hi(gcamp_hi_ci),[0 1 1],'none');
    plot(tvec,zgcamp_hi(gcamp_hi_mu),'k-');
    plot([0 0],[-20 20],'k--');

    
%     L=legend(h,{sprintf('P<=%g',lo_cutoff),sprintf('P>%g',hi_cutoff)});
%     set(L,'box','off','FontSize',8);
%     
    schfigure.outify_axis;

    if i==length(use_fields)
        xlabel('Time (s)');
    end
   
    
end

linkaxes(ax,'xy');
xlim([-2 3]);
ylim([-20 20]);
schfigure.sparsify_axis([],[],[],[-2 0 3],[-20 0 20])
set(ax(1:end-2),'xtick',[]);
set(ax(2:2:end),'ytick',[]);
set(ax,'FontSize',8);

%% '

use_fields={'vel_lo_both','vel_lo_prev','vel_hi_both','vel_hi_prev'};

seq_plot(2)=schfigure();
seq_plot(2).name='sequence_prob_averages_velstratify_zscore';
seq_plot(2).dims='8x3';
tvec=[-win_smps(1):win_smps(2)]/phan.options.fs;
tvec_scalars=[-win_smps_scalars(1):win_smps_scalars(2)]/phan.options.fs;
ax=[];
opts=statset('UseParallel',true);
plt_counter=1;


for i=1:length(use_fields)
      
    vel_lo=cat(2,peaks(:).(sprintf('vel_lo_%s',use_fields{i})));
    vel_hi=cat(2,peaks(:).(sprintf('vel_hi_%s',use_fields{i})));    
    
    vel_lo_mu=nanmean(vel_lo');
    vel_hi_mu=nanmean(vel_hi');
    
    vel_lo_boots=bootstrp(nboots,@nanmean,vel_lo','options',opts);
    vel_hi_boots=bootstrp(nboots,@nanmean,vel_hi','options',opts);
    
    vel_lo_sem=nanstd(vel_lo_boots)*1.96;
    vel_hi_sem=nanstd(vel_hi_boots)*1.96;
    
    vel_lo_ci=[vel_lo_mu-vel_lo_sem;vel_lo_mu+vel_lo_sem];
    vel_hi_ci=[vel_hi_mu-vel_hi_sem;vel_hi_mu+vel_hi_sem];
    
    ax(end+1)=subplot(2,3*length(use_fields)/2,plt_counter);
    plt_counter=plt_counter+1;
    
    h=[];
    h(1)=schfigure.shaded_errorbar(tvec_scalars,vel_lo_ci,[0 0 1],'none');
    hold on;
    plot(tvec_scalars,vel_lo_mu,'k-');    
    h(2)=schfigure.shaded_errorbar(tvec_scalars,vel_hi_ci,[1 0 1],'none');
    plot(tvec_scalars,vel_hi_mu,'k-');
    plot([0 0],[0 4],'k--');

    rcamp_lo=cat(2,peaks(:).(sprintf('rcamp_lo_%s',use_fields{i})));
    rcamp_hi=cat(2,peaks(:).(sprintf('rcamp_hi_%s',use_fields{i})));
    
    rcamp_lo_mu=nanmean(rcamp_lo');
    rcamp_hi_mu=nanmean(rcamp_hi');
    
    rcamp_shuf_lo_mu=nanmean(rcamp_shuffle_lo_mu.(use_fields{i})');
    rcamp_shuf_lo_sig=nanstd(rcamp_shuffle_lo_mu.(use_fields{i})');
    rcamp_shuf_hi_mu=nanmean(rcamp_shuffle_hi_mu.(use_fields{i})');
    rcamp_shuf_hi_sig=nanstd(rcamp_shuffle_hi_mu.(use_fields{i})');
    
    gcamp_shuf_lo_mu=nanmean(gcamp_shuffle_lo_mu.(use_fields{i})');
    gcamp_shuf_lo_sig=nanstd(gcamp_shuffle_lo_mu.(use_fields{i})');
    gcamp_shuf_hi_mu=nanmean(gcamp_shuffle_hi_mu.(use_fields{i})');
    gcamp_shuf_hi_sig=nanstd(gcamp_shuffle_hi_mu.(use_fields{i})');
    
    zgcamp_lo=@(x) (x-mean(gcamp_shuf_lo_mu))./max(gcamp_shuf_lo_sig);
    zgcamp_hi=@(x) (x-mean(gcamp_shuf_hi_mu))./max(gcamp_shuf_hi_sig);

    zrcamp_lo=@(x) (x-mean(rcamp_shuf_lo_mu))./max(rcamp_shuf_lo_sig);
    zrcamp_hi=@(x) (x-mean(rcamp_shuf_hi_mu))./max(rcamp_shuf_hi_sig);

    rcamp_lo_boots=bootstrp(nboots,@nanmean,rcamp_lo','options',opts);
    rcamp_hi_boots=bootstrp(nboots,@nanmean,rcamp_hi','options',opts);
    
    rcamp_lo_sem=nanstd(rcamp_lo_boots);
    rcamp_hi_sem=nanstd(rcamp_hi_boots);
    
    rcamp_lo_ci=[rcamp_lo_mu-rcamp_lo_sem;rcamp_lo_mu+rcamp_lo_sem];
    rcamp_hi_ci=[rcamp_hi_mu-rcamp_hi_sem;rcamp_hi_mu+rcamp_hi_sem];
    
    ax(end+1)=subplot(2,3*length(use_fields)/2,plt_counter);
    plt_counter=plt_counter+1;    
    
    h=[];
    h(1)=schfigure.shaded_errorbar(tvec,zrcamp_lo(rcamp_lo_ci),[1 0 0],'none');
    hold on;
    plot(tvec,zrcamp_lo(rcamp_lo_mu),'k-');
    h(2)=schfigure.shaded_errorbar(tvec,zrcamp_hi(rcamp_hi_ci),[1 0 1],'none');
    plot(tvec,zrcamp_hi(rcamp_hi_mu),'k-');
    plot([0 0],[-20 20],'k--');

    text(0,.05,regexprep(sprintf('P(%s)',use_fields{i}),'_',' '));
    
    gcamp_lo=cat(2,peaks(:).(sprintf('gcamp_lo_%s',use_fields{i})));
    gcamp_hi=cat(2,peaks(:).(sprintf('gcamp_hi_%s',use_fields{i})));
    
    gcamp_lo_mu=nanmean(gcamp_lo');
    gcamp_hi_mu=nanmean(gcamp_hi');
    
    
    gcamp_lo_boots=bootstrp(nboots,@nanmean,gcamp_lo','options',opts);
    gcamp_hi_boots=bootstrp(nboots,@nanmean,gcamp_hi','options',opts);
    
    gcamp_lo_sem=nanstd(gcamp_lo_boots);
    gcamp_hi_sem=nanstd(gcamp_hi_boots);
    
    gcamp_lo_ci=[gcamp_lo_mu-gcamp_lo_sem;gcamp_lo_mu+gcamp_lo_sem];
    gcamp_hi_ci=[gcamp_hi_mu-gcamp_hi_sem;gcamp_hi_mu+gcamp_hi_sem];
    
    ax(end+1)=subplot(2,3*length(use_fields)/2,plt_counter);
    plt_counter=plt_counter+1;
    
    h=[];
    h(1)=schfigure.shaded_errorbar(tvec,zgcamp_lo(gcamp_lo_ci),[0 1 0],'none');
    hold on;
    plot(tvec,zgcamp_lo(gcamp_lo_mu),'k-');    
    h(2)=schfigure.shaded_errorbar(tvec,zgcamp_hi(gcamp_hi_ci),[0 1 1],'none');
    plot(tvec,zgcamp_hi(gcamp_hi_mu),'k-');
    plot([0 0],[-20 20],'k--');

    
%     L=legend(h,{sprintf('P<=%g',lo_cutoff),sprintf('P>%g',hi_cutoff)});
%     set(L,'box','off','FontSize',8);
%     
    schfigure.outify_axis;

    if i==length(use_fields)
        xlabel('Time (s)');
    end
   
    
end

fluo_plots=[2 3 5 6 8 9 11 12];
vel_plots=[1 4 7 10];

linkaxes(ax,'x');
xlim([-2 3]);
%linkaxes(ax([2 3 5 6]));
set(ax(fluo_plots),'ylim',[-20 20]);
set(ax(fluo_plots),'ytick',[-20 0 20]);
set(ax(vel_plots),'ylim',[0 3],'ytick',[0 3]);
set(ax,'xtick',[-2 0 3]);

% %ylim([-.1 .1]);
% schfigure.sparsify_axis([],[],'x',[-2 0 3])
% schfigure.sparsify_axis([],[],'y');
set(ax(1:end-6),'xtick',[]);
set(ax,'FontSize',8);


%%
use_fields={'both','prev'};
if exist('seq_plot','var')
    clear seq_plot;
end


sylls = [ 2    3    6    5 ];
% sylls=2;

if exist('seq_plot','var')
    clear seq_plot;
end

seq_plot=schfigure();
seq_plot.name='sequence_prob_examples_zscore';
seq_plot.dims='8x3';
nboots=1000;
nshuffles=1000;

win=[10 10];
win_smps=round(win.*phan.options.fs);
win_scalars=[2 3];
win_smps_scalars=round(win_scalars.*phan.options.fs);tvec=[-win_smps(1):win_smps(2)]/phan.options.fs;

ax=[];
opts=statset('UseParallel',true);
plot_counter=1;
plot_counter2=length(sylls)*2+1;

for ii=1:length(sylls)
    for i=1:length(use_fields)
                
        rcamp_lo=cat(2,peaks(sylls(ii)).(sprintf('rcamp_lo_%s',use_fields{i})));
        rcamp_hi=cat(2,peaks(sylls(ii)).(sprintf('rcamp_hi_%s',use_fields{i})));
        
        rcamp_lo_shuffles=phanalysis.shuffle_statistic(@nanmean,rcamp_lo',nshuffles,false);
        rcamp_hi_shuffles=phanalysis.shuffle_statistic(@nanmean,rcamp_hi',nshuffles,false);
        
        rcamp_shuf_lo_mu=nanmean(rcamp_lo_shuffles');
        rcamp_shuf_hi_mu=nanmean(rcamp_hi_shuffles');
        
        rcamp_shuf_lo_sig=nanstd(rcamp_lo_shuffles');
        rcamp_shuf_hi_sig=nanstd(rcamp_hi_shuffles');
        
        zrcamp_lo=@(x) (x-mean(rcamp_shuf_lo_mu))./max(rcamp_shuf_lo_sig);
        zrcamp_hi=@(x) (x-mean(rcamp_shuf_hi_mu))./max(rcamp_shuf_hi_sig);
              
        rcamp_lo_boots=bootstrp(nboots,@nanmean,rcamp_lo','options',opts);
        rcamp_hi_boots=bootstrp(nboots,@nanmean,rcamp_hi','options',opts);
        
        ax(end+1)=subplot(length(use_fields),length(sylls)*2,(ii-1)*2+(i-1)*length(sylls)*2+1);
        plot_counter=plot_counter+1;
        
        schfigure.plot_trace_with_ci(tvec,zrcamp_lo(rcamp_lo'),zrcamp_lo(rcamp_lo_boots),...
            'face_color',[1 0 0]);
        schfigure.plot_trace_with_ci(tvec,zrcamp_hi(rcamp_hi'),zrcamp_hi(rcamp_hi_boots),...
            'face_color',[1 0 1]);
        
        plot([0 0],[-20 20],'k--');
        
        %title(regexprep(sprintf('P(%s)',use_fields{i}),'_',' '));
        
        gcamp_lo=cat(2,peaks(sylls(ii)).(sprintf('gcamp_lo_%s',use_fields{i})));
        gcamp_hi=cat(2,peaks(sylls(ii)).(sprintf('gcamp_hi_%s',use_fields{i})));
        
        gcamp_lo_shuffles=phanalysis.shuffle_statistic(@nanmean,gcamp_lo',nshuffles,false);
        gcamp_hi_shuffles=phanalysis.shuffle_statistic(@nanmean,gcamp_hi',nshuffles,false);
        
        gcamp_shuf_lo_mu=nanmean(gcamp_lo_shuffles');
        gcamp_shuf_hi_mu=nanmean(gcamp_hi_shuffles');
        
        gcamp_shuf_lo_sig=nanstd(gcamp_lo_shuffles');
        gcamp_shuf_hi_sig=nanstd(gcamp_hi_shuffles');
        
        zgcamp_lo=@(x) (x-mean(gcamp_shuf_lo_mu))./max(gcamp_shuf_lo_sig);
        zgcamp_hi=@(x) (x-mean(gcamp_shuf_hi_mu))./max(gcamp_shuf_hi_sig);
        
        gcamp_lo_boots=bootstrp(nboots,@nanmean,gcamp_lo','options',opts);
        gcamp_hi_boots=bootstrp(nboots,@nanmean,gcamp_hi','options',opts);
                        
        ax(end+1)=subplot(length(use_fields),length(sylls)*2,(ii-1)*2+(i-1)*length(sylls)*2+2);
        
        schfigure.plot_trace_with_ci(tvec,zgcamp_lo(gcamp_lo'),zgcamp_lo(gcamp_lo_boots),...
            'face_color',[0 1 0]);
        schfigure.plot_trace_with_ci(tvec,zgcamp_hi(gcamp_hi'),zgcamp_hi(gcamp_hi_boots),...
            'face_color',[0 1 1]);              

        plot([0 0],[-20 20],'k--');

        schfigure.outify_axis;
        
        if i==length(use_fields)
            xlabel('Time (s)');
        end
        
        
    end
end

linkaxes(ax,'xy');
ylim([-20 20]);
xlim([-2 3]);
set(ax,'xtick',[-2 0 3]);
set(ax(1:2:end),'xtick',[]);
% set(ax(2:length(sylls)*2),'ytick',[]);
% set(ax(length(sylls)*2+2:end),'ytick',[]);
set(ax,'FontSize',8);