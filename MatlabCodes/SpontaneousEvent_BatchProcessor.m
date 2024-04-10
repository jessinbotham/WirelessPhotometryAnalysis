% Analyzes a folder containing .csv files each with timestamped data and  
% session signal data in columns A and B, respectively. 
% The file names should be saved as the
% "ID_SessionInfo_X" where X=any information you do not 
% need as an identifier when pulling data from the file. 
% NOTE: Underscore delimeters are necessary!

% The user is prompted to select a folder containing .csv files with the appropriate labels
% Then user must enter:
% Name for summary data file to be generated
% Min Peak Prominence for analysis
% Min and Max Peak width for analysis

% Individual File Data is compiled into a 'results' folder
% A pop up notification lets the user know once the entire folder has been
% analyzed

% Get folder directory from the user
folderPath = uigetdir(pwd, 'Select the folder containing the data files to analyze');
if folderPath == 0
    error('Folder selection cancelled by user.');
end

% Prompt user for summary table name and findpeaks parameters
prompt = {'Enter the name for the summary data table (without extension):', ...
          'Enter the minimum peak prominence:', ...
          'Enter the minimum peak width in seconds:', ...
          'Enter the maximum peak width in seconds:'};
title = 'Input';
dims = [1 50; 1 25; 1 25; 1 25];
definput = {'SummaryData', '1.5', '0.15', '5'}; % Default values
inputData = inputdlg(prompt, title, dims, definput);
if isempty(inputData)
    error('Input cancelled by user.');
end

% Unpack input data
summaryTableName = inputData{1};
MinPeakProminence = str2double(inputData{2});
MinPeakWidth = str2double(inputData{3});
MaxPeakWidth = str2double(inputData{4});

% Define the summary table to store summary data
summaryTable = table('Size', [0, 10], 'VariableTypes', ["string", "string", "double", "double", "double", "double", "double", "double", "double", "double"], 'VariableNames', ["ID", "Session", "PeaksCounted", "InterEventInterval", "Frequency_Hz", "MeanWidth", "MeanProminence", "MinPeakProminence", "MinPeakWidth", "MaxPeakWidth"]);

% Create a "results" folder inside the selected folder
resultsFolderPath = fullfile(folderPath, 'results');
if ~exist(resultsFolderPath, 'dir')
    mkdir(resultsFolderPath);
end

% Start loop to analyze each file and update summary table
fileList = dir(fullfile(folderPath, '*.csv'));
if isempty(fileList)
    error('No CSV files found in the specified folder.');
end

for i = 1:length(fileList)
    fileName = fullfile(folderPath, fileList(i).name);
    fprintf('Analyzing file: %s\n', fileName);
    
    % Analyze the current file using SpontaneousActivity_BatchProcessor function
    [ID, Session, Peaks, Frequency, Width, Prominence, minPeakProminenceUsed, minPeakWidthUsed, maxPeakWidthUsed] = SpontaneousActivity_BatchProcessor(fileName, resultsFolderPath, MinPeakProminence, MinPeakWidth, MaxPeakWidth);
    
    % Convert frequency to Hz
    Frequency_Hz = 1 / Frequency; % Calculate the reciprocal
    
    % Update summary table with the analyzed data, findpeaks parameters, and frequency in Hz
    newRow = {ID, Session, Peaks, Frequency, Frequency_Hz, Width, Prominence, minPeakProminenceUsed, minPeakWidthUsed, maxPeakWidthUsed};
    summaryTable = [summaryTable; newRow];
end

% Save summary table to a file
summaryTableFileName = fullfile(folderPath, strcat(summaryTableName, '.xlsx'));
writetable(summaryTable, summaryTableFileName, 'FileType', 'spreadsheet');

% Close all open plots
close all;

% Display pop-up message
msgbox('Folder analysis complete and summary data updated.');

function [ID, Session, Peaks, Frequency, Width, Prominence, minPeakProminenceUsed, minPeakWidthUsed, maxPeakWidthUsed] = SpontaneousActivity_BatchProcessor(fileName, resultsFolderPath, MinPeakProminence, MinPeakWidth, MaxPeakWidth)
    close;
    
    % Filename for analysis
    [~, baseFileName, ~] = fileparts(fileName);
    c = regexp(baseFileName, '_', 'split');
    ID = c{1};
    Session = c{2};

    % Read data from the selected file
    t = readtable(fileName, 'Range', 'B:B');
    RawTrace = table2array(t);

    % Curve fitting to a double exponential
    seconds = (0.01:0.01:height(RawTrace)/100)';
    f = fit(seconds, RawTrace, 'exp2', 'normalize', 'off');

    % Plot of data and curve fit
    graph = figure;
    subplot(3, 2, 1, 'parent', graph)
    x = seconds;
    plot(f, seconds, RawTrace)
    title('Raw Data & Curve Fit')
    xlabel('seconds')
    ylabel('AU')
    fprintf('Curve Fitting Complete.\n');

    % Generate new data trace and normalize and plot
    fd = RawTrace - f(seconds);
    zff = zscore(fd);
    subplot(3, 2, 2, 'parent', graph)
    plot(x, zff)
    title('Normalized Data')
    xlabel('seconds')
    ylabel('dF/F')
    fprintf('Data Normalized.\n');

    % Find peaks in data with user-provided parameters
    [pk, loc, widths, proms] = findpeaks(zff, seconds, 'MinPeakProminence', MinPeakProminence, 'MinPeakWidth', MinPeakWidth, 'MaxPeakWidth', MaxPeakWidth, 'Annotate', 'extents', 'WidthReference', 'halfheight');  
    
    % Plot peaks
    subplot(3, 2, [3, 4], 'parent', graph)
    plot(seconds, zff, loc, pk, 'or')
    title('Peaks')
    xlabel('seconds')
    ylabel('dF/F')
    fprintf('Peaks analyzed.\n');

    % Find interval of peaks (frequency)
    pkInt = diff(loc);
    Peaks = height(pk);
    Frequency = mean(diff(loc));
    Width = mean(widths);
    Prominence = mean(proms);
    subplot(3, 2, 5, 'parent', graph)
    title('Frequency Histogram');
    histogram(pkInt)
    xlabel('seconds')
    ylabel('frequency')
    fprintf('Peak Frequency Analyzed.\n');

    % Datatable of individual data points
    Output = table(pk, loc, widths, proms);
    label = [ID, Session, "Peaks"];
    fname = fullfile(resultsFolderPath, join(label));
    writetable(Output, fname, 'FileType', 'spreadsheet');
    saveas(graph, fname, 'fig');
    fname = fullfile(resultsFolderPath, strjoin(label, '_'));

    % Return analyzed data for summary, findpeaks parameters used, and frequency in Hz
    minPeakProminenceUsed = MinPeakProminence;
    minPeakWidthUsed = MinPeakWidth;
    maxPeakWidthUsed = MaxPeakWidth;
end

