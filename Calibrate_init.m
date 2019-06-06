function out = Calibrate_init(stype)
%------------------------------------------------------------------------
% out = Calibrate_init(stype)
%------------------------------------------------------------------------
% 
% Sets initial values, etc. based on input command stype:
%	'INIT'			loads initial, 'defaults'
%	'INIT_ULTRA'	defaults for ultrasonic stimuli (bats and mice)
% 	'NO_TDT'			default = No_TDT
% 	'RX8_50K'		for RX8, 50 kHz sample rate
% 	'RX6_50K'		for RX6, 50 kHz sample rate
% 	'RZ6_200K'		for RZ6, 200 kHz sample rate
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%  Go Ashida & Sharad Shanbhag
%  ashida@umd.edu
%	sshanbhag@neomed.edu
%------------------------------------------------------------------------
% Original Version Written (HeadphoneCal): 2008-2010 by SJS
% Upgraded Version Written (HeadphoneCal2_init): 2011-2012 by GA
% Evolving Version Written (Calibrate): 2016-? by SJS
%------------------------------------------------------------------------
%
% 26 Apr 2016 (SJS): reworking for optogen project
% 	- INIT: adding UseFR to use or not use FR file
%	- INIT_ULTRA: for use with bats, mice, other high freq critters
%	- added 'RZ6_200K' for RZ6 I/O calibration
%	- INIT: added MicSenseL and MicSenseR
%--------------------------------------------------------------------------

