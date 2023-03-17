function kinect_make_crowd_movies(STATE_LABELS,METADATA,SCALARS,FRAME_IDX,FILENAMES,varargin)
%
%
%
%
%
%
%

[opts,~,opts_names]=kinect_get_defaults('common','state_movies');

nparams=length(varargin);

if mod(nparams,2)>0
  error('Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
  if any(strcmp(varargin{i},opts_names))
    opts.(varargin{i})=varargin{i+1};
  end
end

kinect_print_options(opts);
opts_cell=kinect_map_parameters(opts);

% farm out if we have a parpool rolling

p=gcp('nocreate');

% for i=1:length(STATE_LABELS)
%   STATE_LABELS{i}=STATE_LABELS{i}(~isnan(FRAME_IDX{i}));
% end

[syllables durations usage syllable_idx starts stops]=kinect_syllable_durations(STATE_LABELS);
nfiles=length(FILENAMES);

prior_frames=60;
post_frames=60;
max_examples=20;

tmp=whos('-file',FILENAMES{1},'depth_bounded_rotated');
box_size=tmp.size(1:2);
nframes=cellfun(@length,STATE_LABELS);
nframes=nframes(:);

% sort by usage, take a specific number

[vals,idx]=sort(usage,'descend');
vals=vals./sum(vals);
idx(vals<.001)=[];

% get the durations, take n frames prior to the start and n frames after

% uniform random sampling of each syllable...

% preallocate matrix, then do imfuse for each syllable (alpha blend)...

load(FILENAMES{1},'depth_bounded_rotated');
clim=prctile(single(depth_bounded_rotated(:)),[2.5 97.5]);

for i=1:length(idx)

  % get the number of hits

  % remove any that don't have enough prior/post frames

  start_examples=starts{idx(i)};

  % shift start by prior frames

  start_examples(:,1)=start_examples(:,1)-prior_frames;
  stop_examples=stops{idx(i)};
  stop_examples(:,1)=stop_examples(:,1)+post_frames;

  % get the new durations

  dur_examples=(stop_examples(:,1)-start_examples(:,1))+1;
  dur_actual=stops{idx(i)}(:,1)-starts{idx(i)}(:,1);

  to_del1=start_examples(:,1)<1;
  to_del2=stop_examples(:,1)>nframes(stop_examples(:,2));
  to_del=(to_del1|to_del2);

  start_examples(to_del,:)=[];
  dur_examples(to_del)=[];
  dur_actual(to_del)=[];

  if isempty(start_examples)
    continue;
  end

  nhits=size(start_examples,1);
  nuse=min(nhits,max_examples);

  use_idx=randperm(nhits);
  use_idx=use_idx(1:nuse);

  % include marker for syllable on in each sub-frame?

  start_examples=start_examples(use_idx,:);
  dur_examples=dur_examples(use_idx);
  dur_actual=dur_actual(use_idx);

  max_dur=max(dur_examples);
  extract_examples=start_examples(:,1)+max_dur;

  to_del=extract_examples>nframes(start_examples(:,2));

  start_examples(to_del,:)=[];
  dur_examples(to_del)=[];
  dur_actual(to_del)=[];

  max_dur=max(dur_examples);
  extract_examples=start_examples(:,1)+max_dur;

  % load in movies as needed

  files_to_use=unique(start_examples(:,2));

	% pre-allocate our matrix

  mov_matrix=zeros(424,512,max_dur+1,'int16');
  marker_coords=cell(1,max_dur+1);

  for j=1:length(files_to_use)

		% TODO: add option to use SVD reconstruction

		if opts.use_mask
	    load(FILENAMES{files_to_use(j)},'depth_bounded_rotated',...
				'depth_bounded_cable_mask_rotated');
			cable_mask=log(depth_bounded_cable_mask_rotated)>-15;
			depth_bounded_rotated=depth_bounded_rotated.*int16(cable_mask);
		else
			load(FILENAMES{files_to_use(j)},'depth_bounded_rotated');
		end

    new_idx=start_examples(:,2)==files_to_use(j);
    syllable_idx=int16(STATE_LABELS{files_to_use(j)}==syllables(idx(i)));

    start_cur=start_examples(new_idx,1);
    extract_cur=extract_examples(new_idx);

    write_examples=size(start_cur,1);

    for k=1:write_examples

			write_frames=start_cur(k):extract_cur(k);
			write_centroid=SCALARS(files_to_use(j)).centroid(write_frames,:);
			write_angle=SCALARS(files_to_use(j)).orientation(write_frames);

      % grab the indices

			for l=1:max_dur+1

				new_frame=zeros(424,512,'int16');

				insert_mouse=depth_bounded_rotated(:,:,write_frames(l));
				insert_mouse=imrotate(insert_mouse,write_angle(l),'bilinear','crop');

				coords_x=(write_centroid(l,1)-(box_size(2)/2-1)):(write_centroid(l,1)+box_size(2)/2);
				coords_y=(write_centroid(l,2)-(box_size(1)/2-1)):(write_centroid(l,2)+box_size(1)/2);

				new_frame(coords_y,coords_x)=insert_mouse;
				%
				% figure(1);imagesc(insert_mouse)
				% figure(2);imagesc(new_frame)
				%
				% pause(.03);

				mov_matrix(:,:,l)=mov_matrix(:,:,l)+new_frame;
			end

			marker_idx=find(syllable_idx(start_cur(k):extract_cur(k)));

		end
  end

	% for l=1:max_dur+1
	% 	figure(1);imagesc(mov_matrix(:,:,l));caxis([0 100]);
	% 	pause(.01);
	% end


  % may want to dispatch for asynchronous processing, but may not be necessary
  % unless we have lots of syllables

  kinect_mouse_animate_direct(mov_matrix,...
		'clim',clim,...
    'filename',sprintf('syllable_crowd_%i',i));;

end
