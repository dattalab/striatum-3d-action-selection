function sparsify_axis(AX,PRECISION,XY,XTICK,YTICK)
%
%

if nargin<5 | isempty(YTICK)
    YTICK=[];
end

if nargin<4 | isempty(XTICK)
	XTICK=[];
end

if nargin<3 | isempty(XY)
	XY='xy';
end

if nargin<2 | isempty(PRECISION)
	PRECISION=1e-2;
end

if nargin<1 | isempty(AX)
	AX=findall(gcf,'type','axes');
end

for i=1:length(AX)
	box(AX(i),'off');
	axis(AX(i),'manual');

	if contains(lower(XY),'y')
		ycorners=get(AX(i),'YLim')*1/PRECISION;
		new_ycorners=[floor(ycorners(1)) floor(ycorners(2))]*PRECISION;
        if new_ycorners(2)<=new_ycorners(1)
            new_ycorners(2)=new_ycorners(1)+PRECISION;
        end
		set(AX(i),'YLim',new_ycorners);
        if isempty(YTICK)
            set(AX(i),'YTick',new_ycorners);
        else
            set(AX(i),'YTick',YTICK);
        end
	end

	if contains(lower(XY),'x')
		xcorners=get(AX(i),'XLim')*1/PRECISION;
		new_xcorners=[floor(xcorners(1)) floor(xcorners(2))]*PRECISION;
        if new_xcorners(2)<=new_xcorners(1)
            new_xcorners(2)=new_xcorners(1)+PRECISION;
        end
        set(AX(i),'XLim',new_xcorners);

        if isempty(XTICK)
            set(AX(i),'XTick',new_xcorners);
        else
            set(AX(i),'XTick',XTICK);
        end
	end
end
