%%

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

%%
%

bootfun=@(x) nanmean(x);

examples=[18 14 16 38];
   
limits=[-15 15;...
    -15 15;...
    -15 15;...
    -15 15];

nboots=1e3;
nshuffles=1e3;
win=[2 3];
win_smps=round(win.*phan.options.fs);
tvec=[-win_smps(1):win_smps(2)]/phan.options.fs;
max_lag=phan.options.max_lag;

if exist('trace_figs','var')
    clear trace_figs;
end


trace_figs(1)=schfigure([]);
trace_figs(1).name='trace_examples_zscore';
trace_figs(1).dims='6x2';
ax=[];

for i=1:length(examples(:))
    
    ax(i)=subplot(1,4,i);
    
    ex=examples(i);
    
    gcamp_stitch=(cat(2,model_starts.gcamp(ex,:).wins));
    rcamp_stitch=(cat(2,model_starts.rcamp(ex,:).wins)); 
        
    gcamp_stitch=gcamp_stitch(max_lag-win_smps(1):max_lag+win_smps(2),:);
    rcamp_stitch=rcamp_stitch(max_lag-win_smps(1):max_lag+win_smps(2),:); 
    
    gcamp_shuffle=phanalysis.shuffle_statistic(@nanmean,gcamp_stitch',nshuffles,true)';
    rcamp_shuffle=phanalysis.shuffle_statistic(@nanmean,rcamp_stitch',nshuffles,true)';
            
    zgcamp=@(x) (x-mean(nanmean(gcamp_shuffle)))./max(nanstd(gcamp_shuffle));
    zrcamp=@(x) (x-mean(nanmean(rcamp_shuffle)))./max(nanstd(rcamp_shuffle));
    
    rcamp_stat=bootstrp(nboots,bootfun,rcamp_stitch');
    gcamp_stat=bootstrp(nboots,bootfun,gcamp_stitch');

    schfigure.plot_trace_with_ci(tvec,zgcamp(gcamp_stitch'),zgcamp(gcamp_stat),...
        'face_color',[0 1 0]);
    schfigure.plot_trace_with_ci(tvec,zrcamp(rcamp_stitch'),zrcamp(rcamp_stat),...
        'face_color',[1 0 0]);
    
    xlim([-2 3]);
    ylim(limits(i,:));
    
    set(gca,'ActivePositionProperty','position');
    schfigure.sparsify_axis(gca,[],[],[-2 0 3],[limits(i,1) 0 limits(i,2)]);
    schfigure.outify_axis;
    set(gca,'FontSize',8);    
    
    if i>1
        set(gca,'ytick',[]);
    end
    
end
