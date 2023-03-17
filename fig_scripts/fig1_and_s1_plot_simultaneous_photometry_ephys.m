%% photomephys plots

load('~/Desktop/phanalysis_images/photomephys/photomephys_analysis.mat');
phot.use_defaults;
phot.set_option('baseline_post_smooth',0);
phot.set_option('baseline_win',15);
phot.get_baseline;
phot.subtract_baseline;
phot.get_dff;
phot.rereference;
nrands=10;
nboots=10;

%%

smps=round(.05*phot.metadata.fs);
kernel_t=1:6*smps;
kernel=exp(-kernel_t/smps);
kernel=kernel./sum(kernel);

use_tdt=~isnan(tdt_clock);
max_lag=600;

%%
use_idx=1e4:length(phot.traces(1).dff);

[b,a]=butter(3,[.05]/(30/2),'high');

gcamp_norm=phot.traces(1).dff(use_idx);
rcamp_norm=phot.traces(4).dff(use_idx);
ref_norm=phot.traces(3).baseline_rem(use_idx);

% censor around any sudden jumps in power

nanzscore=@(x) (x-nanmean(x))./nanstd(x);
raw_diff=diff(phot.traces(1).raw);
shifts=find(nanzscore(raw_diff.^2)>3);

for i=1:length(shifts)
    if shifts(i)-500>0 & shifts(i)+500<length(ref_norm)
        ref_norm(shifts(i)-500:shifts(i)+500)=nan;
        gcamp_norm(shifts(i)-500:shifts(i)+500)=nan;
        rcamp_norm(shifts(i)-500:shifts(i)+500)=nan;
    end
end


use_phot.gcamp=gcamp_norm;
use_phot.rcamp=rcamp_norm;
use_phot.ref=ref_norm;


%%

tvec=[-max_lag:max_lag]./phot.metadata.fs;
use_samples=7e3:.4e5;
sigs=fieldnames(use_phot);

