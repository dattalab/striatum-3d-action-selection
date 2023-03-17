function [MAT, IDX] = kinect_insert_element(MAT, DIM, VAL, IDX)
%
%
%
%

% make sure the index is ascending order

IDX = sort(IDX, 'ascend');

% increment by the number of elements added before we get to each index

IDX = IDX(:) + [0:length(IDX) - 1]';

for i = 1:length(IDX)

    if DIM == 1
        MAT = [MAT(1:IDX(i), :); VAL(i, :); MAT(IDX(i) + 1:end, :)];
    elseif DIM == 2
        MAT = [MAT(:, 1:IDX(i)) VAL(:, i) MAT(:, IDX(i) + 1:end)];
    end

end

% actual indices are 1 to the right

IDX = IDX + 1;
