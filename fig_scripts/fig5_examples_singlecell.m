if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end


if ~exist('model_starts','var')
    model_starts=phan.slice_syllables_neural;    
end


%%

d1_examples=[9 11 21 27 39];

mouse_groups={phan.session(:).group};
max_lag=phan.options.max_lag;
tvec=[-max_lag:max_lag]/phan.options.fs;

norm_data=@(x) bsxfun(@rdivide,bsxfun(@minus,x,min(x)),max(x)-min(x));
preproc_traces=@(x) norm_data(nanmean(zscore(double(x)),3));
preproc_tracesz=@(x) zscore(nanmean(zscore(double(x)),3));

d1_example_figs=schfigure();
d1_example_figs.name=sprintf('d1_example_fig_final');
d1_example_figs.dims='5x3';
d1_example_figs.formats='pdf,png,fig';
ax=[];    

ave_idx=find(tvec>-.5&tvec<1);

set_clims=[0 1];
nboots=1e3;

for i=1:length(d1_examples)

    all_d1=[];
    all_d2=[];

    all_d1_idx=find(strcmp(mouse_groups,'d1cre'));
    all_d2_idx=find(strcmp(mouse_groups,'a2acre'));

    for j=1:length(all_d1_idx)        
        all_d1=[all_d1 nanmean((model_starts.imaging(d1_examples(i),all_d1_idx(j)).wins),3)];
    end

    for j=1:length(all_d2_idx)        
        all_d2=[all_d2 nanmean((model_starts.imaging(d1_examples(i),all_d2_idx(j)).wins),3)];
    end


    all_d1_peaknorm=preproc_traces(all_d1);
    all_d1_z=preproc_tracesz(all_d1);
    
    all_d2_peaknorm=preproc_traces(all_d2);
    all_d2_z=preproc_tracesz(all_d2);
    
    all_d1_mus=nanmean(all_d1_peaknorm(ave_idx,:));    
      
    [~,sortidx]=sort(all_d1_mus,'descend');        
    
    pos=nanmean(all_d1_z(ave_idx,:))>0;
    
    [~,max_pos]=max(all_d1_peaknorm(ave_idx,pos));
    [~,max_neg]=min(all_d1_peaknorm(ave_idx,~pos));
    
    neg=find(~pos);
    pos=find(pos);
    
    [~,sortidx_pos]=sort(max_pos);
    [~,sortidx_neg]=sort(max_neg,'descend');

    ax(end+1)=subplot(3,length(d1_examples),i);
    imagesc(tvec,[],[all_d1_peaknorm(:,pos(sortidx_pos))';all_d1_peaknorm(:,neg(sortidx_neg))']);
    
    title([num2str(d1_examples(i))]);
    set(gca,'xtick',[],'ytick',[]);
    
    all_d2_mus=nanmean(all_d2_peaknorm(ave_idx,:));
    [~,sortidx]=sort(all_d2_mus,'descend');
    
    pos=nanmean(all_d2_z(ave_idx,:))>0;
    
    [~,max_pos]=max(all_d2_peaknorm(ave_idx,pos));
    [~,max_neg]=min(all_d2_peaknorm(ave_idx,~pos));
    
    neg=find(~pos);
    pos=find(pos);
    
    [~,sortidx_pos]=sort(max_pos);
    [~,sortidx_neg]=sort(max_neg,'descend');

    caxis([set_clims]);
    clims=caxis;
    ax(end+1)=subplot(3,length(d1_examples),i+length(d1_examples));    
    imagesc(tvec,[],[all_d2_peaknorm(:,pos(sortidx_pos))';all_d2_peaknorm(:,neg(sortidx_neg))']);
    set(gca,'xtick',[],'ytick',[]);
    
    
    if i==length(d1_examples)
       pos=get(ax(end),'position');
       c=colorbar('Location','EastOutside','Position',[pos(1)+pos(3)+.01 pos(2)-.015 .05 .1]);
       set(c,'YTick',[set_clims(1) set_clims(2)]);
       %set(c,);
    end

    caxis(clims);    
    ax(end+1)=subplot(3,length(d1_examples),i+length(d1_examples)*2);
    bootsmps=bootstrp(nboots,@nanmean,all_d2_z'>2);    
    
    schfigure.plot_trace_with_ci(tvec,all_d2_z'>2,bootsmps,...
        'face_color',[0 1 0],'sigma_t',1.96);    
    
    bootsmps=bootstrp(nboots,@nanmean,all_d1_z'>2);

    schfigure.plot_trace_with_ci(tvec,all_d1_z'>2,bootsmps,...
        'face_color',[1 0 0],'sigma_t',1.96);    
      
    ylim([0 .25]);
    ylims=ylim();
    hold on;
    plot([0 0],ylims,'k--');
    xlim([-2 3]); 
    
    schfigure.outify_axis(gca);
    schfigure.sparsify_axis(gca,[],'y');
    schfigure.sparsify_axis(gca,[],'x',[-2 0 3]);


end

colormap(parula);
linkaxes(ax,'x');
linkaxes(ax(3:3:end),'xy');
xlim([-2 3]);