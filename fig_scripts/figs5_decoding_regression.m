%%

load('~/Desktop/phanalysis_images/decoding_results/decoding_results_photometry_regress.mat')

%%

% average mse gain over random

use_fields=fieldnames(performance);
mse_gain=struct();

for i=1:length(use_fields)
    
    obs_mse=mean(performance.(use_fields{i}),2);
    rand_mse=mean(performance_rnd.(use_fields{i})(:));
    
    mse_gain.(use_fields{i})=(obs_mse-rand_mse);
    
end


%%

fig=schfigure();
fig.name='barplot_mspe_gain';
fig.dims='2x5';

% plotsy whotsy
plot_fields={'all_dt_w_combined','gcamp_dt_w_combined','rcamp_dt_w_combined'};

plot_labels={};
for i=1:length(plot_fields)
    tmp=regexp(plot_fields{i},'_','split');
    plot_labels{i}=strjoin(tmp(1:min(length(tmp),2)));
end


plot_height=[];
for i=1:length(plot_fields)
    plot_height(i)=mse_gain.(plot_fields{i});
end

ax=[];

ax(1)=subplot(2,1,1);
bar(plot_height)
xtickangle(45);
box off;

set(gca,'XTick',1:length(plot_fields),...
    'XTickLabel',plot_labels,'xaxislocation','top');

ylim([-.012 0]); 
schfigure.outify_axis;
schfigure.sparsify_axis([],1e-3,'y');
title('Raw');
ylabel('MSPE (rel.)')


% plotsy whotsy
plot_fields={'all_w','gcamp_w','rcamp_w','all_dt_w','gcamp_dt_w','rcamp_dt_w','all_dt_w_combined','gcamp_dt_w_combined','rcamp_dt_w_combined'};

plot_labels={};
for i=1:length(plot_fields)
    tmp=regexp(plot_fields{i},'_','split');
    plot_labels{i}=strjoin(tmp(1:min(length(tmp),2)));
end

plot_height=[];
for i=1:length(plot_fields)
    plot_height(i)=mse_gain.(plot_fields{i});
end

ax(2)=subplot(2,1,2);
bar(plot_height)
xtickangle(45);

set(gca,'XTick',1:length(plot_fields),...
    'XTickLabel',plot_labels,'xaxislocation','top');

ylim([-.012 0]); 

schfigure.outify_axis;
schfigure.sparsify_axis([],1e-3,'y');

title('Warped (linear)');