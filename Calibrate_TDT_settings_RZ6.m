function Calibrate_TDT_settings_RZ6(iodev, cal)
%------------------------------------------------------------------------
% Calibrate_TDT_settings_RZ6(iodev, cal)
%------------------------------------------------------------------------
% sets up TDT tag settings for Calibrate program using RZ6
% 
%------------------------------------------------------------------------
% Input Arguments:
% 	iodev			TDT device interface structure
% 	cal             calibration data structure
% 
% Output Arguments:
%	none
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%  Sharad Shanbhag & Go Ashida
%	sshanbhag@neomed.edu
%  ashida@umd.edu
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% Originally Written (HeadphoneCal_tdtinit): 2009-2011 by SJS
% Upgraded Version Written (HeadphoneCal2_TDTsettings): 2011-2012 by GA
% Evolving Version Written (Calibrate): 2016-? by SJS
% 
% Revisions:
% 29 Apr 2016 (SJS): HeadphoneCal2_TDT_settings_RZ6 created for use with
%							RZ6
% 	- removed calls to set filter tags (removed filtering from the 
% 	  circuit to save processing power on single-processor RZ6)
% 	- removed set channels tags - only 2 outputs, inputs for RZ6
%------------------------------------------------------------------------

% set the total sweep period time
RPsettag(iodev, 'SwPeriod', ms2samples(cal.SweepPeriod, iodev.Fs));
% set the sweep count (may not be necessary)
RPsettag(iodev, 'SwCount', 1);
% Set the length of time to acquire data
RPsettag(iodev, 'AcqDur', ms2samples(cal.AcqDuration, iodev.Fs));
% set the stimulus delay
RPsettag(iodev, 'StimDelay', ms2samples(cal.Delay, iodev.Fs));
% set the stimulus Duration
RPsettag(iodev, 'StimDur', ms2samples(cal.Duration, iodev.Fs));

