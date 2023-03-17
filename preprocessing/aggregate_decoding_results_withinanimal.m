listing=dir(fullfile(pwd,'rf_decoding*.mat'));
listing={listing(:).name};

upd=kinect_extract.proc_timer(length(listing));
performance=struct();
performance_metadata=struct();

% reconstruct syllable-specific performance???
% current inscopix decoding results for the within animal comparison is:
% 1) decoding_results_withinanimal/20180118T105648 (agg and set to old_performance)
% 2) decoding_results_withinanimal_compare/20180118T105648 (agg and set to performance)

%nboots=metadata.nboots;

if exist('job_details.mat','file')
    load('job_details.mat','pseudo_pop_labels')
    use_labels=pseudo_pop_labels;
    randomize=true;   
else
    randomize=false;
end

nrands=1000;
nparams=length(listing);

performance.rnd=[];
performance.ncells=[];
performance.levels=[];
performance.nsyllables={};
grps={'d1','d2','both'};
is_hierarchy=false;

for i=1:nparams
    
    load(listing{i},'model_perf','model_prediction','metadata');
       
    % for now just load performance and construct guessing likelihood based
    % on prevalence order 0 probs 
           
    performance.ncells(i)=metadata.ncells;      
    if ~isfield(metadata,'mouse_idx')
        metadata.mouse_idx=1;
    end
    
    
    performance.within(:,metadata.boot_idx,metadata.cell_idx,metadata.mouse_idx)=model_perf.both;        
    
    % flip that weighted coin
    nfolds=metadata.cvobj.NumTestSets;
    
    if randomize
        for j=1:nfolds

            use_labels_fold=use_labels(metadata.cvobj.training(j));
            obs_labels_fold=use_labels(metadata.cvobj.test(j));
            probs=accumarray(use_labels_fold,ones(size(use_labels_fold)));
            probs=probs./sum(probs);
            bins=[-inf;cumsum(probs);inf];

            for k=1:nrands

                [~,guess]=histc(rand(length(obs_labels_fold),1),bins);
                performance.rnd(j,k,metadata.cell_idx,metadata.mouse_idx)=mean(obs_labels_fold==guess);

            end
        end       
    end        
    upd(i);
   
end

performance.rnd=squeeze(performance.rnd);
performance.within=squeeze(performance.within);
performance.within(performance.within==0)=nan;
%old_performance=performance;


%%

if exist('old_performance', 'var')
    save('decoding_results.mat', 'performance', 'old_performance')
else
    save('decoding_results.mat', 'performance')
end

