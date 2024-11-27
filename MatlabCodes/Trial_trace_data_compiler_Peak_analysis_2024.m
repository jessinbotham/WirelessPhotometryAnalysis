
% Use this script after RawDataPreProcessing and extraction of trial trace
% data with pMat to compile trial trace data, transform raw data into
% z-scores, and perform the peak analysis for each trial

% Start by selecting the folder where trial trace data .csv files are saved
% and specify the time parameters used to extract the trials. Users are
% prompted to designate thresholds for peak detection. The trials are
% compiled into a single excel workbook and the file names are used as ID
% and group/session variables. Separate sheets of the workbook contain
% z-scores, peaks, locations, prominences, and widths.

% Prompt the user to select a folder
folder = uigetdir('Select a folder containing CSV files');

% Prompt the user to enter the summary file name
prompt = {'Enter the name of the summary file (without extension):'};
dlgtitle = 'Summary File Name';
dims = [1 50];
definput = {'summary'}; % Default summary file name
summary_name = inputdlg(prompt, dlgtitle, dims, definput);

% Check if the user canceled the input dialog
if isempty(summary_name)
    disp('User canceled the operation.');
    return;
end

% Get a list of all CSV files in the selected folder
files = dir(fullfile(folder, '*.csv'));
num_files = length(files);

% Initialize a cell array to store data
summary_data = {};

% Loop through each CSV file to extract data
for i = 1:num_files
    file_path = fullfile(folder, files(i).name);
    
    % Extract ID and Session from the file name
    [~, baseFileName, ~] = fileparts(files(i).name);
    c = regexp(baseFileName, '_', 'split');
    
    % Ensure that the file name is correctly split
    if numel(c) < 2
        disp(['Skipping file ', files(i).name, ' because it does not match the expected naming convention.']);
        continue; % Skip to the next file
    end
    
    ID = c{1};
    Session = c{2};
    
    % Read the CSV file
    tbl = readtable(file_path);
    
    % Append ID and Session to the data
    num_rows = height(tbl);
    IDs = repmat({ID}, num_rows, 1);
    Sessions = repmat({Session}, num_rows, 1);
    
    % Extract data from the table
    data = tbl{:, 1:end}; % Include all columns
    
    % Combine ID, Session, and data
    combined_data = [IDs, Sessions, num2cell(data)];
    
    % Append to the summary data
    summary_data = [summary_data; combined_data];
end

