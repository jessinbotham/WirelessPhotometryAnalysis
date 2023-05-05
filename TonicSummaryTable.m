%Creates a summary table excel file to add individual trial event data
%Data files should be in a .csv file with the timestamp data in column A
%and the signal data in column B. Note: that code is for data that does not
%contain a control channel. The file name is saved as the
%"ID_SessionInfo_X" where X=any information you do not need as an identifier
%when pulling data from the file. Underscore delimeters are necessary.
sz=[1 6];
varTypes=["string","string","double","double","double","double"];
varNames=["ID","Day","Peaks","Frequency","Width","Prominence"];
summary=table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
%Edit "Tonic_Summary_Example" to desired file name
writetable(summary,"Tonic_Summary_Example",'FileType','Spreadsheet');