testing=[phot.traces([1 3]).baseline_rem];
testing=testing(use_idx(use_samples),:);
rng default; 
[w,m,h]=fastica(detrend(zscore(testing))');
[val,idx]=max(abs(m));

ref_trace=find(idx==2);
flip=sign(m(idx(ref_trace),ref_trace));
rmat=struct();

use_corr.gcamp=use_phot.gcamp(use_samples);
use_corr.rcamp=use_phot.rcamp(use_samples);
use_corr.ref=w(ref_trace,:).*flip;
use_corr.gcamp_dt=phanalysis.compute_deltas(use_corr.gcamp,2);
use_corr.rcamp_dt=phanalysis.compute_deltas(use_corr.rcamp,2);
use_corr.ref_dt=phanalysis.compute_deltas(use_corr.ref,2);


%%

rmat=struct();

sigs=fieldnames(use_corr);

upd=kinect_extract.proc_timer(size(fr_mat,2)*length(sigs));
counter=1;
mua_interp=interp1(tdt_clock(use_tdt),abs(fr_mat),phot.timestamps(use_idx),'linear');

for i=1:size(fr_mat,2)
    
    
    sig_mua=zscore(mua_interp(use_samples,i));
    
    for j=1:length(sigs)
        rmat.(sigs{j})(:,i)=xcorr(zscore(use_corr.(sigs{j})),sig_mua,'coeff',max_lag);
        upd(counter);
        counter=counter+1;
    end
end



%%

% plot all of the signals in an easy-to-digest manner

% get confidence bounds for all estimates
boots=struct();

sem=struct();
mu=struct();
use_ch=find(max(rmat.rcamp_dt)>.1);
%use_ch=[17    10    23    16    15    14     6    18    13     8];

for i=1:length(sigs)
    boots.(sigs{i})=bootstrp(nboots,@mean,rmat.(sigs{i})(:,use_ch)');
    sem.(sigs{i})=std(boots.(sigs{i}))';
    mu.(sigs{i})=mean(rmat.(sigs{i})(:,use_ch),2);
end

% get common average from the ephys

car_mat=bsxfun(@minus,mua_mat,median(mua_mat,2));
channel_to_use=[17];



%%


upd=kinect_extract.proc_timer(size(fr_mat,2)*length(sigs));
counter=1;

for i=1:length(sigs)
    
    
   use_field=(sprintf('%s_rnd',(sigs{i})));
   rmat.(use_field)=nan(max_lag*2+1,size(fr_mat,2),nrands);

   for j=1:size(fr_mat,2)
       sig_mua=zscore(mua_interp(use_samples,j));
       for k=1:nrands   
           sig_mua_rnd=circshift(sig_mua,randi(length(sig_mua)));
           rmat.(use_field)(:,j,k)=xcorr(zscore(use_corr.(sigs{i})),sig_mua_rnd,'coeff',max_lag);
       end
       upd(counter);
       counter=counter+1;
       
   end
end

upd(inf);

%%

new_panel(1)=schfigure();
new_panel(1).name='rcamp_gcamp_spiking';
new_panel(1).dims='1.5x3';
tmp_rcamp=squeeze(mean(rmat.rcamp_rnd(:,use_ch,:),2));
tmp_gcamp=squeeze(mean(rmat.gcamp_rnd(:,use_ch,:),2));

tvec=[-max_lag:max_lag]/phot.metadata.fs;

subplot(2,1,1);

schfigure.shaded_errorbar(tvec,prctile(tmp_rcamp',[2.5 97.5]),[.75 0 0]);
hold on;
schfigure.shaded_errorbar(tvec,prctile(tmp_gcamp',[2.5 97.5]),[0 .75 0]);

ci_rcamp=[mu.rcamp(:)'+sem.rcamp(:)';mu.rcamp(:)'-sem.rcamp(:)'];
ci_gcamp=[mu.gcamp(:)'+sem.gcamp(:)';mu.gcamp(:)'-sem.gcamp(:)'];

schfigure.shaded_errorbar(tvec,ci_rcamp,[1 0 0]);
plot(tvec,mu.rcamp,'k-');
schfigure.shaded_errorbar(tvec,ci_gcamp,[0 1 0]);
plot(tvec,mu.gcamp,'k-');

xlim([-2 3]);
ylim([-.15 .4]);


tmp=boots.gcamp;
tmp(tmp<0)=0;
use_samples=max_lag-100:max_lag+200;
com=(sum(tmp(:,use_samples)'.*repmat([1:length(use_samples)]',[1 nboots]))./sum(tmp(:,use_samples)'));
idx=((com+use_samples(1))-max_lag)/phot.metadata.fs;

text(1,.4,sprintf('%i%s%i',round(mean(idx)*1e3),char(177),round((std(idx)*1.96)*1e3)),'color','green');
tmp=boots.rcamp;
tmp(tmp<0)=0;
com=(sum(tmp(:,use_samples)'.*repmat([1:length(use_samples)]',[1 nboots]))./sum(tmp(:,use_samples)'))
idx=((com+use_samples(1))-max_lag)/phot.metadata.fs;

text(1,.35,sprintf('%i%s%i',round(mean(idx)*1e3),char(177),round((std(idx)*1.96)*1e3)),'color','red');

set(gca,'FontSize',10);
schfigure.sparsify_axis(gca,[],[],[-2 0 3],[-.15 0 .4]);
schfigure.outify_axis;

subplot(2,1,2);

tmp_rcamp=squeeze(mean(rmat.rcamp_dt_rnd(:,use_ch,:),2));
tmp_gcamp=squeeze(mean(rmat.gcamp_dt_rnd(:,use_ch,:),2));

tvec=[-max_lag:max_lag]/phot.metadata.fs;

schfigure.shaded_errorbar(tvec,prctile(tmp_rcamp',[2.5 97.5]),[.75 0 0]);
hold on;
schfigure.shaded_errorbar(tvec,prctile(tmp_gcamp',[2.5 97.5]),[0 .75 0]);

ci_rcamp=[mu.rcamp_dt(:)'+sem.rcamp_dt(:)';mu.rcamp_dt(:)'-sem.rcamp_dt(:)'];
ci_gcamp=[mu.gcamp_dt(:)'+sem.gcamp_dt(:)';mu.gcamp_dt(:)'-sem.gcamp_dt(:)'];

schfigure.shaded_errorbar(tvec,ci_rcamp,[1 0 0]);
plot(tvec,mu.rcamp_dt,'k-');
schfigure.shaded_errorbar(tvec,ci_gcamp,[0 1 0]);
plot(tvec,mu.gcamp_dt,'k-');

tmp=boots.gcamp_dt;
tmp(tmp<0)=0;

use_samples=max_lag-50:max_lag+50;
com=(sum(tmp(:,use_samples)'.*repmat([1:length(use_samples)]',[1 nboots]))./sum(tmp(:,use_samples)'));
idx=((com+use_samples(1))-max_lag)/phot.metadata.fs;

text(1,.25,sprintf('%i%s%i',round(mean(idx)*1e3),char(177),round((std(idx)*1.96)*1e3)),'color','green');

tmp=boots.rcamp_dt;
tmp(tmp<0)=0;
com=(sum(tmp(:,use_samples)'.*repmat([1:length(use_samples)]',[1 nboots]))./sum(tmp(:,use_samples)'));
idx=((com+use_samples(1))-max_lag)/phot.metadata.fs;


text(1,.2,sprintf('%i%s%i',round(mean(idx)*1e3),char(177),round((std(idx)*1.96)*1e3)),'color','red');


ylim([-.15 .25]);
xlim([-2 3]);
set(gca,'FontSize',10);
schfigure.sparsify_axis(gca,[],[],[-2 0 3],[-.15 0 .25]);
schfigure.outify_axis;

%%


use_duration=600;

ref_peaks=max(rmat.ref(max_lag:max_lag+use_duration,use_ch));
rcamp_peaks=max(rmat.rcamp(max_lag:max_lag+use_duration,use_ch));
gcamp_peaks=max(rmat.gcamp(max_lag:max_lag+use_duration,use_ch));

ref_sem=std(bootstrp(nboots,@mean,ref_peaks));
rcamp_sem=std(bootstrp(nboots,@mean,rcamp_peaks));
gcamp_sem=std(bootstrp(nboots,@mean,gcamp_peaks));

ref_ci=[mean(ref_peaks)-ref_sem;mean(ref_peaks)+ref_sem];
rcamp_ci=[mean(rcamp_peaks)-rcamp_sem;mean(rcamp_peaks)+rcamp_sem];
gcamp_ci=[mean(gcamp_peaks)-gcamp_sem;mean(gcamp_peaks)+gcamp_sem];

new_panel(2)=schfigure();
new_panel(2).dims='1.5x3';
new_panel(2).name='gcamp_rcamp_reference_spiking_correlation';

h=bar(1,mean(rcamp_peaks));
hold on;
plot([1 1],rcamp_ci,'k-');
h.FaceColor='r';
hold on;
h=bar(2,mean(gcamp_peaks));
plot([2 2],gcamp_ci,'k-');
h.FaceColor='g';
h=bar(3,mean(ref_peaks));
plot([3 3],ref_ci,'k-');
h.FaceColor=[.75 .75 .75];
set(gca,'XTick',[1:3],'XTickLabel',{'jRCaMP1b','GCaMP6s','Ref'});
schfigure.outify_axis;
schfigure.sparsify_axis([],[],'y');
xtickangle(90);

%%

mu_fs=1/mean(diff(tdt_clock(use_tdt)));
gcamp_norm=phot.traces(1).dff;
gcamp_norm(gcamp_norm<0)=0;
rcamp_norm=phot.traces(4).dff;
rcamp_norm(rcamp_norm<0)=0;
ref=min(phot.timestamps);
panel(1)=schfigure();
panel(1).name='photomephys';
panel(1).dims='2x5';
ax(1)=subplot(4,1,1);
plot(tdt_clock(use_tdt)-ref,car_mat(:,channel_to_use),'k-');
set(ax(1),'xcolor',get(gca,'color'));
ylim([-200 200]);
ax(2)=subplot(4,1,2);
plot(tdt_clock(use_tdt)-ref,fr_mat(:,channel_to_use)*mu_fs,'r-');
set(ax(2),'xcolor',get(gca,'color'));
ylim([0 600]);
hold on
plot([85 90],[600 600],'k-');
ax(3)=subplot(4,1,3);
plot(phot.timestamps-ref,gcamp_norm*1e2,'g-');
set(ax(3),'xcolor',get(gca,'color'));
ylim([0 20]);
ax(4)=subplot(4,1,4);
plot(phot.timestamps-ref,rcamp_norm*1e2,'r-');
ylim([0 5]);
linkaxes(ax,'x');
xlim([80 130]);
set(ax(4),'xcolor',get(gca,'color'));

h=line([80 90],[,-.5 -.5],'Color','k');
h.Clipping='off';
schfigure.sparsify_axis(ax);
schfigure.outify_axis(ax);
%offsetAxes(ax(end));


mu_fs=1/mean(diff(tdt_clock(use_tdt)));
gcamp_norm=phot.traces(1).dff;
gcamp_norm(gcamp_norm<0)=0;
rcamp_norm=phot.traces(4).dff;
rcamp_norm(rcamp_norm<0)=0;
ref=min(phot.timestamps);
panel(2)=schfigure();
panel(2).name='photomephys_zoom';
panel(2).dims='2x5';
ax(1)=subplot(4,1,1);
plot(tdt_clock(use_tdt)-ref,car_mat(:,channel_to_use),'k-');
set(ax(1),'xcolor',get(gca,'color'));
ylim([-200 200]);
ax(2)=subplot(4,1,2);
plot(tdt_clock(use_tdt)-ref,fr_mat(:,channel_to_use)*mu_fs,'r-');
set(ax(2),'xcolor',get(gca,'color'));
ylim([0 600]);
ax(3)=subplot(4,1,3);
plot(phot.timestamps-ref,gcamp_norm*1e2,'g-');
set(ax(3),'xcolor',get(gca,'color'));
ylim([0 20]);
ax(4)=subplot(4,1,4);
plot(phot.timestamps-ref,rcamp_norm*1e2,'r-');
ylim([0 5]);
linkaxes(ax,'x');
xlim([85 90]);
set(ax(4),'xcolor',get(gca,'color'));
h=line([85 86],[,-.5 -.5],'Color','k');
h.Clipping='off';
schfigure.sparsify_axis(ax);
schfigure.outify_axis(ax);
%offsetAxes(ax(end));


