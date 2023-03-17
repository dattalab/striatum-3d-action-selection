%%
if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end


if ~exist('model_starts','var')
    model_starts=phan.slice_syllables_neural;    
end

%%

%
% sort some examples

[b,a]=ellip(2,.2,40,[.5]/(30/2),'low');

norm_data=@(x) bsxfun(@rdivide,bsxfun(@minus,x,min(x)),max(x)-min(x));
preproc_traces_nofilt=@(x) norm_data(double(x));
preproc_traces=@(x) norm_data(filtfilt(b,a,double(x)));
preproc_tracesz=@(x) zscore(nanmean(zscore(filtfilt(b,a,double(x))),3));
mouse_groups={phan.session(:).group};
max_lag=phan.options.max_lag;
tvec=[-max_lag:max_lag]/phan.options.fs;
d1_example_figs=schfigure();

d1_example_figs.dims='5x3';
d1_example_figs.formats='pdf,png,fig';
ax=[];    
ave_idx=find(tvec>-.5&tvec<1);
noise_idx=find(tvec<-2|tvec>5);
set_clims=[0 1];

% 26-->3,4,8,9
% 27 looks good maybe????


beh_example=[27];
trials=[1:12];
d1_example_figs.name=sprintf('d1_example_%i',beh_example);

all_d1=[];
all_d2=[];

all_d1_idx=find(strcmp(mouse_groups,'d1cre'));
all_d2_idx=find(strcmp(mouse_groups,'a2acre'));

for j=1:length(all_d1_idx)        
    all_d1=[all_d1 nanmean((model_starts.imaging(beh_example,all_d1_idx(j)).wins),3)];
end

for j=1:length(all_d2_idx)        
    all_d2=[all_d2 nanmean((model_starts.imaging(beh_example,all_d2_idx(j)).wins),3)];
end


all_d1_peaknorm=preproc_traces(all_d1);
all_d1_z=preproc_tracesz(all_d1);

all_d2_peaknorm=preproc_traces(all_d2);
all_d2_z=preproc_tracesz(all_d2);

all_d1_mus=nanmean(all_d1_peaknorm(ave_idx,:));    
all_d1_noise=nanmean(all_d1_peaknorm(noise_idx,:));

[~,sortidx]=sort(all_d1_mus,'descend');        

pos=nanmean(all_d1_z(ave_idx,:))>0;

[~,max_pos]=max(all_d1_peaknorm(ave_idx,pos));
[~,max_neg]=min(all_d1_peaknorm(ave_idx,~pos));

neg_d1=find(~pos);
pos_d1=find(pos);

[~,sortidx_pos_d1]=sort(max_pos);
[~,sortidx_neg_d1]=sort(max_neg,'descend');

ax(end+1)=subplot(2,length(trials)+1,1);
imagesc(tvec,[],[all_d1_peaknorm(:,pos_d1(sortidx_pos_d1))';all_d1_peaknorm(:,neg_d1(sortidx_neg_d1))']);
%imagesc(tvec,[],all_d1_peaknorm(:,sortidx)');

title([num2str(beh_example)]);
set(gca,'xtick',[],'ytick',[]);

all_d2_mus=nanmean(all_d2_peaknorm(ave_idx,:));
[~,sortidx]=sort(all_d2_mus,'descend');

pos=nanmean(all_d2_z(ave_idx,:))>0;

[~,max_pos]=max(all_d2_peaknorm(ave_idx,pos));
[~,max_neg]=min(all_d2_peaknorm(ave_idx,~pos));

neg_d2=find(~pos);
pos_d2=find(pos);

[~,sortidx_pos_d2]=sort(max_pos);
[~,sortidx_neg_d2]=sort(max_neg,'descend');

caxis([set_clims]);
clims=caxis;
ax(end+1)=subplot(2,length(trials)+1,length(trials)+2);    
imagesc(tvec,[],[all_d2_peaknorm(:,pos_d2(sortidx_pos_d2))';all_d2_peaknorm(:,neg_d2(sortidx_neg_d2))']);
%imagesc(tvec,[],all_d2_peaknorm(:,sortidx)');


schfigure.outify_axis(gca);
schfigure.sparsify_axis(gca,[],'y');
schfigure.sparsify_axis(gca,[],'x',[-2 0 3]);
set(gca,'ytick',[]);

for i=1:length(trials)
    
    all_d1=[];
    all_d2=[];

    all_d1_idx=find(strcmp(mouse_groups,'d1cre'));
    all_d2_idx=find(strcmp(mouse_groups,'a2acre'));

    for j=1:length(all_d1_idx)        
        all_d1=[all_d1 squeeze((model_starts.imaging(beh_example,all_d1_idx(j)).wins(:,:,trials(i))))];
    end

    for j=1:length(all_d2_idx)        
        all_d2=[all_d2 squeeze((model_starts.imaging(beh_example,all_d2_idx(j)).wins(:,:,trials(i))))];
    end
    
    all_d1_pos=all_d1(:,pos_d1(sortidx_pos_d1));
    all_d1_neg=all_d1(:,neg_d1(sortidx_neg_d1));
    
    all_d1_fused=[all_d1_pos all_d1_neg];
    
    all_d2_pos=all_d2(:,pos_d2(sortidx_pos_d2));
    all_d2_neg=all_d2(:,neg_d2(sortidx_neg_d2));
    
    all_d2_fused=[all_d2_pos all_d2_neg];    
       
    all_d1_fused(isnan(all_d1_fused))=0;
    all_d2_fused(isnan(all_d2_fused))=0;
    
    all_d1_fused = preproc_traces(all_d1_fused);
    all_d2_fused = preproc_traces(all_d2_fused);

    all_d1_fused(isnan(all_d1_fused))=0;
    all_d2_fused(isnan(all_d2_fused))=0;
    
    all_d1_peaknorm=preproc_traces(imgaussfilt(all_d1_fused,3))';
    all_d2_peaknorm=preproc_traces(imgaussfilt(all_d2_fused,3))';        
    
    ax(end+1)=subplot(2,length(trials)+1,1+i);    
    imagesc(tvec,[],all_d1_peaknorm);
    %imagesc(tvec,[],all_d2_peaknorm(:,sortidx)');
    set(gca,'xtick',[],'ytick',[]);
    caxis([set_clims]);

    
    ax(end+1)=subplot(2,length(trials)+1,length(trials)+2+i);    
    imagesc(tvec,[],all_d2_peaknorm);
    %imagesc(tvec,[],all_d2_peaknorm(:,sortidx)');
    caxis([set_clims]);
    schfigure.outify_axis(gca);
    schfigure.sparsify_axis(gca,[],'y');
    schfigure.sparsify_axis(gca,[],'x',[-2 0 3]);
    set(gca,'ytick',[]);
    
    
end

pos=get(ax(end),'position');
c=colorbar('location','eastoutside','position',[pos(1)+pos(3)+.02 pos(2) .02 pos(4)*.5]);
set(c,'YTick',set_clims);
colormap(parula);
linkaxes(ax,'x');
xlim([-2 3]);
