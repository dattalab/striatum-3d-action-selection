classdef hifiber < handle & matlab.mixin.SetGet

properties

    user_data

end

properties (GetAccess = public, SetAccess = {?hifiber, ?phanalysis, ?kinect_extract})

    options
    timestamps
    traces
    references
    metadata
    status

end

properties (Access = private)

end

methods

    function obj = hifiber(DATA, TIMESTAMPS, FS, CHANNEL_NAMES)

        if nargin < 4
            CHANNEL_NAMES = {};
        end

        if nargin < 3
            FS = [];
        end

        if nargin < 2
            return;
        end

        if isvector(DATA)
            DATA = DATA(:);
        end

        obj.use_defaults;

        TIMESTAMPS = TIMESTAMPS(:);

        if isempty(FS)
            fs = 1 ./ nanmean(diff(TIMESTAMPS));
        else
            fs = FS;
        end

        [nsamples, nchannels] = size(DATA);

        obj.timestamps = TIMESTAMPS;
        obj.metadata.fs = round(fs);

        for i = 1:nchannels
            obj.traces(i).raw = DATA(:, i);
            obj.traces(i).baseline = [];
            obj.traces(i).baseline_rem = [];
            obj.traces(i).dff = [];
            obj.traces(i).reref = [];
            obj.traces(i).name = sprintf('Ch%i', i);
            obj.traces(i).mod_freq = [];
            obj.traces(i).reference_channel = [];
        end

        obj.set_channel_names(CHANNEL_NAMES);
        obj.status.invert = false;

    end

    function s = saveobj(obj)
        use_names = properties(obj);

        for i = 1:length(use_names)
            s.(use_names{i}) = obj.(use_names{i});
        end

    end

end

methods (Static)

    % doesn't require the kinect_extract object
    upd = proc_timer(nloops, varargin)
    [new_ref, fun] = get_demod_reference(signal, ts, sampling_rate, ref_fs, ref_sig)
    [new_sync, fun] = get_sync_signal(signal, ts, sampling_rate)
    filt_data = bandpass(signal, fc, bw, sampling_rate, order, type, ripple, attenuation)
    mat = vec2mat(vec, nwin, noverlap)
    [proj, residuals, rescaled] = vector_rejection(sig, reference)

    function obj = loadobj(s)

        if isstruct(s)
            use_names = fieldnames(s);
            obj = hifiber;

            for i = 1:length(use_names)
                obj.(use_names{i}) = s.(use_names{i});
            end

        else
            obj = s;
        end

    end

end

end
