
%%

if ~exist('phan','var')
    load('~/Desktop/workspace/1pimaging_dls/_analysis/phanalysis_object.mat');
    phan=phanalysis_object;
end


if ~exist('model_starts','var')
    model_starts=phan.slice_syllables_neural;    
end

% if ~exist('model_scalars','var')
%     model_scalars=phan.slice_syllables_scalars;
% end
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

beh=phan.behavior;
beh.get_transition_matrix;
cutoff=phan.options.syllable_cutoff;

% maybe group the high and low probs?

low_prob=cell(1,length(cutoff));
high_prob=cell(1,length(cutoff));

% sum up all the transition matrices...

%beh.get_transition_matrix;

trans_to_p=@(x,dim) bsxfun(@rdivide,x,sum(x,dim));

all_trans=cat(3,beh(:).transition_matrix);
all_trans=sum(all_trans,3);
%all_trans=all_trans(1:cutoff,1:cutoff);

all_trans_p_out=trans_to_p(all_trans+1,2);
all_trans_p_in=trans_to_p(all_trans+1,1);

%%


peaks=struct();

% we're potentially seeing an effect using a win of 2 3

nrands=1000;
win=[2 3];
win_smps=round(win.*phan.options.fs);

max_lag=phan.options.max_lag;
max_lag_scalars=phan.options.max_lag_scalars;
diff_idx=max_lag:max_lag+11;

hi_cutoff=50;
lo_cutoff=50;
hi_cutoff_vel=50;
lo_cutoff_vel=50;
mouse_groups={phan.session(:).group};
use_mice=1:length(phan.session);

peaks=struct();

counter=1;
cutoff=phan.options.syllable_cutoff;
upd=kinect_extract.proc_timer(cutoff);

% collect response for each roi, then aggregate

for i=1:cutoff
    for ii=1:length(use_mice)
        
        tmp_data=phanalysis.nanzscore([model_starts.imaging(i,use_mice(ii)).wins]);
        tmp_durs=[model_starts.imaging(i,use_mice(ii)).durations];
        tmp_group=mouse_groups{use_mice(ii)};
        
        tmp_next=cat(1,model_starts.imaging(i,use_mice(ii)).next_label);
        tmp_prev=cat(1,model_starts.imaging(i,use_mice(ii)).prev_label);
        
        session_idx=cat(1,model_starts.imaging(i,use_mice(ii)).session_idx);
        % tmp_vel=([model_scalars(i,session_idx).velocity_mag_3d]);
        
        trans_row=all_trans_p_out(i,:);
        trans_col=all_trans_p_in(:,i);
        
        bad_idx=(tmp_next<=0|tmp_prev<=0);
        
        tmp_data(:,bad_idx)=[];
        % tmp_vel(:,bad_idx)=[];
        tmp_next(bad_idx)=[];
        tmp_prev(bad_idx)=[];
        
        ntrials=size(tmp_data,3);
        
        if ntrials<10
            continue;
        end
        
        window_next_trans_p=trans_row(tmp_next);
        window_prev_trans_p=trans_col(tmp_prev);
        
        p_hi_cutoff_prev=prctile(window_prev_trans_p,hi_cutoff);
        p_lo_cutoff_prev=prctile(window_prev_trans_p,lo_cutoff);
        
        p_hi_cutoff_next=prctile(window_next_trans_p,hi_cutoff);
        p_lo_cutoff_next=prctile(window_next_trans_p,lo_cutoff);
        
%         vel_mu=nanmean(tmp_vel(max_lag_scalars-10:max_lag_scalars,:));
%         vel_lo_cutoff=prctile(vel_mu,lo_cutoff_vel);
%         vel_hi_cutoff=prctile(vel_mu,hi_cutoff_vel);
        
        window_hi=struct();
        window_lo=struct();
        
        window_hi.both=(window_prev_trans_p(:)>p_hi_cutoff_prev&window_next_trans_p(:)>p_hi_cutoff_next);
        window_lo.both=(window_prev_trans_p(:)<=p_lo_cutoff_prev&window_next_trans_p(:)<=p_lo_cutoff_next);
      
        use_names=fieldnames(window_hi);
        
        for j=1:length(use_names)
            
            window_lo.(use_names{j})=find(window_lo.(use_names{j}));
            window_hi.(use_names{j})=find(window_hi.(use_names{j}));
            
            use_trials=min(length(window_hi.(use_names{j})),length(window_lo.(use_names{j})));
            
            if use_trials<2
                continue;
            end
            
            window_hi.(use_names{j})=window_hi.(use_names{j})(1:use_trials);
            window_lo.(use_names{j})=window_lo.(use_names{j})(1:use_trials);
            
            peaks(ii).(sprintf('imaging_hi_%s',use_names{j})){i}=(tmp_data(diff_idx,:,window_hi.(use_names{j})));
            peaks(ii).(sprintf('imaging_lo_%s',use_names{j})){i}=(tmp_data(diff_idx,:,window_lo.(use_names{j})));
            
            
        end
    end
    
    counter=counter+1;
    
    upd(i);
    
