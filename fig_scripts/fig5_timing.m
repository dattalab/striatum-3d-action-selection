%%
%
%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end


%%

% make a grand average of all the dang cells: for your average!
% stitch together ROIs, maybe normalize again, then average

changepoints = phan.slice_changepoints_neural;
model_starts = phan.slice_syllables_neural;

%%

idx=[changepoints.imaging(:).session_idx];
[b,a]=ellip(5,.2,40,[.75]/(30/2),'high');

chk_grps={'d1cre','a2acre','wt'};

mouse_grps={phan.session(:).group};
%mouse_grps(strcmp(mouse_grps,'d1nlstdtom'))={'wt'};

use_traces=struct();
rand_mu=struct();
nrands=1000;
nshuffles=1000;

upd=kinect_extract.proc_timer(length(mouse_grps));
counter=1;
for i=1:length(chk_grps)
    use_traces.(chk_grps{i})=[];
    tmp_mice=find(contains(mouse_grps,chk_grps{i}));

    for j=1:length(tmp_mice)
        % make sure index matches
        use_idx=idx==tmp_mice(j);
        use_traces.(chk_grps{i})=cat(2,use_traces.(chk_grps{i}),squeeze(nanmean(changepoints.imaging(use_idx).wins,3)));
        upd(counter);
        counter=counter+1;
    end

    % just add a shift to each imaging matrix prior to averaging for
    % randomization

    use_traces.(chk_grps{i})=(phanalysis.nanzscore((use_traces.(chk_grps{i}))))>2;
    rand_mu.(chk_grps{i})=phanalysis.shuffle_statistic(@nanmean, use_traces.(chk_grps{i})',nshuffles,true);

end

%%

imaging_cpave=schfigure;
imaging_cpave.name='imaging_cp_ave';
imaging_cpave.dims='1.5x1.5';
colors=[1 0 0; 0 1 0; 1 .5 0];
max_lag=phan.options.max_lag;
tvec=[-max_lag:max_lag]./phan.options.fs;

rand_ci=prctile(struct2array(rand_mu),[2.5 97.5],2)';
schfigure.shaded_errorbar(tvec,rand_ci,[.75 .75 .75],'none');
hold on;
sem_store=struct();
for i=1:length(chk_grps)

    bootstat=bootstrp(1000,@nanmean,use_traces.(chk_grps{i})');
    mu=nanmean(use_traces.(chk_grps{i})');
    sem=nanstd(bootstat);
    ci=[mu+sem;mu-sem];
    max_lag=phan.options.max_lag;

    schfigure.shaded_errorbar(tvec,ci,colors(i,:),'none');

    plot(tvec,mu,'k-');
    xlimits=xlim();
    sem_store.(chk_grps{i})=std(max(bootstat'));
    mu_store.(chk_grps{i})=mean(max(bootstat'));

end

ylim([0 .16]);
ylimits=ylim();
plot([0 0],ylimits,'k-');
plot(xlimits,[0 0],'k-');
xlim([-2 3])
schfigure.outify_axis;
schfigure.sparsify_axis([],[],'x',[-2 0 3]);
schfigure.sparsify_axis([],[],'y');


%%
%

[nsyllables,nsession]=size(model_starts.imaging);
use_traces_strial=struct();
use_traces_ave=struct();
ave_active=struct();
strial_active=struct();
counter=1;

chk_grps={'d1','a2a','wt'};
colors=[1 0 0; 0 1 0; .5 .5 0];
mouse_grps={phan.session(:).group};

upd=kinect_extract.proc_timer(length(chk_grps)*nsyllables);

for i=1:length(chk_grps)

    tmp_mice=find(contains(mouse_grps,chk_grps{i}));
    ave_active.(chk_grps{i})=[];
    strial_active.(chk_grps{i})=[];

    for j=1:nsyllables
        use_traces_strial=[];
        use_traces_ave=[];
        for k=1:length(tmp_mice)
            % make sure index matches
            use_idx=tmp_mice(k);
            use_traces_strial=cat(2,use_traces_strial,squeeze(nanmean(abs(phanalysis.nanzscore(model_starts.imaging(j,use_idx).wins))>2,3)));
            use_traces_ave=cat(2,use_traces_ave,squeeze(nanmean(model_starts.imaging(j,use_idx).wins,3)));
        end
        tmp=nanmean(abs(zscore(use_traces_ave))>2,2);
        ave_active.(chk_grps{i})(end+1)=max(tmp(phan.options.max_lag-30:phan.options.max_lag+60));
        tmp=nanmean(use_traces_strial,2);
        strial_active.(chk_grps{i})(end+1)=max(tmp(phan.options.max_lag-30:phan.options.max_lag+60));
        upd(counter);
        counter=counter+1;
    end


end


%%
mu=struct();
sem=struct();

for i=1:length(chk_grps)

    mu.strial.(chk_grps{i})(1)=mean(strial_active.(chk_grps{i}))*1e2;
    mu.ave.(chk_grps{i})(1)=mean(ave_active.(chk_grps{i}))*1e2;

    mu.strial.(chk_grps{i})(2)=std(bootstrp(1e3,@mean,strial_active.(chk_grps{i})))*1e2;
    mu.ave.(chk_grps{i})(2)=std(bootstrp(1e3,@mean,ave_active.(chk_grps{i})))*1e2;

end

notes='mu sem';
phanalysis.print_stats('neurons_active_strial.txt',mu.strial,{},'notes',notes);
phanalysis.print_stats('neurons_active_ave.txt',mu.ave,{},'notes',notes);


