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

if ~exist('ave_starts','var')
    ave_starts=phan.average_windows(model_starts);
end

%%


ave_starts_norm=struct();

win=[2 3];
win_smps=round(win.*phan.options.fs);
max_lag=phan.options.max_lag;
nshuffles=1000;
syllable_cutoff=phan.options.syllable_cutoff;

fs=phan.options.fs;
smoothing=0;

% tvec=[-max_lag:max_lag]/fs;
tvec=[-win_smps(1):win_smps(2)]/fs;


upd=kinect_extract.proc_timer(syllable_cutoff);

for i=1:phan.options.syllable_cutoff
        
    gcamp_stitch=zscore(cat(2,model_starts.gcamp(i,:).wins));
    rcamp_stitch=zscore(cat(2,model_starts.rcamp(i,:).wins)); 
        
    gcamp_stitch=gcamp_stitch(max_lag-win_smps(1):max_lag+win_smps(2),:);
    rcamp_stitch=rcamp_stitch(max_lag-win_smps(1):max_lag+win_smps(2),:);
    
    gcamp_shuffle=phanalysis.shuffle_statistic(@nanmean,gcamp_stitch',nshuffles,true)';
    rcamp_shuffle=phanalysis.shuffle_statistic(@nanmean,rcamp_stitch',nshuffles,true)';
    
    zgcamp=@(x) (x-mean(nanmean(gcamp_shuffle)))./max(nanstd(gcamp_shuffle));
    zrcamp=@(x) (x-mean(nanmean(rcamp_shuffle)))./max(nanstd(rcamp_shuffle));
    
    ave_starts_norm.gcamp_mu.mu(:,i)=nanmean(zgcamp(gcamp_stitch'));
    ave_starts_norm.rcamp_mu.mu(:,i)=nanmean(zrcamp(rcamp_stitch'));
    
    upd(i);
    
end

%% 
% sort by peak value just before/after 0, yadda yadda

use_field='mu';

cut_mu_rcamp=ave_starts_norm.rcamp_mu.(use_field)(:,1:syllable_cutoff);
cut_mu_gcamp=ave_starts_norm.gcamp_mu.(use_field)(:,1:syllable_cutoff);

plot_mu_rcamp=ave_starts_norm.rcamp_mu.(use_field)(:,1:syllable_cutoff);
plot_mu_gcamp=ave_starts_norm.gcamp_mu.(use_field)(:,1:syllable_cutoff);

if smoothing>0
    sig_samples=round(fs*smoothing);
    for i=1:size(cut_mu_rcamp,2)
        smps=round(smoothing*phan.options.fs);
        kernel_t=1:6*smps;
        kernel=exp(-kernel_t/smps);
        kernel=kernel./sum(kernel);
        tmp=conv(cut_mu_rcamp(:,i),kernel,'full');
        cut_mu_rcamp(:,i)=tmp(1:size(cut_mu_rcamp,1));
        tmp=conv(cut_mu_gcamp(:,i),kernel,'full');
        cut_mu_gcamp(:,i)=tmp(1:size(cut_mu_rcamp,1));
    end
end

%sort_mu=cut_mu_rcamp(max_lag-use_win(1):max_lag+use_win(2),:);
sort_mu=cut_mu_rcamp;

[r,c]=size(sort_mu);
[val,loc]=max(abs(sort_mu));
max_sign=sign(sort_mu(loc+(0:r:(c-1)*r)));

% nested sorting, first + then -, biggest to smallest, smallest to biggest
thresh=0;

pos_idx=find(max_sign==1&val>thresh);
pos_vals=loc(pos_idx);
[~,pos_sort]=sort(pos_vals,'ascend');

neg_idx=find(max_sign==-1&val>thresh);
neg_vals=loc(neg_idx);
[~,neg_sort]=sort(neg_vals,'descend');

rcamp_sorted_rcamp=[plot_mu_rcamp(:,pos_idx(pos_sort)) plot_mu_rcamp(:,neg_idx(neg_sort))]; 
rcamp_sorted_gcamp=[plot_mu_gcamp(:,pos_idx(pos_sort)) plot_mu_gcamp(:,neg_idx(neg_sort))]; 

%sort_mu=cut_mu_gcamp(max_lag-use_win(1):max_lag+use_win(2),:);
sort_mu=cut_mu_gcamp;

[r,c]=size(sort_mu);
[val,loc]=max(abs(sort_mu));
max_sign=sign(sort_mu(loc+(0:r:(c-1)*r)));

% nested sorting, first + then -, biggest to smallest, smallest to biggest

pos_idx=find(max_sign==1&val>thresh);
pos_vals=loc(pos_idx);
[~,pos_sort]=sort(pos_vals,'ascend');

neg_idx=find(max_sign==-1&val>thresh);
neg_vals=loc(neg_idx);
[~,neg_sort]=sort(neg_vals,'descend');

gcamp_sorted_rcamp=[plot_mu_rcamp(:,pos_idx(pos_sort)) plot_mu_rcamp(:,neg_idx(neg_sort))]; 
gcamp_sorted_gcamp=[plot_mu_gcamp(:,pos_idx(pos_sort)) plot_mu_gcamp(:,neg_idx(neg_sort))]; 


%%

colors='jet';
clims=[-8 8];

false_color(1)=schfigure();
false_color(1).name='syllable_falsecolor_norm';
false_color(1).dims='4x6';

ax(1)=subplot(2,2,1);
imagesc(tvec,[],rcamp_sorted_rcamp');
hold on;
plot([0 0],[.5 syllable_cutoff+.5],'k-','color','k');
caxis(clims)

ax(2)=subplot(2,2,2);
imagesc(tvec,[],rcamp_sorted_gcamp');
hold on;
plot([0 0],[.5 syllable_cutoff+.5],'k-','color','k');
caxis(clims)
ax(3)=subplot(2,2,3);
imagesc(tvec,[],gcamp_sorted_rcamp');
hold on;
plot([0 0],[.5 syllable_cutoff+.5],'k-','color','k');
caxis(clims)

ax(4)=subplot(2,2,4);
imagesc(tvec,[],gcamp_sorted_gcamp');
hold on;
plot([0 0],[.5 syllable_cutoff+.5],'k-','color','k');
caxis(clims)

c=colorbar('Location','SouthOutside');
set(c,'XTick',clims);
drawnow;

linkaxes(ax,'x');
xlim([-2 3]);

false_color(1).sparsify_axis([],[],[],[-2 0 3]);
false_color(1).outify_axis;
false_color(1).unify_caxis([],.05);

ax_pos=get(ax(4),'position');

for i=1:length(ax)
    set(ax(i),'YTick',1:syllable_cutoff,'YTickLabel',[],'TickLength',[.025 .025]);
    cur_ax_pos=get(ax(i),'position');
    if i==3
        set(ax(i),'position',[cur_ax_pos(1) ax_pos(2) cur_ax_pos(3) ax_pos(4)]);
    else
        set(ax(i),'position',[cur_ax_pos(1:3) ax_pos(4)]);
    end
    set(ax(i),'FontSize',10);
    
end

%colormap(colors);
colormap(flipud(brewermap(1000,'RdBu')));
set(c,'xtick',[clims(1) 0 clims(2)]);
