%%

if ~exist('phan','var')
    load('~/Desktop/workspace/1pimaging_dls/_analysis/phanalysis_object.mat');
    phan=phanalysis_object;
end

if ~exist('model_starts','var')
    model_starts=phan.slice_syllables_neural;    
end

if ~exist('syll_max','var')
    syll_max=d1d2_imaging_compute_aves(phan,model_starts,...
        'fun',@max,'normalize',false,'win',[0 0],...
        'cut',phan.options.syllable_cutoff);
end

%%

mouse_group={phan.session(:).group};
mouse_group(strcmp(mouse_group,'d1nlstdtom'))={'wt'};
use_scalars={'angle_dt','height_ave','height_ave_dt','length','length_dt',...
        'velocity_mag','velocity_mag_dt','velocity_mag_3d','velocity_mag_3d_dt'};

clear r;

cell_r=[];
cell_syllables=[];
cell_idx=[];
cell_mouse_idx=[];

cutoff=phan.options.syllable_cutoff;
ave_vec=phan.options.max_lag-5:phan.options.max_lag+10;
upd=kinect_extract.proc_timer(length(phan.stats.corr_scalars));

for i=1:length(phan.stats.corr_scalars)
    
    
    tmp=[];
    tmp_pop=[];
    for j=1:length(use_scalars)
        tmp(:,end+1)=corr(phan.stats.corr_scalars(i).(use_scalars{j}),phan.stats.corr_imaging(i).data,'rows','pairwise','type','pearson')';        
    end
    
    idx=repmat(mouse_group(i),[size(tmp,1) 1]);
    
    fields=fieldnames(phan.imaging(i).traces);

    
    cell_r=[cell_r;tmp];
    
    if any(strcmp(fields,'cell_type'))      
        idx={phan.imaging(i).traces(:).cell_type}';
    end
    cell_idx=[cell_idx;idx];
    cell_mouse_idx=[cell_mouse_idx;repmat(i,[size(tmp,1) 1])];
    nrois=size(phan.stats.corr_imaging(i).data,2);
    tmp_mu=nan(nrois,phan.options.syllable_cutoff);
    use_data=(phan.stats.corr_imaging(i).data);
    %use_data=syll_max(i).data;
    tmp_std=nan(size(tmp_mu));
    for j=1:phan.options.syllable_cutoff
       use_idx=phan.stats.corr_scalars(i).model_labels==j;
     % use_idx=syll_max(i).labels==j;
       tmp_mu(:,j)=nanmean(use_data(use_idx,:));        
       tmp_std(:,j)=nanstd(use_data(use_idx,:)); 
    end
    %cell_syllables=[cell_syllables;[cat(1,tmp_mu{:});cat(1,tmp_std{:})]'];
    %cell_syllables=[cell_syllables;[cat(1,tmp_mu{:})]'];
    cell_syllables=[cell_syllables;[tmp_mu]];
    upd(i);
end

plot_r=struct();

ctypes={'d1','a2a','wt'};

for i=1:length(use_scalars)
   for j=1:length(ctypes)
      plot_r.(use_scalars{i}).(ctypes{j})=cell_r(contains(cell_idx,ctypes{j}),i); 
   end
end

%%

use_idx=contains(cell_idx,'cre');
all_data=[(cell_r) normr(cell_syllables)];
all_data_syllables=normr(cell_syllables);
all_data_scalars=(cell_r);

%all_other_data=[normr(cell_r(~use_idx,:)) normr(cell_syllables(~use_idx,:))];

train_data=struct();

train_data.all=all_data(use_idx,:);
train_data.syllables=all_data_syllables(use_idx,:);
train_data.scalars=all_data_scalars(use_idx,:);
train_labels=cell_idx(use_idx,:);

nfolds=5;
nrands=1e3;
ci_levels=[.5:.005:1];

cvobj=cvpartition(train_labels,'kfold',nfolds);

perf=struct();
fields={'all','syllables','scalars'};
counter=1;

upd=kinect_extract.proc_timer(nfolds*length(fields));

for i=1:nfolds    
    for j=1:length(fields)    
    
        mdl=TreeBagger(2000,train_data.(fields{j})(cvobj.training(i),:),...
            train_labels(cvobj.training(i)),'prior','uniform');
        obs=train_labels(cvobj.test(i));
        [guesses,probas]=mdl.predict(train_data.(fields{j})(cvobj.test(i),:));
        perf.(fields{j})(i).acc=mean(strcmp(guesses,obs));
        perf.(fields{j})(i).ci=nan(1,length(ci_levels));
        perf.(fields{j})(i).ci_frac=nan(1,length(ci_levels));
        perf.(fields{j})(i).ci_rnd=nan(nrands,length(ci_levels));
        perf.(fields{j})(i).guesses=guesses;
        perf.(fields{j})(i).probas=probas;
        perf.(fields{j})(i).actual=obs;
    
        for k=1:nrands
           rnd_guesses=randsample(train_labels(cvobj.training(i)),length(obs),true);
           perf.(fields{j})(i).rnd_acc(k)=mean(strcmp(rnd_guesses,obs));
        end
        
        for k=1:length(ci_levels)
            incl=max(probas')>ci_levels(k);
            if sum(incl)>0
                perf.(fields{j})(i).ci(k)=mean(strcmp(guesses(incl),obs(incl)));              
                perf.(fields{j})(i).ci_frac(k)=mean(incl);
                for l=1:nrands
                   rnd_guesses=randsample(train_labels(cvobj.training(i)),sum(incl),true);
                   perf.(fields{j})(i).ci_rnd(l,k)=mean(strcmp(rnd_guesses,obs(incl)));
                end
            end
        end
    
        upd(counter);
        counter=counter+1;
        
    end        
end

save('cell_prediction_performance_with_rnd.mat','perf','-v7.3');


%%



% can we make predictions???

use_idx=strcmp(cell_idx,'d1')|strcmp(cell_idx,'d2');
use_idx_augment=contains(cell_idx,'cre');

%[coef score]=pca(normr(cell_syllables));

all_data_syllables=normr(cell_syllables);
%all_data_syllables=score(:,1:20);
all_data_scalars=(cell_r);
all_data=[all_data_scalars all_data_syllables];
%all_other_data=[normr(cell_r(~use_idx,:)) normr(cell_syllables(~use_idx,:))];

train_data=struct();

train_data.all=all_data(use_idx,:);
train_data.syllables=all_data_syllables(use_idx,:);
train_data.scalars=all_data_scalars(use_idx,:);
train_labels=cell_idx(use_idx,:);

augment_data.all=all_data(use_idx_augment,:);
augment_data.syllables=all_data_syllables(use_idx_augment,:);
augment_data.scalars=all_data_scalars(use_idx_augment,:);
train_labels_augment=cell_idx(use_idx_augment,:);
train_labels_augment(strcmp(train_labels_augment,'d1cre'))={'d1'};
train_labels_augment(strcmp(train_labels_augment,'a2acre'))={'a2a'};

% augment the datarrrr


nrands=1000;
nfolds=5;
ci_levels=[.5:.005:1];


fields={'all','syllables','scalars'};
counter=1;

reps=5;
upd=kinect_extract.proc_timer(nfolds*length(fields)*reps);
cvobj=cvpartition(train_labels,'kfold',nfolds);
perf=struct();
naugments=0;

for ii=1:reps
    cvobj=cvobj.repartition;   
    
    for i=1:nfolds    
        for j=1:length(fields)
            
            [coef score latent dummy explained]=pca(train_data.(fields{j}));
            
            use_idx=min(find(cumsum(explained)>90));
            % 6 lookin' good thus far...
            
            train_x=score(cvobj.training(i),1:min(use_idx,size(score,2)));
            %train_x=train_data.(fields{j})(cvobj.training(i),:);            
            train_y=train_labels(cvobj.training(i));
            %test_x=train_data.(fields{j})(cvobj.test(i),:);
            test_x=score(cvobj.test(i),1:min(use_idx,size(score,2)));
            test_y=train_labels(cvobj.test(i));
            
            if naugments>0
                [augments,idx]=datasample(train_x,naugments,1);
                mu=mean(train_x);
                tmp=corr(mu(:),augment_data.(fields{j})','rows','complete','type','pearson');
                tmp(tmp<=0)=0;
                [augments,idx]=datasample(augment_data.(fields{j}),naugments,'weights',tmp(:));
                train_x=[train_x;augments];
                train_y=[train_y;train_labels_augment(idx)];
            end
            
%             mdl=TreeBagger(50,train_data.(fields{j})(cvobj.training(i),:),...
%                 train_labels(cvobj.training(i)),'prior','uniform');
            mdl=TreeBagger(100,train_x,train_y,...
                'prior','uniform','minleafsize',1,'maxnumsplits',1e3);
           
            [guesses,probas]=mdl.predict(test_x);
            perf(ii).(fields{j})(i).acc=mean(strcmp(guesses,test_y));
            perf(ii).(fields{j})(i).ci=nan(1,length(ci_levels));
            perf(ii).(fields{j})(i).ci_frac=nan(1,length(ci_levels));
            perf(ii).(fields{j})(i).ci_rnd=nan(nrands,length(ci_levels));
            perf(ii).(fields{j})(i).guesses=guesses;
            perf(ii).(fields{j})(i).probas=probas;
            perf(ii).(fields{j})(i).actual=test_y;

            for k=1:nrands
               rnd_guesses=randsample(train_y,length(test_y),true);
               perf(ii).(fields{j})(i).rnd_acc(k)=mean(strcmp(rnd_guesses,test_y));
            end

            for k=1:length(ci_levels)
                incl=max(probas')>ci_levels(k);
                if sum(incl)>0
                    perf(ii).(fields{j})(i).ci(k)=mean(strcmp(guesses(incl),test_y(incl)));              
                    perf(ii).(fields{j})(i).ci_frac(k)=mean(incl);
                    for l=1:nrands
                       rnd_guesses=randsample(train_y,sum(incl),true);
                       perf(ii).(fields{j})(i).ci_rnd(l,k)=mean(strcmp(rnd_guesses,test_y(incl)));
                    end
                end
            end

            upd(counter);
            counter=counter+1;

        end        
    end
end

%save('cell_prediction_performance_twocolor_with_rnd.mat','perf');