% Create variable names
var_names = [{'ID'}, {'Session'}, tbl.Properties.VariableNames(:)'];

% Convert cell array to a table
summary_table = cell2table(summary_data, 'VariableNames', var_names);

% Construct the file path for the summary Excel file
summary_excel_path = fullfile(folder, [summary_name{1}, '.xlsx']);

% Write the table to the first sheet of the Excel file
writetable(summary_table, summary_excel_path, 'Sheet', 'RawData');

% Open the Excel file and read the data
excel_data = readtable(summary_excel_path, 'Sheet', 'RawData');

% Copy ID and Session information to the second sheet
id_session_data = excel_data(:, 1:2);
writetable(id_session_data, summary_excel_path, 'Sheet', 'ZScores', 'Range', 'A1');

% Transform the remaining data using z-score
remaining_data = excel_data(:, 3:end);
zscore_data = array2table(zscore(table2array(remaining_data), 0, 2), 'VariableNames', remaining_data.Properties.VariableNames);
writetable(zscore_data, summary_excel_path, 'Sheet', 'ZScores', 'Range', 'C1');

% Create the variable named as specified by the user for Summary File Name in the MATLAB workspace
var_name = matlab.lang.makeValidName([summary_name{1}, '_zscores']); % Ensure a valid variable name
eval([var_name, ' = table2array(zscore_data);']);

% Prompt the user to enter the start time, increment, and end time for s
prompt = {'Start Time:', 'Increment:', 'End Time:'};
dlgtitle = 'Enter Time Parameters';
dims = [1 50];
definput = {'-10', '0.5', '20'}; % Default values
time_params = inputdlg(prompt, dlgtitle, dims, definput);

% Convert the inputs to numeric values
start_time = str2double(time_params{1});
increment = str2double(time_params{2});
end_time = str2double(time_params{3});

% Create s based on user inputs
s = start_time:increment:end_time;

% Prompt the user to enter the time range for peak detection
prompt = {'Start Time for Peak Detection:', 'End Time for Peak Detection:'};
dlgtitle = 'Enter Peak Detection Time Range';
time_range_params = inputdlg(prompt, dlgtitle, dims, {'0', '10'}); % Default values for the time range

% Convert the inputs to numeric values
peak_start_time = str2double(time_range_params{1});
peak_end_time = str2double(time_range_params{2});

% Filter the time vector s to the specified range
time_range_filter = (s >= peak_start_time) & (s <= peak_end_time);
s_filtered = s(time_range_filter);

% Prompt the user to enter the peak detection parameters
prompt = {'Min Peak Prominence:', 'Min Peak Width (s):', 'Max Peak Width (s):'};
dlgtitle = 'Enter Peak Detection Parameters';
dims = [1 50];
definput = {'1.5', '1', '6'}; % Default values
peak_params = inputdlg(prompt, dlgtitle, dims, definput);

% Convert the inputs to numeric values
MinProm = str2double(peak_params{1});
MinWidth = str2double(peak_params{2});
MaxWidth = str2double(peak_params{3});

% Execute the provided code with the created variable 'T1'
T1 = eval(var_name); % Replace %%%%%T1 with the variable name

% Initialize cell arrays to store peaks, locations, widths, and prominences
P = cell(size(T1, 1), 1);
L = cell(size(T1, 1), 1);
W = cell(size(T1, 1), 1);
Pr = cell(size(T1, 1), 1);

% Loop over each row of T1 to find peaks and related information
for k1 = 1:size(T1, 1)
    % Filter the data to match the filtered time vector
    data = T1(k1, :);
    data_filtered = data(time_range_filter);
    
    if ~isempty(data_filtered) % Check if the filtered data is not empty
        [pk, loc, widths, proms] = findpeaks(data_filtered, s_filtered, 'MinPeakProminence', MinProm, 'MinPeakWidth', MinWidth, 'MaxPeakWidth', MaxWidth, 'Annotate', 'extents', 'WidthReference', 'halfheight');
        P{k1} = pk; % Peaks
        L{k1} = loc; % Locations
        W{k1} = widths; % Widths
        Pr{k1} = proms; % Prominences
    else
        % If the filtered data is empty, assign empty arrays
        P{k1} = [];
        L{k1} = [];
        W{k1} = [];
        Pr{k1} = [];
    end
end

% Convert cell arrays to matrices
TPk = cellToMatrix(P);
TL = cellToMatrix(L);
TW = cellToMatrix(W);
TPr = cellToMatrix(Pr);

% Write Peak data to Excel
writematrix(TPk, summary_excel_path, 'Sheet', 'Peaks');

% Write Location data to Excel
writematrix(TL, summary_excel_path, 'Sheet', 'Location');

% Write Width data to Excel
writematrix(TW, summary_excel_path, 'Sheet', 'Width');

% Write Prominence data to Excel
writematrix(TPr, summary_excel_path, 'Sheet', 'Prominence');

msgbox('Trial trace data compilation and analysis saved to designated summary file');

% Function to convert a cell array of numeric vectors to a matrix, padding with NaNs
function result = cellToMatrix(cellArray)
    % Convert a cell array of numeric vectors to a matrix, padding with NaNs
    maxLength = max(cellfun(@numel, cellArray));
    result = nan(numel(cellArray), maxLength);
    for i = 1:numel(cellArray)
        result(i, 1:numel(cellArray{i})) = cellArray{i};
    end
end
