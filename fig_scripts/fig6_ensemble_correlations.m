if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end



%%
has_twocolor=false(size(phan.imaging));

for i=1:length(phan.imaging)
    fields=fieldnames(phan.imaging(i).traces);
    if any(strcmp(fields,'cell_type'))
        has_twocolor(i)=true;
    end
end

use_mice=find(has_twocolor);
fields={'d1','d2','both'};
nshuffles=1000;

shift=0;
phan.set_option('scalar_shift',shift);
phan.compute_scalars_correlation;

cut=phan.options.syllable_cutoff;
for ii=1:length(fields)
    
    within_dist=[];
    inter_dist=[];
    within_dist_shuffles=[];
    inter_dist_shuffles=[];

    for i=1:length(use_mice)

        use_data=(phanalysis.nanzscore([phan.stats.corr_imaging(use_mice(i)).data]));
        use_labels=[phan.stats.corr_scalars(use_mice(i)).model_labels];
        cell_types={phan.imaging(use_mice(i)).traces(:).cell_type};    

        if strcmp(fields{ii},'both')
            use_rois=find(strcmp(cell_types,'d1')|strcmp(cell_types,'d2'));
        else
            use_rois=find(strcmp(cell_types,fields{ii}));
        end
        
        if length(use_rois)<1
            continue;
        end

        for j=1:cut

            ref_data=use_data(use_labels==j,:);    
            withindist=1-pdist(ref_data(:,use_rois),'correlation');
            within_dist(end+1)=nanmean(withindist(:));

            dists=phan.distance.inter.ar(i,:);

            %within_dist{end+1}=within_dist(:);

            for k=setdiff(1:cut,j)

               cmp_data=use_data(use_labels==k,:);
               interdist=1-pdist2(ref_data(:,use_rois),cmp_data(:,use_rois),'correlation');

               inter_dist(end+1)=nanmean(interdist(:));

            end

        end

    end
    
    counter=1;
    counter2=0;
    upd=kinect_extract.proc_timer(cut*length(use_mice));

    
    for i=1:length(use_mice)

        use_data=(phanalysis.nanzscore([phan.stats.corr_imaging(use_mice(i)).data]));
        use_labels=[phan.stats.corr_scalars(use_mice(i)).model_labels];

        cell_types={phan.imaging(use_mice(i)).traces(:).cell_type};    
       
        if strcmp(fields{ii},'both')
            use_rois=find(strcmp(cell_types,'d1')|strcmp(cell_types,'d2'));
        else
            use_rois=find(strcmp(cell_types,fields{ii}));
        end
        
        if length(use_rois)<1
            continue;
        end

        for j=1:cut

            for k=1:nshuffles
                
                rnd_labels=use_labels(randperm(length(use_labels)));
                ref_data=use_data(rnd_labels==j,:);    

                withindist=1-pdist(ref_data(:,use_rois),'correlation');
                within_dist_shuffles(counter,k)=nanmean(withindist(:));

                dists=phan.distance.inter.ar(i,:);

                %within_dist{end+1}=within_dist(:);

%                 for l=setdiff(1:cut,j)
% 
%                    cmp_data=use_data(use_labels==l,:);
%                    interdist=1-pdist2(ref_data(:,use_rois),cmp_data(:,use_rois),'correlation');
% 
%                    inter_dist_shuffles(counter2+l,k)=nanmean(interdist(:));
% 
%                 end
            end

            counter2=counter2+length(setdiff(1:cut,j));
            counter=counter+1;
            upd((i-1)*cut+j);

        end                
    end
    
    ensemble_stats.within_corr.(fields{ii})=within_dist;
    ensemble_stats.inter_corr.(fields{ii})=inter_dist;
    ensemble_stats.within_corr_shuffle.(fields{ii})=within_dist_shuffles;
    ensemble_stats.inter_corr_shuffle.(fields{ii})=inter_dist_shuffles;

end

% save('ensemble_correlations_twocolor_updated.mat','ensemble_stats','shift','-v7.3');


%%
%

grps={'d1','d2','both'};

ensemble_correlations=schfigure();
ensemble_correlations.name='ca_ensemble_correlation_twocolor_cdf';
ensemble_correlations.dims='2.5x3.5';
ensemble_correlations.formats='pdf,fig,png';

count=1;
for i=1:length(grps)
        
    subplot(3,2,count);
    schfigure.stair_histogram(ensemble_stats.within_corr.(grps{i}),[-.15:.01:.15],'normalize',true,'cdf',true,'color','k');
    hold on;
    schfigure.stair_histogram(ensemble_stats.inter_corr.(grps{i}),[-.15:.01:.15],'normalize',true,'cdf',true,'color',[.75 .75 .75]);
    xlim([-.05 .15]);
    title([grps{i}]);
    count=count+1;
        
    subplot(3,2,count);
    
    schfigure.stair_histogram(nanmean(ensemble_stats.within_corr_shuffle.(grps{i})),[-.05:5e-4:.05]);
    hold on;
    ylims=ylim();
    plot(repmat(nanmean(ensemble_stats.within_corr.(grps{i})),[1 2]),ylims,'r--');
    xlim([-.05 .05]);
    count=count+1;
    
end

schfigure.outify_axis;
schfigure.sparsify_axis;