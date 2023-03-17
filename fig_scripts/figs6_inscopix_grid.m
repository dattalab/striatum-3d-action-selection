if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end

if ~exist('model_starts','var')
    model_starts=phan.slice_syllables_neural;    
end

%%

d1_examples=[9 11 39];
d=phan.distance.inter.ar(d1_examples,d1_examples);
z=linkage(squareform(d,'tovector'),'complete');
tmp=optimalleaforder(z,squareform(d,'tovector'));

mouse_groups={phan.session(:).group};
max_lag=phan.options.max_lag;
tvec=[-max_lag:max_lag]/phan.options.fs;
[b,a]=ellip(2,.2,40,[1]/(30/2),'low');

norm_data=@(x) bsxfun(@rdivide,bsxfun(@minus,x,min(x)),max(x)-min(x));
preproc_traces=@(x) norm_data(nanmean(zscore(double(x)),3));
preproc_tracesz=@(x) zscore(nanmean(zscore(double(x)),3));

d1_example_grid=schfigure();
d1_example_grid.name=sprintf('d1_example_fig_final_grid');
d1_example_grid.dims='4x4';
d1_example_grid.formats='pdf,png,fig';
ax=[];
ave_idx=find(tvec>-.5&tvec<1);
set_clims=[0 1];
all_d1_peaknorm={};
all_d1_z={};
all_d2_peaknorm={};
all_d2_z={};

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
    
    
    all_d1_peaknorm{i}=preproc_traces([all_d1 ]);
    all_d1_z{i}=preproc_tracesz([all_d1 ]);
    
    all_d2_peaknorm{i}=preproc_traces(all_d2);
    all_d2_z{i}=preproc_tracesz(all_d2);
    
    
end


for i=1:length(d1_examples)
    
    pos=nanmean(all_d1_z{i}(ave_idx,:))>0;
    
    [~,max_pos]=max(all_d1_peaknorm{i}(ave_idx,pos));
    [~,max_neg]=min(all_d1_peaknorm{i}(ave_idx,~pos));
    
    neg=find(~pos);
    pos=find(pos);
    
    [~,sortidx_pos]=sort(max_pos);
    [~,sortidx_neg]=sort(max_neg,'descend');
    
    pos_d1=pos;
    neg_d1=neg;
    
    sortidx_pos_d1=sortidx_pos;
    sortidx_neg_d1=sortidx_neg;
    
    pos=nanmean(all_d2_z{i}(ave_idx,:))>0;
    
    [~,max_pos]=max(all_d2_peaknorm{i}(ave_idx,pos));
    [~,max_neg]=min(all_d2_peaknorm{i}(ave_idx,~pos));
    
    neg=find(~pos);
    pos=find(pos);
    
    [~,sortidx_pos]=sort(max_pos);
    [~,sortidx_neg]=sort(max_neg,'descend');
    
    pos_d2=pos;
    neg_d2=neg;
    
    sortidx_pos_d2=sortidx_pos;
    sortidx_neg_d2=sortidx_neg;
    
    [~,sortidx]=sort(nanmean(all_d1_z{i}(ave_idx,:)),'descend');
    
    for j=1:length(d1_examples)
        
        subplot(length(d1_examples),length(d1_examples),(i-1)*length(d1_examples)+j);
        imagesc(tvec,[],[all_d1_peaknorm{j}(:,pos_d1(sortidx_pos_d1))';all_d1_peaknorm{j}(:,neg_d1(sortidx_neg_d1))']);
        
        if i==1
            title([num2str(d1_examples(j))]);
        end
        if i<length(d1_examples)
            set(gca,'xtick',[],'ytick',[]);
        else
            schfigure.outify_axis(gca);
            schfigure.sparsify_axis(gca,[],'y');
            schfigure.sparsify_axis(gca,[],'x',[-2 0 3]);
            set(gca,'ytick',[]);
            
        end
        xlim([-2 3]);
        
        
        caxis([set_clims]);
        
    end
        
end

colormap(parula);

d1_example_grid(2)=schfigure();
d1_example_grid(2).name=sprintf('d2_example_fig_final_grid');
d1_example_grid(2).dims='4x4';
d1_example_grid(2).formats='pdf,png,fig';

for i=1:length(d1_examples)
    
    pos=nanmean(all_d1_z{i}(ave_idx,:))>0;
    
    [~,max_pos]=max(all_d1_peaknorm{i}(ave_idx,pos));
    [~,max_neg]=min(all_d1_peaknorm{i}(ave_idx,~pos));
    
    neg=find(~pos);
    pos=find(pos);
    
    [~,sortidx_pos]=sort(max_pos);
    [~,sortidx_neg]=sort(max_neg,'descend');
    
    pos_d1=pos;
    neg_d1=neg;
    
    sortidx_pos_d1=sortidx_pos;
    sortidx_neg_d1=sortidx_neg;
    
    pos=nanmean(all_d2_z{i}(ave_idx,:))>0;
    
    [~,max_pos]=max(all_d2_peaknorm{i}(ave_idx,pos));
    [~,max_neg]=min(all_d2_peaknorm{i}(ave_idx,~pos));
    
    neg=find(~pos);
    pos=find(pos);
    
    [~,sortidx_pos]=sort(max_pos);
    [~,sortidx_neg]=sort(max_neg,'descend');
    
    pos_d2=pos;
    neg_d2=neg;
    
    sortidx_pos_d2=sortidx_pos;
    sortidx_neg_d2=sortidx_neg;
    
    [~,sortidx]=sort(nanmean(all_d1_z{i}(ave_idx,:)),'descend');
 
    for j=1:length(d1_examples)
        
        subplot(length(d1_examples),length(d1_examples),(i-1)*length(d1_examples)+j);
        imagesc(tvec,[],[all_d2_peaknorm{j}(:,pos_d2(sortidx_pos_d2))';all_d2_peaknorm{j}(:,neg_d2(sortidx_neg_d2))']);
        
        if i==1
            title([num2str(d1_examples(j))]);
        end
        
        if i<length(d1_examples)
            set(gca,'xtick',[],'ytick',[]);
        else
            schfigure.outify_axis(gca);
            schfigure.sparsify_axis(gca,[],'y');
            schfigure.sparsify_axis(gca,[],'x',[-2 0 3]);
            set(gca,'ytick',[]);
            
        end
        xlim([-2 3]);                
        caxis([set_clims]);
        
    end
  
end

colormap(parula);
