%This code measures parameters for each individual trial. Data containing
%zscores of trial trace data (obtained with pMat) should be organized into
%rows.
%Load the EventDataExample File before running this script.

%T1 = your data table name with zscores for each trial in rows
%Use the TraceDataExample file containing 25 trials from -1 to 5s
%relative to the reinforced lever response in 0.5s bins (13 columns) 
T1=EventDataExample 

%Determine timepoints within each trial to measure the event parameters.
%The example file (TraceDataExample) contains trials binned in 0.5s
%intervals (determined in pMAt). s=the time in seconds to detect peaks.
%The example below will measure peaks within -1 to 5s relative to T0
s=-1:0.5:5 
for k1=1:size(T1,1)
    [pk,loc,widths,proms]=findpeaks(T1(k1,:),s,'MinPeakProminence',1.5, 'MinPeakWidth',0.15);
    P{k1}=[pk]; %peaks_subset
    L{k1}=[loc]; %locationss_subset
    W{k1}=[widths]; %widths_subset
    Pr{k1}=[proms]; %prominence_subset
end


TPk=transpose(P);
TL=transpose(L);
TW=transpose(W);
TPr=transpose(Pr);


n = cellfun(@numel,TPk);
k = cumsum(n);
ii = k-n+1;
v = ones(k(end),1);


%Writes excel file containing the Peak within the region for each trial
A = accumarray([repelem((1:numel(n))',n),cumsum(v)],[TPk{:}]',[],[],nan);
xlswrite('EventData_Peaks.xlsx',A); 

r = cellfun(@numel,TL);
q = cumsum(r);
iii = q - r + 1;
w = ones(q(end),1);

%Writes excel file containing the Location of the Peak within the region for each trial
B = accumarray([repelem((1:numel(r))',r),cumsum(w)],[TL{:}]',[],[],nan);
xlswrite('EventData_Location.xlsx',B);

nn = cellfun(@numel,TW);
kk = cumsum(nn);
iit = kk - nn + 1;
vv = ones(kk(end),1);

%Writes excel file containing the Peak Width within the region for each trial
AA = accumarray([repelem((1:numel(nn))',nn),cumsum(vv)],[TW{:}]',[],[],nan);
xlswrite('EventData_width.xlsx',AA);

rr = cellfun(@numel,TPr);
qq = cumsum(rr);
iio = qq - rr + 1;
ww = ones(qq(end),1);

%Writes excel file containing the Prominence (rise above surrounding values) within the region for each trial
BB = accumarray([repelem((1:numel(rr))',rr),cumsum(ww)],[TPr{:}]',[],[],nan);
xlswrite('EventData_prominence.xlsx',BB);

