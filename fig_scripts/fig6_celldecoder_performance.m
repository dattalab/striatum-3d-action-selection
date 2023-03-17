%%

load('~/Desktop/phanalysis_images/decoding_results/decoding_results_1pimaging_cell_types.mat');

ci_levels=[.5:.005:1];

cell_prediction_perf=schfigure();
cell_prediction_perf.dims='3.75x2.5';
cell_prediction_perf.name='cell_prediction_performance_both';
cell_prediction_perf.formats='png,pdf,fig';
set(cell_prediction_perf.fig,...
    'defaultAxesColorOrder',[0 0 1; 1 0 0]);

subplot(1,2,1);
fields=fieldnames(perf);

ax=[];
h1=[];
for i=1:length(fields)
    yyaxis left;
    h1(i)=plot(ci_levels,nanmean(cat(1,perf.(fields{i})(:).ci))*1e2);
    hold on;
    ylim([40 100]);
    ylabel('Percent correct');
    hold on;
    rnd_perf=nanmedian(nanmean(cat(3,perf.(fields{i})(:).ci_rnd),3))*1e2;
    plot(ci_levels,rnd_perf,get(h1(i),'LineStyle'),'color','k');
    xlim([.5 .75]);

    yyaxis right;
    plot(ci_levels,nanmean(cat(1,perf.(fields{i})(:).ci_frac))*1e2);
    ylabel('Percent met criterion');
    box off;
    set(gca,'TickDir','out',...
        'TickLength',[.025 .025],...
        'XTick',[.5:.05:75],'YTick',[0:20:100],...
        'fontsize',7,'ylim',[0 100],'layer','top');   
    xlabel('Confidence threshold');
    xlim([.5 .75]);
end
%legend(h1,fields,'location','southwest','fontsize',8);

%%

load('~/Desktop/phanalysis_images/decoding_results/decoding_1pimaging_twocolor_cell_types.mat');
%
subplot(1,2,2);


ax=[];
fields=fieldnames(perf);
h1=[];
for i=1:length(fields)
    yyaxis left;
    
    tmp=[];
    for j=1:length(perf)
        tmp=[tmp;cat(1,perf(j).(fields{i})(:).ci)];
    end
    h1(i)=plot(ci_levels,nanmean(tmp)*1e2);
    hold on;
    
    tmp=[];
    for j=1:length(perf)
        tmp=[tmp;nanmedian(nanmean(cat(3,perf(j).(fields{i})(:).ci_rnd),3))];
    end
    rnd_perf=nanmean(tmp)*1e2;
    plot(ci_levels,rnd_perf,get(h1(i),'LineStyle'),'color','k');
    ylim([40 90]);
    ylabel('Percent correct');
    hold on;
    xlim([.5 .75]);

    yyaxis right;
    tmp=[];
    for j=1:length(perf)
        tmp=[tmp;cat(1,perf(j).(fields{i})(:).ci_frac)];
    end
    plot(ci_levels,nanmean(tmp)*1e2);
    ylabel('Percent met criterion');
    box off;
    set(gca,'TickDir','out',...
        'TickLength',[.025 .025],...
        'XTick',[.5:.05:75],'YTick',[0:20:100],...
        'fontsize',7,'ylim',[0 100],'layer','top');    
    xlabel('Confidence threshold');
    xlim([.5 .75]);
end
%legend(h1,fields,'location','southwest','fontsize',8);
