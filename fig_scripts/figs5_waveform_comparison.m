%%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/photometry_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end

phan.set_option('normalize_method','');
phan.set_option('rectify',false);
phan.set_option('filter_trace',false);
phan.window_photometry('b');

%%

% compare averages?  pairwise all-to-all?

cut=phan.options.syllable_cutoff;
max_lag=phan.options.max_lag;
use_window=[0 30];
within_compare=nan(1,cut);
between_compare=nan(cut-1,cut);

rcamp_sessions=[phan.stats.model_starts.rcamp(1,:).session_idx];
gcamp_sessions=[phan.stats.model_starts.gcamp(1,:).session_idx];

intersession=intersect(unique(rcamp_sessions),unique(gcamp_sessions));

use_gcamp=ismember(gcamp_sessions,intersession);
use_rcamp=ismember(rcamp_sessions,intersession);

upd=kinect_extract.proc_timer(cut);

for i=1:cut
    
    gcamp_stitch=zscore(cat(2,phan.stats.model_starts.gcamp(i,use_gcamp).wins));
    rcamp_stitch=zscore(cat(2,phan.stats.model_starts.rcamp(i,use_rcamp).wins));
    
    
    gcamp_stitch=gcamp_stitch(max_lag-use_window(1):max_lag+use_window(2),:);
    rcamp_stitch=rcamp_stitch(max_lag-use_window(2):max_lag+use_window(2),:);
    
    merge=[gcamp_stitch;rcamp_stitch];
    
    tmp=pdist(merge','correlation');
    within_compare(i)=nanmean(tmp);
    
    counter=1;
    
    for j=setdiff(1:cut,i)
        
        gcamp_stitch=zscore(cat(2,phan.stats.model_starts.gcamp(j,use_gcamp).wins));
        rcamp_stitch=zscore(cat(2,phan.stats.model_starts.rcamp(j,use_rcamp).wins));
        
        gcamp_stitch=gcamp_stitch(max_lag-use_window(1):max_lag+use_window(2),:);
        rcamp_stitch=rcamp_stitch(max_lag-use_window(2):max_lag+use_window(2),:);
        
        merge_other=[gcamp_stitch;rcamp_stitch];
        
        tmp=pdist2(merge',merge_other','correlation');
        between_compare(counter,i)=nanmean(tmp(triu(ones(size(tmp)),1)==1));
        
        counter=counter+1;
        
    end
    
    upd(i);
    
end


%%

wave_compare=schfigure;
wave_compare.dims='1.25x3';
wave_compare.name='waveform_comparison';
wave_compare.formats='pdf,png,fig';

plot([within_compare(:) nanmean(between_compare)']','ko-','markersize',6,'markerfacecolor',[1 1 1]);
xlim([.5 2.5]);
set(gca,'XTick',[1 2],'XTickLabel',{'Same syllable','Diff.syllable'},'FontSize',12);
xtickangle(90);
schfigure.sparsify_axis([],[],'y');
schfigure.outify_axis;


%%

% compare averages?  pairwise all-to-all?

cut=phan.options.syllable_cutoff;
max_lag=phan.options.max_lag;
use_window=[90 90];
within_compare=nan(1,cut);
between_compare=nan(cut-1,cut);

rcamp_sessions=[phan.stats.model_starts.rcamp(1,:).session_idx];
gcamp_sessions=[phan.stats.model_starts.gcamp(1,:).session_idx];


all_ids = {phan.metadata.mouse.Name};
rcamp_ids = {phan.session(rcamp_sessions).mouse_id};
gcamp_ids = {phan.session(gcamp_sessions).mouse_id};

is_rcamp=ismember(all_ids,rcamp_ids);
is_gcamp=ismember(all_ids,gcamp_ids);

include_ids=all_ids(is_rcamp&is_gcamp);

upd=kinect_extract.proc_timer(length(include_ids));

win_len=length(-use_window(1):use_window(2));

gcamp_wins=zeros(win_len,cut,length(include_ids));
rcamp_wins=zeros(size(gcamp_wins));
odor_sessions = find(cellfun(@(x) strcmp(x, "odor"), phan.get_genos));

for i=1:length(include_ids)
    
    use_gcamp=contains(gcamp_ids,include_ids{i});
    use_rcamp=contains(rcamp_ids,include_ids{i});
    
    for j=1:cut

        gcamp_stitch=zscore(cat(2,phan.stats.model_starts.gcamp(j,use_gcamp).wins));
        rcamp_stitch=zscore(cat(2,phan.stats.model_starts.rcamp(j,use_rcamp).wins));
        
        gcamp_wins(:,j,i)=nanmean(gcamp_stitch(max_lag-use_window(1):max_lag+use_window(2),:),2);
        rcamp_wins(:,j,i)=nanmean(rcamp_stitch(max_lag-use_window(1):max_lag+use_window(2),:),2);

    
    end
    
    upd(i);
    
end


% now do a within (across mice) and between syllable (across all)

within_dist=nan(cut,length(include_ids)-1);
between_dist=nan(cut,length(include_ids));

merge=[gcamp_wins;rcamp_wins];
        
for i=1:length(include_ids)
    for j=1:cut
        tmp=pdist2(merge(:,:,i)',squeeze(merge(:,j,:))','correlation');
        within_dist(j,:)=tmp(j,setdiff(1:length(include_ids),i));
        between_dist(j,:)=mean(tmp(setdiff(1:cut,j),:));
    end
end


%%

wave_compare=schfigure;
wave_compare.dims='1.25x3';
wave_compare.name='waveform_comparison';
wave_compare.formats='pdf,png,fig';

plot([nanmean(within_dist,2) nanmean(between_dist,2)]','ko-','markersize',6,'markerfacecolor',[1 1 1]);
xlim([.5 2.5]);
set(gca,'XTick',[1 2],'XTickLabel',{'Same syllable','Diff.syllable'},'FontSize',12);
xtickangle(90);
schfigure.sparsify_axis([],[],'y');
schfigure.outify_axis;
