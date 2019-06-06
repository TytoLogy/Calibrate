%--------------------------------------------------------------------------
% Calibrate_Test.m
%--------------------------------------------------------------------------
%  Script that tests the calibration protocol
%    This script is called by Calibrate.m (buttonTestCalibration callback)
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Sharad Shanbhag
% sshanbhag@neomed.edu
%--------------------------------------------------------------------------
% Evolving Version Written (Calibrate): 22 Oct 2017 by SJS
%------------------------------------------------------------------------
% Notes:
%------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial setup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% display message
str = 'Initial setup for calibration test'; 
set(handles.textMessage, 'String', str);
% general constants
L = 1; 
R = 2;
MAX_ATTEN = 120;
% making a local copy of the cal settings structure
cal = handles.h2.cal;
% load calibration data
[calfile, calpath] = uigetfile('*_cal.mat;*.cal;*.mat', ...
												'Load CAL Data', ...
												'C:\TytoLogy\Experiments\CalData');
if calfile == 0
	str = 'Calibration Test cancelled';
	handles.h2.COMPLETE = 0;
	update_ui_str(handles.textMessage, str);
	guidata(hObject, handles);
	return
else
	caldata = load_cal(fullfile(calpath, calfile));
end

% if user has chosen to use Microphone Frequency response
% we need to make sure the data are loaded.
if cal.UseFR
	fr = handles.h2.fr;
	% check if FR files are loaded
	switch cal.Side 
		 case 'BOTH' 
			  if ~(fr.loadedR && fr.loadedL)
					str = 'Load FR files (L and R) before calibration!'; 
					set(handles.textMessage, 'String', str);
					errordlg(str, 'FR file error');
					return;
			  end
			  cal.frL = fr.frdataL; 
			  cal.frR = fr.frdataR; 
			  cal.frfileL = fr.frfileL;
			  cal.frfileR = fr.frfileR;

		 case 'LEFT'
			  if ~fr.loadedL
					str = 'Load FR file (L) before calibration!'; 
					set(handles.textMessage, 'String', str);
					errordlg(str, 'FR file error');
					return;
			  end
			  cal.frL = fr.frdataL; 
			  cal.frR = fake_FR; % dummy data struct for R
			  cal.frfileL = fr.frfileL;
			  cal.frfileR = [];

		 case 'RIGHT'
			  if ~fr.loadedR
					str = 'Load FR file (R) before calibration!'; 
					set(handles.textMessage, 'String', str);
					errordlg(str, 'FR file error');
					return;
			  end
			  cal.frL = fake_FR; % dummy data struct for L
			  cal.frR = fr.frdataR; 
			  cal.frfileL = [];
			  cal.frfileR = fr.frfileR;
	end
else
	cal.frL = fake_FR;
	cal.frR = fake_FR;
end

% I/O channels
cal.OutChanL = handles.h2.config.OutChanL;
cal.OutChanR = handles.h2.config.OutChanR;
cal.InChanL = handles.h2.config.InChanL;
cal.InChanR = handles.h2.config.InChanR;
% Calibration Microphone Settings
if cal.UseFR
	% get microphone settings from the FR data struct
	cal.RefMicSens = [cal.frL.cal.RefMicSens cal.frR.cal.RefMicSens];
	cal.MicGain_dB = [cal.frL.cal.MicGain_dB cal.frR.cal.MicGain_dB];
else
	% get microphone settings that were entered in GUI
	cal.RefMicSens = [cal.MicSenseL cal.MicSenseR];
	cal.MicGain_dB = [cal.MicGainL_dB cal.MicGainR_dB];
end
% pre-compute some conversion factors:
% Volts to Pascal factor
cal.VtoPa = cal.RefMicSens.^-1;
% mic gain factor
cal.MicGain = 10.^(cal.MicGain_dB./20);

% Frequencies
cal.F = [cal.Fmin cal.Fstep cal.Fmax];
cal.Freqs = cal.Fmin : cal.Fstep : cal.Fmax;
cal.Nfreqs = length(cal.Freqs);
% pre-compute the sinusoid RMS factor
cal.RMSsin = 1/sqrt(2);  

