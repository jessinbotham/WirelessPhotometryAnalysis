%This script can be used to compile trial trace data after it is extracted
%with pMAT. When prompted to select a folder, you should select the 'Data'
%folder generated with pMAT. The summary file will compile ID and session
%info based on the first two variables of the file name separated by an
%underscore delimiter. e.g. ANIMALID_SESSION2_otherinfonotincluded.csv

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
var_names = {'ID', 'Session', tbl.Properties.VariableNames{:}};

% Convert cell array to a table
summary_table = cell2table(summary_data, 'VariableNames', var_names);

% Construct the file path for the summary Excel file
summary_excel_path = fullfile(folder, [summary_name{1}, '.xlsx']);

% Write the table to Excel
writetable(summary_table, summary_excel_path);

disp(['Summary Excel file saved as: ', summary_excel_path]);