end

%%

mus1=cell(size(peaks));
mus2=cell(size(peaks));
shuffle_diff=[];

zdiff={};
left_pval={};
right_pval={};
shufflediff={};
mudiff={};
shufflediff_raw={};
%diff_idx=max_lag:max_lag+15;
diff_idx=1:length(diff_idx);

upd=kinect_extract.proc_timer(length(peaks));

for i=1:length(peaks)
    
    skip=cellfun(@isempty,peaks(i).imaging_hi_both)|cellfun(@isempty,peaks(i).imaging_lo_both);
    
    mu1_data=cat(3,peaks(i).imaging_hi_both{:});
    mu2_data=cat(3,peaks(i).imaging_lo_both{:});
    
    mu1=nanmean(mu1_data,3);
    mu2=nanmean(mu2_data,3);
    
    % z-score relative to a shuffled control
    nrois=size(mu1,2);
    
    shuffle_diff=nan(nrands,nrois);

    mudiff{i}=nanmean(mu1(diff_idx,:)-mu2(diff_idx,:));
    mus1{i}=nanmean(mu1(diff_idx,:));
    mus2{i}=nanmean(mu2(diff_idx,:));
    merge=cat(3,mu1_data(diff_idx,:,:),mu2_data(diff_idx,:,:));
    npool=size(merge,3);

    for k=1:nrands
        rand_pool=randperm(npool);
        pool1=rand_pool(1:npool/2);
        pool2=rand_pool(npool/2+1:end);
        group1=nanmean(merge(:,:,pool1),3);
        group2=nanmean(merge(:,:,pool2),3);
        shuffle_diff(k,:)=nanmean(group1-group2);
    end
        
    shufflediff{i}=bsxfun(@rdivide,bsxfun(@minus,shuffle_diff,nanmean(shuffle_diff)),nanstd(shuffle_diff));
    shufflediff_raw{i}=shuffle_diff;
    zdiff{i}=(mudiff{i}-nanmean(shuffle_diff))./nanstd(shuffle_diff);

    left_pval{i}=1-mean(repmat(mudiff{i},[nrands 1])<shuffle_diff);
    right_pval{i}=1-mean(repmat(mudiff{i},[nrands 1])>shuffle_diff);
    upd(i);
    
end


%%
% make a histogram and highlight the significant values, call it a day bro

plt_fields={'d1cre','a2acre'};

prob_histos=schfigure();
prob_histos.dims='1.5x3';
prob_histos.name='inscopix_sequence_probs';
prob_histos.formats='png,pdf,fig';
alpha=.05;
bins=[-6:.5:6];

for i=1:length(plt_fields)
    
    use_idx=find(strcmp(mouse_groups,plt_fields{i}));
    
    left_vals=[];
    right_vals=[];
    for j=1:length(use_idx)
        left_vals=[left_vals zdiff{use_idx(j)}(left_pval{use_idx(j)}<alpha)];
        right_vals=[right_vals zdiff{use_idx(j)}(right_pval{use_idx(j)}<alpha)];
    end
    
    stitch=cat(2,zdiff{use_idx});
    stitchshuffle=cat(2,shufflediff{use_idx});
    
    ax(i)=subplot(length(plt_fields),1,i);
    schfigure.stair_histogram(stitch,bins,'normalize',true,'k-');
    hold on;

    schfigure.stair_histogram(stitchshuffle(:),bins,'normalize',true,'k-','color',[.75 .75 .75]);
    schfigure.stair_histogram(left_vals,bins,'fill',true,'facecolor','b','normalize',true,'normalize_denom',length(stitch));
    schfigure.stair_histogram(right_vals,bins,'fill',true,'facecolor','r','normalize',true,'normalize_denom',length(stitch));
    %schfigure.stair_histogram(tmp2(:),bins,'fill',true,'facecolor','k');
    
    box off;
    
    title([plt_fields{i}]);
    
