%Preprocessing script for Telefipho Wireless Photometry .txt data for integration 
%with pMAT suite for extracting event data. 

%Main functions of the script are to
%Batch process a folder of text files
%Remove artifacts at the start of the session
%Remove static artifacts in the recording coded as 32768 and replace with the 
%nearest value
%Perform an exponential fit on signal and time data to generate control channel
%Split files into signal and event .csv files for pMAT
%Create a separate folder for a copy of signal files for integration with the
%SpontaneousEvent_BatchProcessor.m 

%See ReadMe for full details on running this script

%Prompting user to select the directory containing .txt files containing
%raw data 
folderpath = uigetdir('', 'Select the directory containing .txt files');

% Checking if the user cancels the selection
if isequal(folderpath,0)
    disp('No directory selected. Exiting script.');
    return;
end

% Create a new directory for signal files
signal_folderpath = fullfile(folderpath, 'Signal Files');
if ~exist(signal_folderpath, 'dir')
    mkdir(signal_folderpath);
end

% Listing all .txt files in the selected directory
txtFiles = dir(fullfile(folderpath, '*.txt'));

% Checking if there are any .txt files in the directory
if isempty(txtFiles)
    disp('No .txt files found in the selected directory. Exiting script.');
    return;
end

% Initialize summary string
summary_str = '';

% Prompting user to input the number of rows to remove from the top
num_rows_to_remove = inputdlg('Enter the number of rows to remove from the start of the recording. (Ex: 100 Hz sampling = 100 rows/second) :', 'Number of Rows');

% Checking if the user cancels the input
if isempty(num_rows_to_remove)
    disp('No value entered. Exiting script.');
    return;
end

% Converting input to numeric value
num_rows_to_remove = str2double(num_rows_to_remove{1});

% Processing each .txt file in the directory
for i = 1:length(txtFiles)
    filename = txtFiles(i).name;
    filepath = fullfile(folderpath, filename);
    
    % Reading the .txt file with tab delimiters
    data = readtable(filepath, 'Delimiter', '\t');
    
    % Renaming columns
    data.Properties.VariableNames{'Var1'} = 'Timestamp';
    data.Properties.VariableNames{'Var2'} = 'Signal';
    data.Properties.VariableNames{'Var3'} = 'Events';
    
    % Removing specified number of rows from the top
    if num_rows_to_remove > 0
        data = data(num_rows_to_remove+1:end, :);
    end

    % Counting the number of occurrences of '32768'
    num_32768_values = sum(data.Signal == 32768);
    
    if num_32768_values > 500
        % Update summary string
        summary_str = [summary_str, sprintf('Signal and Event Data Extraction Complete! \n %d missing values detected in file %s.\n Check raw data files for accuracy.', num_32768_values, filename)];
    end
        
    % Replacing '32768' with the previous value
    for j = 2:height(data)  % Start from the second row
        if data.Signal(j) == 32768
            data.Signal(j) = data.Signal(j - 1);
        end
    end
    
    % Fit a exponential trend line to columns A and B
    exponentialFit = fit(data.Timestamp, data.Signal, 'exp2'); 
    
    % Generate values for the "Control" column using the equation
    data.Control = exponentialFit(data.Timestamp);
    
    % Constructing the name for the output .csv file for the signal
    [~, file_name, ~] = fileparts(filename);
    csv_file_name = [file_name '_SignalFile.csv'];
    csv_file_path = fullfile(folderpath, csv_file_name);
    
    % Selecting and renaming columns for the SignalFile
    SignalFileData = data(:, {'Timestamp', 'Signal', 'Control'});
    
    % Writing the data to the .csv file
    writetable(SignalFileData, csv_file_path);
    
    disp(['Signal Data File created for ', filename, ' in ', csv_file_path]);
    
    % Copying the signal file to the "Signal Files" directory
    copyfile(csv_file_path, fullfile(signal_folderpath, csv_file_name));
    
    disp(['Copy of Signal Data File for ', filename, ' saved in "Signal Files" directory.']);
    
    % Creating second .csv file with values from the original .txt file
    EventData = table(data.Events, data.Timestamp, data.Timestamp, ...
    'VariableNames', {'Events', 'Onset', 'Offset'});
    
    % Applying the formula to change values in column A
    EventData.Events = arrayfun(@(x) {double(x < 3)}, EventData.Events);
    
    % Replace numeric values with string values
    EventData.Events = replace(string(EventData.Events), {'0', '1'}, {'FALSE', 'TRUE'});

    % Constructing the name for the second output .csv file
    event_csv_file_name = [file_name '_EventData.csv'];
    event_csv_file_path = fullfile(folderpath, event_csv_file_name);
    
    % Writing the data to the second .csv file
    writetable(EventData, event_csv_file_path);
    
    disp(['Event Data File created for ', filename, ' in ', event_csv_file_path]);
end

% Display summary of files with more than 500 '32768' values
if ~isempty(summary_str)
    msgbox(summary_str, 'Summary', 'warn');
else
    msgbox('Signal and Event Data Extraction Complete!\n No files with more than 500 "32768" values detected.', 'Summary');
end
