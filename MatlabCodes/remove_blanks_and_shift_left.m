function data_no_blanks = remove_blanks_and_shift_left(data)
    % Initialize the modified data matrix
    data_no_blanks = data;

    % Loop through each row
    for i = 1:size(data_no_blanks, 1)
        row = data_no_blanks(i, :); % Extract the current row

        % Find indices of non-NaN elements
        non_nan_indices = ~isnan(row);

        % Remove NaN elements and shift cells left
        row = row(non_nan_indices);
        
        % Update the row in the modified data matrix
        data_no_blanks(i, 1:numel(row)) = row;
    end
end
