The most recent version of these codes can be found in the **MatlabCodes folder**

Scripts are written for batch processing and analysis of _Telefipho_ wireless photometry data.

Raw data files should be saved as .txt files with the first two identifiers separated by an underscore delimiter. 
Use sample data files in the SampleData folder for example
Folder for analysis and codes should be saved in the matlab workspace before running

**REQUIREMENTS:**
Event data is extracted using the pMAT suite. For use of these codes with event data:
Start by downloading Matlab and installing pMAT.
Installation and user guide can be found here: https://github.com/djamesbarker/pMAT 
Other prerequisites include the remove_blanks_and_shift_left.m function in the MatlabCodes folder
Codes are intended to be used in the order described below. 
Enter 'clear' in the command window before running each script.

**WORKFLOW:**


**_1. RawDataPreprocessing.m_**
   Compiles and cleans a folder of Telefipho raw data files with event pairing saved in .txt format (see SampleData for example)
   1. The user is prompted to select the folder for analysis
   2. The user is prompted to select the number of rows to remove from the file to account for artifacts at the start of the recording. Use values of at least 20 (0.2 s) for sample data files
   3. For Telefipho users, static artifacts coded as 32768 are removed from the signal and filled with the next detected value. If more than 500 occurrences are found, then users will be warned at the end with a popup indicating which files should be reexamined for inconsistencies and extensive loss of signal
   4. Underscore delimiters in the filename are used to generate filenames for .csv files created by this script
   5. The _SignalFile consists of the raw signal data with artifacts removed aligned to time and a control channel is generated using an exponential fit
   6. The _EventData consists of the events coded as TRUE or FALSE indicated by a drop in voltage (<3V) in the second channel during recording. Events are aligned to time
   7. The _SignalFile and _EventData for each .txt file are saved for processing with pMAT. A copy of the signal files are also saved to a separate folder, Signal Files, for SpontaneousEvent_BatchProcessor.m
   8. The user is notified once the file saves are completed. A warning message including files with a large number of artifacts notifies the user of file abnormalities if present.

**_2. SpontaneousEvent_BatchProcessor.m_**
  Utilizes the Signal Files folder created with the RawDataPreprocessing.m to measure spontaneous peaks (not paired with behavior) throughout a recording file
  1.  User is prompted to select the directory location of Signal Files
  2.  User enters a name for the summary data file and specifies the detection parameters to use with the find peaks function
  3.  The signal is fit to a double exponential curve and a plot is generated with the fit signal and peaks detected for each file to allow the user to assess the detection parameters. When re-running the script using different parameters, users should enter 'clear' in the command window before proceeding
  4.  For each file in the folder, a figure is saved containing the raw data, exponential fit, fit data with detected peaks circled, and a frequency distribution plot of the events detected. A separate .csv file containing all of the peaks detected for the recording file is generated. The plots and individual .csv file are saved to a "results" folder.
  5.  The specified summary data file compiles the identifying information obtained from the file name and the mean inter-event interval, frequency in Hz, peak height, prominence, width, and parameters used for detection

**_3. TrialTraceData_compiler.m_** and versions
   These scripts are meant to be used AFTER extracting trail trace data (behavioral event paired) in pMAT suite. When using pMAT, underscore delimiters for file naming is necessary to maintain identifiers.
   The pMAT suite will save trial trace data to a separate 'Data' folder which should be used when running these scripts.
   1. TrialTraceData_compiler.m prompts users to locate the Data folder containing trial trace data.
   2. Users designate a filename for the summary file to be created with identifiers and trial data aligned into a single sheet
   
   To include z-score data and peak detection for each trial use the **_TrialTraceDataCompiler_withPeakAnalysis.m_**
   1. TrialTraceData_compiler.m prompts users to locate the Data folder containing trial trace data.
   2. Users designate a filename for the summary file to be created with identifiers and trial data aligned into a single sheet
   3. Users are prompted to enter the time parameters (Start Time, Increment, End Time) used to isolate events in pMAT (Pre Time (s), Bin Constant, Post Time (s)). NOTE: Converting the Bin Constant into Increments (s) users should note the sampling frequency. e.g. For 100 hz sampling, a Bin Constant of 50 equals an Increment of 0.5 s
   4. Users are also prompted for peak detection parameters to use with find peaks function
   5. Summary File saved with this script adds additional sheets for z-scores aligned by identifiers, Peaks, Locations, Prominences, and Widths. Note that peak parameters are not aligned with identifiers in the new workbook but are maintained in the same order as the raw data and z-score sheets so users should copy this information over before sorting data in the summary file.
   6. A pop-up window notifies the user that the compilation is completed
   
   _NOTE: warning messages may appear indicating that a specified worksheet was added to the workbook. These warnings are not errors and should be ignored._
  
   To include z-score data, peak detection, and AUC for each trial, use the **_TrialTraceDataCompiler_withPeakAnalysis_withAUC.m_**
   1. Users locate the Data folder containing trial trace data.
   2. Users designate a filename for the summary file to be created with identifiers and trial data aligned into a single sheet
   3. Users are prompted to enter the time parameters (Start Time, Increment, End Time) used to isolate events in pMAT (Pre Time (s), Bin Constant, Post Time (s)). NOTE: Converting the Bin Constant into Increments (s) users should note the sampling frequency. e.g. For 100 hz sampling, a Bin Constant of 50 equals an Increment of 0.5 s
   4. Users are also prompted for peak detection parameters to use with find peaks function
   5. Users are finally prompted to enter up to 10 increments for AUC measurements. The default values range from -6 to 12 s in 2-s intervals
   6. Summary File saved with this script adds additional sheets for z-scores aligned by identifiers, Peaks, Locations, Prominences, Widths, and AUC. Note that peak parameters and AUC are not aligned with identifiers in the new workbook but are maintained in the same order as the raw data and z-score sheets so users should copy this information over before sorting data in the summary file.
   7. A pop-up window notifies the user that the compilation is completed
   
   _NOTE: warning messages may appear indicating that a specified worksheet was added to the workbook. These warnings are not errors and should be ignored._

