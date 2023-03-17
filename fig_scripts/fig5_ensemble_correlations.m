%%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end

if ~exist('model_starts','var')
    model_starts=phan.slice_syllables_neural;    
end

%%


cut=phan.options.syllable_cutoff;

use_mice=[1:length(phan.session)];
example=6;
train_cut=15;
grps={'d1','a2a','wt'};
mouse_grps={phan.session(:).group};
nshuffles=1000;
shift=0;

%%

phan.set_option('scalar_shift',shift);
phan.compute_scalars_correlation;
ensemble_stats=struct();



for iii=1:length(grps)

    within_dist=[];
    inter_dist=[];
    
    use_mice=find(contains(mouse_grps,grps{iii}));
    for i=1:length(use_mice)

        use_data=(phanalysis.nanzscore([phan.stats.corr_imaging(use_mice(i)).data]));
        use_labels=[phan.stats.corr_scalars(use_mice(i)).model_labels];

        for j=1:cut

            ref_data=use_data(use_labels==j,:);    

            use_mu=nanmean(ref_data);
            use_rois=true(1,size(ref_data,2));

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

    within_dist_shuffles=nan(numel(within_dist),nshuffles);
    inter_dist_shuffles=nan(numel(inter_dist),nshuffles);

    upd=kinect_extract.proc_timer(cut*length(use_mice));

    counter=1;
    counter2=0;

    for i=1:length(use_mice)

        use_data=(phanalysis.nanzscore([phan.stats.corr_imaging(use_mice(i)).data]));
        use_labels=[phan.stats.corr_scalars(use_mice(i)).model_labels];

        [nsamples,nrois]=size(use_data);
        templates=nan(nrois,cut);

        for j=1:cut

            cmpidx=setdiff(1:cut,j);

            for ii=1:nshuffles

                use_labels=use_labels(randperm(length(use_labels)));
                ref_data=use_data(use_labels==j,:);

                use_mu=nanmean(ref_data);
                use_rois=true(1,size(ref_data,2));

                withindist=1-pdist(ref_data(:,use_rois),'correlation');
                within_dist_shuffles(counter,ii)=nanmean(withindist(:));

                for k=1:length(cmpidx)

                   cmp_data=use_data(use_labels==cmpidx(k),:);
                   interdist=1-pdist2(ref_data(:,use_rois),cmp_data(:,use_rois),'correlation');
                   inter_dist_shuffles(counter2+k,ii)=nanmean(interdist(:));

                end

            end

            counter2=counter2+length(cmpidx); 
            counter=counter+1;
            upd((i-1)*cut+j);


        end


    end
    ensemble_stats.within_corr.(grps{iii})=within_dist;
    ensemble_stats.inter_corr.(grps{iii})=inter_dist;
    ensemble_stats.within_corr_shuffle.(grps{iii})=within_dist_shuffles;
    ensemble_stats.inter_corr_shuffle.(grps{iii})=inter_dist_shuffles;
end

%%

grps={'d1','a2a','wt'};

ensemble_correlations=schfigure();
ensemble_correlations.name='ca_ensemble_correlation_cdf';
ensemble_correlations.dims='3x4.5';
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

%%

% p-values
pvals_ensemblestats=struct();
for i=1:length(grps)
    pvals_ensemblestats.(grps{i})=1-mean(nanmean(ensemble_stats.within_corr.d1)>nanmean(ensemble_stats.within_corr_shuffle.d1))
end

