function set_reference_channel(OBJ, CH, REF)
%
%
%

for i = 1:length(OBJ)
    nchannels = length(OBJ(i).traces);

    if (CH <= nchannels & CH > 0) & (REF <= nchannels & REF >= 0)
        OBJ(i).traces(CH).reference_channel = REF;
    end

end
