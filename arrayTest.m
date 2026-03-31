% Example 2D array
A = [1, 5, 3; 8, 2, 6; 4, 7, 9];

% Find the maximum value and its linear index
[maxValue, linearIndex] = max(A(:));

% Convert the linear index to row and column indices
[row, col] = ind2sub(size(A), linearIndex);

% Display the results
disp(['Maximum value: ', num2str(maxValue)]);
disp(['Row index: ', num2str(row)]);
disp(['Column index: ', num2str(col)]);