end

xlabel('Modulation index');

linkaxes(ax,'x');
xlim([-6 6]);
schfigure.outify_axis;
schfigure.sparsify_axis([],[],[],[-6 0 6]);

%%


plt_fields={'d1cre','a2acre'};

paired_plot=schfigure();
paired_plot.dims='1.5x3';
paired_plot.name='inscopix_sequence_probs_paired';
paired_plot.formats='png,pdf,fig';
alpha=.05;
counter=1;

for i=1:length(plt_fields)
    
    use_idx=find(strcmp(mouse_groups,plt_fields{i}));
    
    shows1_left=[];
    shows2_left=[];    
    shows1_right=[];
    shows2_right=[];
    
    for j=1:length(use_idx)
        
        right_idx=right_pval{use_idx(j)}<alpha;
        left_idx=left_pval{use_idx(j)}<alpha;
        
        shows1_right=[shows1_right (mus2{use_idx(j)}(:,right_idx))];
        shows2_right=[shows2_right (mus1{use_idx(j)}(:,right_idx))];        
        shows1_left=[shows1_left (mus2{use_idx(j)}(:,left_idx))];
        shows2_left=[shows2_left (mus1{use_idx(j)}(:,left_idx))];             
        
    end
            
    ax(i)=subplot(length(plt_fields),2,counter);
        
    plot([shows1_right;shows2_right],'ko-','markerfacecolor','w','markersize',2.5,'markeredgecolor','r');
    xlim([.5 2.5]);
    box off;
    ylim([-.15 .15]);
    
    schfigure.sparsify_axis(gca);
    schfigure.outify_axis(gca);
    if i<length(plt_fields)
        set(gca,'xtick',[]);
    else
        set(gca,'xtick',[1 2],'xticklabel',{'LoP','HiP'});
        xtickangle(45);               
    end
    
    title([plt_fields{i}]);
    
    
    counter=counter+1;
    ax(i)=subplot(length(plt_fields),2,counter);
    
    plot([shows1_left;shows2_left],'ko-','markerfacecolor','w','markersize',2.5,'markeredgecolor','b');
    counter=counter+1;
    xlim([.5 2.5]);
    box off;
    ylim([-.15 .15]);

    schfigure.sparsify_axis(gca);
    schfigure.outify_axis(gca);
    set(gca,'yticklabel',[])
    if i<length(plt_fields)
        set(gca,'xtick',[]);
    else
        set(gca,'xtick',[1 2],'xticklabel',{'LoP','HiP'});
        xtickangle(45);
    end
    
                
end



%%

plt_fields={'d1cre','a2acre'};
seq_raw_delta=schfigure();
seq_raw_delta.dims='1.5x3';
seq_raw_delta.name='inscopix_sequence_probs_raw_delta';
seq_raw_delta.formats='png,pdf,fig';
alpha=.05;
bins=[-.15:.005:.15];

for i=1:length(plt_fields)
    
    subplot(length(plt_fields),1,i);

    use_idx=strcmp(mouse_groups,plt_fields{i});
    tmp=cat(2,left_pval{use_idx});
    tmp2=cat(2,mudiff{use_idx});
    left_vals=abs(tmp2(tmp<.05));
    sum(tmp<.05)
    schfigure.stair_histogram(left_vals,bins,'normalize',true,'m-','cdf',true);
    hold on;
    
    tmp=cat(2,right_pval{use_idx});
    tmp2=cat(2,mudiff{use_idx});
    right_vals=abs(tmp2(tmp<.05));
    sum(tmp<.05)
    schfigure.stair_histogram(right_vals,bins,'normalize',true,'y-','cdf',true);
    hold on;
    
    xlim([.05 .15]);    
    
    [h,p,ksstat]=kstest2(left_vals,right_vals,'tail','smaller')
    %xlim([0 .125]); 
end

schfigure.sparsify_axis;
schfigure.outify_axis;
ylabel('Cum. prop.');
xlabel('Abs(change z-dF/F0)');