switch upper(stype)
	case 'INIT'
		out.Fmin = 400;
		out.Fmax = 12000;
		out.Fstep = 200;
		out.Reps = 3;
		out.Side = 'BOTH';

		out.AttenType = 'VARIED';
		out.MinLevel = 45;
		out.MaxLevel = 50;
		out.AttenStep = 2;
		out.AttenFixed = 60;
		out.AttenStart = 90; 

		out.MicGainL_dB = 40;
		out.MicGainR_dB = 40;
		out.MicSenseL = 1;
		out.MicSenseR = 1;
		out.frfileL = [];
		out.frfileR = [];
		out.UseFR = 1;

		out.ISI = 100; 
		out.Duration = 150;
		out.Delay = 10;
		out.Ramp = 5;
		out.DAlevel = 5;

		out.AcqDuration = 200;
		out.SweepPeriod = out.AcqDuration + 10;
		out.TTLPulseDur = 1;
		out.HPFreq = 100;
		out.LPFreq = 16000;
		
		out.Fs = 44100;

		out.SaveRawData = 0; 
		return;

		
	case 'INIT_ULTRA'
		out = Calibrate_init('INIT');
		out.Fmin = 4000;
		out.Fmax = 90000;
		out.Fstep = 500;
		out.HPFreq = 3800;
		out.LPFreq = 95000;
		return;		
		
	% default = No_TDT - for testing
	case 'NO_TDT'
		disp('No_TDT selected');
		out.CONFIGNAME = stype;
		out.OutChanL = 0;
		out.OutChanR = 0;
		out.InChanL = 0;
		out.InChanR = 0;

		out.Circuit_Path = [];
		out.Circuit_Name = [];
		out.Dnum = 0; % device number

		out.RXinitFunc = @(varargin) struct('C',0,'handle',0,'status',-1);
		out.PA5initFunc = @(varargin) struct('C',0,'handle',0,'status',-1);
		out.RPloadFunc = @(varargin) -1;
		out.RPrunFunc = @(varargin) -1;
		out.RPcheckstatusFunc = @(varargin) -1;
		out.RPsamplefreqFunc = @(varargin) 50000;
		out.TDTsetFunc = @HeadphoneCal2_NoTDT_settings;
		out.setattenFunc = @(varargin) -1;
		out.ioFunc = @HeadphoneCal2_NoTDT_calibration_io;
		out.PA5closeFunc = @(varargin) -1;
		out.RPcloseFunc = @(varargin) -1;
		return;    

	% for RX8, 50 kHz sample rate
	case 'RX8_50K'
		disp('RX8_50K selected');
		out.CONFIGNAME = stype;
		out.OutChanL = 17;
		out.OutChanR = 18;
		out.InChanL = 1;
		out.InChanR = 2;

		out.Circuit_Path = 'C:\TytoLogy2\toolbox2\TDTcircuits\';
		out.Circuit_Name = 'RX8_2_TwoChannelInOut'; % for Pena Lab
		out.Dnum = 2; % device number % for Pena Lab

		out.RXinitFunc = @RX8init;
		out.PA5initFunc = @PA5init;
		out.RPloadFunc = @RPload2;
		out.RPrunFunc = @RPrun;
		out.RPcheckstatusFunc = @RPcheckstatus;
		out.RPsamplefreqFunc = @RPsamplefreq;
		out.TDTsetFunc = @HeadphoneCal2_TDT_settings;
		out.setattenFunc = @PA5setatten;
		out.ioFunc = @hp2_calibration_io;
		out.PA5closeFunc = @PA5close;
		out.RPcloseFunc = @RPclose;
		return;

	% for RX6, 50 kHz sample rate
	case 'RX6_50K'
		disp('RX6_50K selected');
		out.CONFIGNAME = stype;
		out.OutChanL = 1;
		out.OutChanR = 2;
		out.InChanL = 128;
		out.InChanR = 129;

		out.Circuit_Path = 'C:\TytoLogy2\toolbox2\TDTcircuits\';
		out.Circuit_Name = 'RX6_50k_TwoChannelInOut';
		out.Dnum = 1; % device number

		out.RXinitFunc = @RX6init2;
		out.PA5initFunc = @PA5init;
		out.RPloadFunc = @RPload2;
		out.RPrunFunc = @RPrun;
		out.RPcheckstatusFunc = @RPcheckstatus;
		out.RPsamplefreqFunc = @RPsamplefreq;
		out.TDTsetFunc = @HeadphoneCal2_TDT_settings;
		out.setattenFunc = @PA5setatten;
		out.ioFunc = @hp2_calibration_io;
		out.PA5closeFunc = @PA5close;
		out.RPcloseFunc = @RPclose;
		return;

	% for RZ6, 200 kHz sample rate
	case 'RZ6_200K'
		disp('RZ6_200K selected');
		out.CONFIGNAME = stype;
		out.OutChanL = 1;
		out.OutChanR = 2;
		out.InChanL = 1;
		out.InChanR = 2;

		out.Circuit_Path = 'C:\TytoLogy\Toolboxes\TDTToolbox\Circuits\RZ6';
		out.Circuit_Name = 'RZ6_CalibrateIO_softTrig.rcx';
		out.Dnum = 1; % device number

		% need to rework these functions!
		out.RXinitFunc = @RZ6init;
		% atten mode: 'PA5', 'RZ6', 'DIGITAL'
		out.AttenMode = 'RZ6';
		out.PA5initFunc = [];
		out.RPloadFunc = @RPload;
		out.RPrunFunc = @RPrun;
		out.RPcheckstatusFunc = @RPcheckstatus;
		out.RPsamplefreqFunc = @RPsamplefreq;
		out.TDTsetFunc = @HeadphoneCal2_TDT_settings_RZ6;
		out.setattenFunc = @RZ6setatten;
		out.getattenFunc = @RZ6getatten;
		out.ioFunc = @RZ6calibration_io;
		out.PA5closeFunc = [];
		out.RPcloseFunc = @RPclose;
		return;

	%{
	% for RZ6, 200 kHz sample rate
	case 'RZ6_200K'
		disp('RZ6_200K selected');
		out.CONFIGNAME = stype;
		out.OutChanL = 1;
		out.OutChanR = 2;
		out.InChanL = 1;
		out.InChanR = 2;

		out.Circuit_Path = 'C:\TytoLogy\Toolboxes\TDTToolbox\Circuits\RZ6';
		out.Circuit_Name = 'RZ6_CalibrateIO_softTrig.rcx';
		out.Dnum = 1; % device number

		% need to rework these functions!
		out.RXinitFunc = @RZ6init;
		% atten mode: 'PA5', 'RZ6', 'DIGITAL'
		out.AttenMode = 'RZ6';
		out.PA5initFunc = [];
		out.RPloadFunc = @RPload;
		out.RPrunFunc = @RPrun;
		out.RPcheckstatusFunc = @RPcheckstatus;
		out.RPsamplefreqFunc = @RPsamplefreq;
		out.TDTsetFunc = @HeadphoneCal2_TDT_settings_RZ6;
		out.setattenFunc = @RZ6setatten;
		out.getattenFunc = @RZ6getatten;
		out.ioFunc = @RZ6calibration_io;
		out.PA5closeFunc = [];
		out.RPcloseFunc = @RPclose;
		return;
	%}
		
	% trap unknown type
	otherwise
		disp([mfilename ': unknown parameter ' stype '...']);
		out = [];
		return;

end    