% check low freq limit
if cal.Freqs(1) < max( cal.frL.Freqs(1), cal.frR.Freqs(1) )
    str = 'requested LF calibration limit is out of FR file bounds'; 
    set(handles.textMessage, 'String', str);
    errordlg(str, 'FR file error');
    return;
end
% check high freq limit
if cal.Freqs(end) > min( cal.frL.Freqs(end), cal.frR.Freqs(end) )
    str = 'requested HF calibration limit is out of FR file bounds'; 
    set(handles.textMessage, 'String', str);
    errordlg(str, 'FR file error');
    return;
end

% fetch the L and R headphone mic adjustment values for the 
% calibration frequencies using interpolation
cal.frL.magadjval = interp1(cal.frL.Freqs, cal.frL.adjmag, cal.Freqs);
cal.frR.magadjval = interp1(cal.frR.Freqs, cal.frR.adjmag, cal.Freqs);
cal.frL.phiadjval = interp1(cal.frL.Freqs, cal.frL.adjphi, cal.Freqs);
cal.frR.phiadjval = interp1(cal.frR.Freqs, cal.frR.adjphi, cal.Freqs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize the TDT devices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% display message
str = 'Initializing TDT'; 
set(handles.textMessage, 'String', str);
% make a local copy of the TDT config settings structure
config = handles.h2.config; 
% make iodev structure
iodev.Circuit_Path = config.Circuit_Path;
iodev.Circuit_Name = config.Circuit_Name;
iodev.Dnum = config.Dnum; 
% initialize RX* 
tmpdev = config.RXinitFunc('GB', config.Dnum); 
iodev.C = tmpdev.C;
iodev.handle = tmpdev.handle;
iodev.status = tmpdev.status;
% initialize attenuators
if strcmpi(config.AttenMode, 'PA5')
	% initialize PA5 attenuators (left = 1 and right = 2)
	PA5L = config.PA5initFunc('GB', 1);
	PA5R = config.PA5initFunc('GB', 2);
end
% load circuit
iodev.rploadstatus = config.RPloadFunc(iodev); 
% start circuit
config.RPrunFunc(iodev);
% check status
iodev.status = config.RPcheckstatusFunc(iodev);
% Query the sample rate from the circuit 
iodev.Fs = config.RPsamplefreqFunc(iodev);
% store in cal struct
cal.Fs = iodev.Fs;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up TDT parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
config.TDTsetFunc(iodev, cal); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up filtering
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-----------------------------------------------------------------------
% update bandpass filter for processing the data
%-----------------------------------------------------------------------
% Nyquist frequency
fnyq = iodev.Fs / 2;
% passband definition
fband = [handles.h2.cal.HPFreq handles.h2.cal.LPFreq] ./ fnyq;
% filter coefficients using a 3rd order Butterworth bandpass filter
[fcoeffb, fcoeffa] = butter(3, fband, 'bandpass');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setup storage variables -- testdata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
testdata.version = '2.2';
testdata.time_str = datestr(now, 31);        % date and time
testdata.timestamp = now;                % timestamp
testdata.adFc = iodev.Fs;                % analog input rate 
testdata.daFc = iodev.Fs;                % analog output rate 
testdata.F = cal.F;                    % freq range (matlab string)
testdata.freq = cal.Freqs;            % frequencies (matlab array)
testdata.Nfreqs = cal.Nfreqs;                % number of freqs to collect
testdata.Reps = cal.Reps;                % reps per frequency
testdata.cal = cal;                   % parameters for calibration session
testdata.frdataL = cal.frL;    % FR data
testdata.frdataR = cal.frR;    % FR data
testdata.frfileL = cal.frfileL;  % FR file name
testdata.frfileR = cal.frfileR;  % FR file name
testdata.DAlevel = cal.DAlevel;        % output peak voltage level
testdata.Side = cal.Side;
testdata.AttenType = cal.AttenType;
switch cal.AttenType
    case 'VARIED'
		 testdata.Atten = cal.AttenStart;        % initial attenuator setting
		 testdata.max_spl = cal.MaxLevel;        % maximum spl (will be determined in program)
		 testdata.min_spl = cal.MinLevel;        % minimum spl (will be determined in program)
    case 'FIXED'
		 testdata.Atten = cal.AttenFixed;        % initial attenuator setting
		 testdata.max_spl = cal.AttenFixed;    % maximum spl (will be determined in program)
		 testdata.min_spl = cal.AttenFixed;    % minimum spl (will be determined in program)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% noise test ranges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
minfreq = 5000;
maxfreq = 90000;
midfreq = floor( 0.5*(maxfreq-minfreq) );
noise_freqs = {	[minfreq maxfreq]; ...
						[minfreq midfreq]; ...
						[midfreq maxfreq] };

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up arrays to hold data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tmpcell = cell(2,1);  % L = 1; R = 2; 
tmpcell{1} = zeros(cal.Nfreqs, cal.Reps);
tmpcell{2} = zeros(cal.Nfreqs, cal.Reps);
tmprawmags = tmpcell;
tmpleakmags = tmpcell;
tmpphis = tmpcell;
tmpleakphis = tmpcell;
tmpdists = tmpcell;
tmpleakdists = tmpcell;
tmpdistphis = tmpcell;
tmpleakdistphis = tmpcell;
tmpmaxmags = tmpcell;
tmpnoisemags = cell(2, 1);
tmpnoisemags{1} = zeros(length(noise_freqs), cal.Reps);
tmpnoisemags{2} = zeros(length(noise_freqs), cal.Reps);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setup cell for raw data 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rawdata.freq = testdata.freq;
rawdata.resp = cell(cal.Nfreqs, cal.Reps);
rawdata.noiseresp = cell(length(noise_freqs), cal.Reps);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set the start and end bins for the calibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_bin = ms2bin(cal.Delay + cal.Ramp, iodev.Fs);
if start_bin < 1
	start_bin = 1;
end
end_bin = start_bin + ms2bin(cal.Duration - 2*cal.Ramp, iodev.Fs);
zerostim = syn_null(cal.Duration, iodev.Fs, 1);  % make zeros for both channels
outpts = length(zerostim);
acqpts = ms2bin(cal.AcqDuration, iodev.Fs);

stim_start_bin = ms2bin(cal.Ramp, iodev.Fs);
if stim_start_bin < 1
	stim_start_bin = 1;
end
stim_end_bin = start_bin + ms2bin(cal.Duration - 2*cal.Ramp, iodev.Fs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up vectors for plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dt = 1/iodev.Fs;
tvec = 1000*dt*(0:(acqpts-1));
stimvec = 0*tvec; 
delay_bin = ms2bin(cal.Delay, iodev.Fs);
duration_bin = ms2bin(cal.Duration, iodev.Fs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setup attenuation (use min value)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Latten = cal.MinLevel;    
Ratten = cal.MinLevel;
switch cal.Side 
	case 'BOTH' 
		% do nothing
	case 'LEFT'
		Ratten = MAX_ATTEN;
	case 'RIGHT'
		Latten = MAX_ATTEN;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now initiate sweeps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% display message
str = 'Now Running Calibration';
set(handles.textMessage, 'String', str);
% pause to let things settle down
pause(1);
% now starting
STOPFLAG = 0; 
rep = 1;
freq_index = 1;
tic % timer start

% ****** main LOOP through the frequencies ******
while ~STOPFLAG && ( freq_index <= cal.Nfreqs )
	% get the current frequency
	freq = cal.Freqs(freq_index); 
	% tell user what frequency is being played
	update_ui_str(handles.editFreqVal, freq);  

	if strcmp(cal.Side, 'BOTH') || strcmp(cal.Side, 'LEFT')  % LEFT    
		% setup played/silent parameters
		PLAYED = L;
		SILENT = R;
		if strcmpi(config.AttenMode, 'PA5')
			PA5P = PA5L;  % played
			PA5S = PA5R;  % silent
		end
		Patten = Latten;
		Satten = MAX_ATTEN;
		atten_val(PLAYED) = Patten; %#ok<*SAGROW>
		atten_val(SILENT) = Satten;
		pmagadjval = cal.frL.magadjval; 
		smagadjval = cal.frR.magadjval; 
		pphiadjval = cal.frL.phiadjval;
		sphiadjval = cal.frR.phiadjval;
		editAttenP = handles.editAttenL;
		editAttenS = handles.editAttenR;
		editValP = handles.editValL;
		editValS = handles.editValR;
		editSPLP = handles.editSPLL;
		editSPLS = handles.editSPLR;
		axesStimP = handles.axesStimL;
		axesStimS = handles.axesStimR;
		axesRespP = handles.axesRespL;
		axesRespS = handles.axesRespR;
		Pcolor = 'g'; 
		Scolor = 'r'; 

		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%% go to main loop for recording responses and storing data %%%
		Calibrate_testloop;
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	end  % LEFT

	if strcmp(cal.Side, 'BOTH') || strcmp(cal.Side, 'RIGHT')  % RIGHT    
		% setup played/silent parameters
		PLAYED = R;
		SILENT = L;
		if strcmpi(config.AttenMode, 'PA5')
			PA5P = PA5R;  % played
			PA5S = PA5L;  % silent
		end
		Patten = Ratten;
		Satten = MAX_ATTEN;
		atten_val(PLAYED) = Patten;
		atten_val(SILENT) = Satten;
		pmagadjval = cal.frR.magadjval;
		smagadjval = cal.frL.magadjval;
		pphiadjval = cal.frR.phiadjval;
		sphiadjval = cal.frL.phiadjval;
		editAttenP = handles.editAttenR;
		editAttenS = handles.editAttenL;
		editValP = handles.editValR;
		editValS = handles.editValL;
		editSPLP = handles.editSPLR;
		editSPLS = handles.editSPLL;
		axesStimP = handles.axesStimR;
		axesStimS = handles.axesStimL;
		axesRespP = handles.axesRespR;
		axesRespS = handles.axesRespL;
		Pcolor = 'r';
		Scolor = 'g';
	
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%% go to main loop for recording responses and storing data %%%
		Calibrate_testloop;
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	end  % RIGHT

%     % do some adjustments and calculations
%     tmpleakmags{L}(freq_index, :) =...
%         tmpleakmags{L}(freq_index, :) - tmprawmags{R}(freq_index, :);
%     tmpleakphis{L}(freq_index, :) =...
%         tmpleakphis{L}(freq_index, :) - tmpphis{R}(freq_index, :);
%     tmpleakmags{R}(freq_index, :) =...
%         tmpleakmags{R}(freq_index, :) - tmprawmags{L}(freq_index, :);
%     tmpleakphis{R}(freq_index, :) =...
%         tmpleakphis{R}(freq_index, :) - tmpphis{L}(freq_index, :);
% 
		% compute the averages for this frequency
	for i=1:2 % L = 1, R = 2
		testdata.mag(i, freq_index) = mean( tmpmaxmags{i}(freq_index, :) );
		testdata.mag_stderr(i, freq_index) = std( tmpmaxmags{i}(freq_index, :) );
		testdata.phase(i, freq_index) = mean( unwrap(tmpphis{i}(freq_index, :)) );
		testdata.phase_stderr(i, freq_index) = std( unwrap(tmpphis{i}(freq_index, :)) );
		testdata.dist(i, freq_index) = mean( tmpdists{i}(freq_index, :) );
		testdata.dist_stderr(i, freq_index) = std( tmpdists{i}(freq_index, :) );

		testdata.leakmag(i, freq_index) = mean( tmpleakmags{i}(freq_index, :) );
		testdata.leakmag_stderr(i, freq_index) = std( tmpleakmags{i}(freq_index, :) );
		testdata.leakphase(i, freq_index) = mean( unwrap(tmpleakphis{i}(freq_index, :)) );
		testdata.leakphase_stderr(i, freq_index) = std( unwrap(tmpleakphis{i}(freq_index, :)) );
		testdata.leakdist(i, freq_index) = mean( tmpleakdists{i}(freq_index, :) );
		testdata.leakdist_stderr(i, freq_index) = std( tmpleakdists{i}(freq_index, :) );
	end

	% increment frequency index counter
	freq_index = freq_index + 1;

	% check if STOP_FLG is set
	if STOPFLAG
		str = 'STOPFLAG detected'; %#ok<UNRCH>
		set(handles.textMessage, 'String', str);
		if STOPFLAG == -1 
			errordlg('Attenuation maxed out!', 'Attenuation error');
		elseif STOPFLAG == -2
			errordlg('Attenuation at minimum level!', 'Attenuation error');
		end
		break;
	end
	% check if user pressed ABORT button 
	if read_ui_val(handles.buttonAbort) == 1
		str = 'ABORTING Calibration';
		set(handles.textMessage, 'String', str);
		handles.h2.ABORT = 1;
		guidata(hObject, handles);    
		break;
	end

end %****** end of cal loop


% ****** main LOOP through the bands ******		
for loop = 1:length(noise_freqs)
	Fmin = noise_freqs{loop}(1);
	Fmax = noise_freqs{loop}(2);
	
	if strcmp(cal.Side, 'BOTH') || strcmp(cal.Side, 'LEFT')  % LEFT    
		% setup played/silent parameters
		PLAYED = L;
		SILENT = R;
		if strcmpi(config.AttenMode, 'PA5')
			PA5P = PA5L;  % played
			PA5S = PA5R;  % silent
		end
		Patten = Latten;
		Satten = MAX_ATTEN;
		atten_val(PLAYED) = Patten; %#ok<*SAGROW>
		atten_val(SILENT) = Satten;
		Pcolor = 'g'; 
		Scolor = 'r';
		
		Calibrate_testloop_noise;
		
	end

	if strcmp(cal.Side, 'BOTH') || strcmp(cal.Side, 'RIGHT')  % RIGHT    
		% setup played/silent parameters
		PLAYED = R;
		SILENT = L;
		if strcmpi(config.AttenMode, 'PA5')
			PA5P = PA5R;  % played
			PA5S = PA5L;  % silent
		end
		Patten = Ratten;
		Satten = MAX_ATTEN;
		atten_val(PLAYED) = Patten;
		atten_val(SILENT) = Satten;
		Pcolor = 'r';
		Scolor = 'g';
		Calibrate_testloop_noise;
	end

	% check if user pressed ABORT button 
	if read_ui_val(handles.buttonAbort) == 1
		str = 'ABORTING Calibration';
		set(handles.textMessage, 'String', str);
		handles.h2.ABORT = 1;
		guidata(hObject, handles);    
		break;
	end

end %****** end of cal loop

cal.timer = toc; % get the time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% exit gracefully 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmpi(config.AttenMode, 'PA5')
	config.PA5closeFunc(PA5L);
	config.PA5closeFunc(PA5R);
end
config.RPcloseFunc(iodev);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if we made it to the end of the frequencies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if freq >= cal.Freqs(end) && ~handles.h2.ABORT % if yes, set the COMPLETE flag
	handles.h2.COMPLETE = 1;
	guidata(hObject, handles);
else % if not, skip the saving and return 
	handles.h2.COMPLETE = 0;
	handles.h2.testdata = testdata;
	handles.h2.rawdata = rawdata;
	guidata(hObject, handles);    
	return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save data to file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% by default, data will be written to temp_cal.mat
% but first, query the user for a non-default file or location
[fname, fpath] = uiputfile('*_testdata.mat', 'Save test Data', ...
																'E:\Data\SJS\Test');
if handles.h2.cal.SaveRawData
	save('temp_testdata.mat', 'testdata', 'rawdata', '-mat');
	if fname
		save(fullfile(fpath, fname), 'testdata', 'rawdata', '-mat');
	end
else 
	save('temp_testdata.mat', 'testdata', '-mat');
	if fname
		save(fullfile(fpath, fname), 'testdata', '-mat');
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save handles and data and temp file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handles.h2.testdata = testdata;
handles.h2.rawdata = rawdata;
guidata(hObject, handles);

