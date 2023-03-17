function [STRUCT]=compute_ave_1pimaging(OBJ,MODEL_STARTS,varargin)
%
%
%

opts=struct(...
  'cut',40,...
  'win',[-.2 .2],...
  'fun',@nanmean,...
  'normalize',false);

nparams=length(varargin);
opts_names=fieldnames(opts);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
  if any(strcmp(varargin{i},opts_names))
    opts.(varargin{i})=varargin{i+1};
  end
end


max_lag=OBJ.options.max_lag;
win_smps=round(OBJ.options.fs*opts.win);
STRUCT=struct();

upd=kinect_extract.proc_timer(size(MODEL_STARTS.imaging,2)*opts.cut);

for i=1:size(MODEL_STARTS.imaging,2)

  ntrials=0;

  for j=1:opts.cut
    durs=MODEL_STARTS.imaging(j,i).durations;
    ntrials=ntrials+length(durs(durs+win_smps(2)<=max_lag));
  end
  nrois=size(MODEL_STARTS.imaging(1,i).wins,2);

  STRUCT(i).data=nan(ntrials,nrois);
  STRUCT(i).labels=nan(ntrials,1);
  counter=0;

  for j=1:opts.cut

        % get averages across all rois for this roi (rois on
        % dim 2)

        use_data=MODEL_STARTS.imaging(j,i).wins;
        use_durs=MODEL_STARTS.imaging(j,i).durations;
        use_prevs=MODEL_STARTS.imaging(j,i).prev_label;
        use_next=MODEL_STARTS.imaging(j,i).next_label;
        
        to_del=(use_durs+win_smps(2))>max_lag;
        use_data(:,:,to_del)=[];
        use_durs(to_del)=[];
        use_prevs(to_del)=[];
        use_next(to_del)=[];
        
        if opts.normalize
            use_data=phanalysis.nanzscore(use_data);
        end

        for l=1:length(use_durs)
            STRUCT(i).data(counter+l,:)=...
                squeeze(opts.fun(use_data(max_lag+win_smps(1):...
                        max_lag+use_durs(l)+win_smps(2),:,l)));
        end

        STRUCT(i).labels(counter+1:counter+length(use_durs))=j;
        STRUCT(i).prev_label(counter+1:counter+length(use_durs))=use_prevs;
        STRUCT(i).next_label(counter+1:counter+length(use_durs))=use_next;
        counter=counter+l;

        upd((i-1)*opts.cut+j);
        %templates(:,k)=nanmean(use_data(use_labels==k,:));
  end

end
