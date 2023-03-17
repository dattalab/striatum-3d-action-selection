%%

%%

% compare PCs for behaviors where we have plenty of samples from each group

beh=phan.behavior;
max_lag=phan.options.max_lag_scalars;
cut=phan.options.syllable_cutoff;
win=[0 20];
win_len=length(-win(1):win(2));
nsessions=length(beh);
npcs=10;

% gather up a distance matrix for all sessions

pca_dist=nan(nsessions,nsessions,cut);
beh_trajectories=nan(win_len*npcs,cut,nsessions);

cut=phan.options.syllable_cutoff;
within_condition=nan(1,cut);
between_condition=nan(1,cut);
other_syllables=nan(cut-1,cut);
distance_type='euclidean';
model_scalars=phan.slice_syllables_scalars({'pca'});

shams_idx=ismember(ids,shams)&ctrl;
lesions_idx=ismember(ids,lesions)&ctrl;

for i=1:cut
    try
        tmp=cellfun(@(x) nanmean((x(max_lag-win(1):max_lag+win(2),1:npcs,:)),3),{model_scalars(i,:).pca},'uniformoutput',false);
    catch
        continue;
    end
    
    tmp=cat(3,tmp{:});
    [r,c,z]=size(tmp);
    tmp=reshape(tmp,r*c,z);
    beh_trajectories(:,i,:)=tmp;
    
    tmp1=pdist2(squeeze(beh_trajectories(:,i,shams_idx))',squeeze(beh_trajectories(:,i,lesions_idx))',distance_type);
    tmp2=pdist(squeeze(beh_trajectories(:,i,lesions_idx))',distance_type);
    
    within_condition(i)=nanmedian(tmp2(:));
    between_condition(i)=nanmedian(tmp1(:));
    
    counter=1;
    
    for j=setdiff(1:cut,i)
        
        tmp3=pdist2(squeeze(beh_trajectories(:,i,:))',squeeze(beh_trajectories(:,j,:))',distance_type);
        
        other_syllables(counter,i)=nanmedian(tmp3(:));
        counter=counter+1;
        
    end
end

%%

% compare within syllable within condition, then across condition, then
% across syllables

behavior_comparison=schfigure();
behavior_comparison.name='lesion_behavior_compare';
behavior_comparison.dims='1.25x2';
behavior_comparison.formats='pdf,png,fig';
ylim([0 1.25]);
plot([within_condition(:) between_condition(:) nanmean(other_syllables)']','ko-',...
    'markersize',5,'markerfacecolor',[1 1 1]);
xlim([0 4]);
set(gca,'XTick',[1:3],'XTickLabel',...
    {'Within','Between','Other'},'FontSize',10);
xtickangle(90);
schfigure.outify_axis;
schfigure.sparsify_axis(gca,1e-3,'y');


%%

if exist('old_within_condition','var')
    behavior_comparison(2)=schfigure();
    behavior_comparison(2).name='lesion_behavior_compare_combined';
    behavior_comparison(2).dims='1.25x2';
    behavior_comparison(2).formats='pdf,png,fig';
    
    ylim([0 1.25]);
    plot([[old_within_condition(:);within_condition(:)] [old_between_condition(:);between_condition(:)] [old_other_syllables;nanmean(other_syllables)']]','ko-',...
        'markersize',5,'markerfacecolor',[1 1 1]);
    xlim([0 4]);
    set(gca,'XTick',[1:3],'XTickLabel',...
        {'Within','Between','Other'},'FontSize',10);
    xtickangle(90);
    schfigure.outify_axis;
    schfigure.sparsify_axis(gca,1e-3,'y');
    
    
end


