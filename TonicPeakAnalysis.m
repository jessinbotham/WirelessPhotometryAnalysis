%%First use TonicSummaryTable to create spreadsheet for summary data
%Analysis for Raw data in second column at ms time intervals
%Files with '_' delimiter and no '.' in filenames
%Data should have no NaN values. Use the example file
%'ExampleID_SessionDay_ExampleSignalFile.csv'
%Once 'Summary data updated.' is printed in the command window, the
%function can be restarted to choose another file. Summary data will be
%saved to the summary data file and individual file data will be save to a
%spreadsheet and figure.

%Start the function and user is prompted to choose the data file
function PhotometryPeaks();
close;
startingFolder = pwd;  % or 'C:\wherever';
if ~exist(startingFolder, 'dir')
	% If that folder doesn't exist, just start in the current folder.
	startingFolder = pwd;
end
% Get the name of the file that the user wants to use.   
defaultFileName = fullfile(startingFolder, '*.*');
    [baseFileName, folder] = uigetfile(defaultFileName, 'Select a file');
        %Filename for analysis
        c=regexp(baseFileName, '_', 'split');
        %Get File parts for data labels
        ID=c{1};
        Day=c{2};

            t=readtable(baseFileName,'Range','B:B');
            RawTrace=table2array(t);
            %d=column data of raw signal data


            %Curve fitting to a double exponential
            seconds=(0.01:0.01:height(RawTrace)/100)'; %generate time vector for curve fitting in s
            f=fit(seconds,RawTrace,'exp2','normalize','off'); %double exponential curve fit

            %plot of data and curve fit
            graph=figure;
            subplot(3,2,1,'parent',graph)
            x=seconds;
            plot(f,seconds,RawTrace)
            title('Raw Data & Curve Fit')
            xlabel('seconds')
            ylabel('AU')
            fprintf('Curve Fitting Complete.\n');
            %Generate new data trace and normalize and plot
            fd=RawTrace-f(seconds);%subtract fit data from raw data
            zff=zscore(fd);%zscore of fit data
            subplot(3,2,2,'parent',graph)
            plot(x,zff)
            title('Normalized Data')
            xlabel('seconds')
            ylabel('dF/F')
            fprintf('Data Normalized.\n');
            %find peaks in data
            %MinPeakWidth is half-prominence. Set to 0.15s (150 ms)
            [pk,loc,widths,proms]=findpeaks(zff,seconds,'MinPeakProminence',1.2, 'MinPeakWidth',0.15,'MaxPeakWidth',10,'Annotate','extents','WidthReference','halfheight');  
            subplot(3,2,[3,4],'parent',graph)
            plot(seconds,zff,loc,pk,'or')
            title('Peaks')
            xlabel('seconds')
            ylabel('dF/F')
            fprintf('Peaks analyzed.\n');
            %find interval of peaks(frequency)
            pkInt=diff(loc);
            Peaks=height(pk);
            Frequency= mean(diff(loc));
            Width=mean(widths);
            Prominence=mean(proms);
            subplot(3,2,5,'parent',graph)
            title('Frequency Histogram');
            histogram(pkInt)
            xlabel('seconds')
            ylabel('frequency')
            fprintf('Peak Frequency Analyzed.\n');

            %datatable of individual data points
            Output = table(pk, loc, widths, proms);
            label=[ID,Day,"Peaks"];
            fname= join(label);
            %Save table with unique file name
            writetable(Output,fname,'FileType','spreadsheet');
            %Save Figure with curve fitting and histogram plot
            saveas(graph,fname,'fig');
            fprintf(fname+" Data Saved.\n")

            %Adding summary data to summary file. The file name MUST match
            %the name designated when creating the summary table
            newRow={ID,Day,Peaks,Frequency,Width,Prominence};
            [numbers,strings,raw]=xlsread('Tonic_Summary_Example.xls');
            lastRow=size(raw,1);
            nextRow= lastRow + 1;
            cellReference = sprintf('A%d', nextRow);
            xlswrite('Tonic_Summary_Example.xls', newRow,'Sheet1', cellReference);
            fprintf('Summary data updated.\n');
end
