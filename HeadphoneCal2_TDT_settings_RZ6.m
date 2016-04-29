function HeadphoneCal2_TDT_settings_RZ6(iodev, cal)
%------------------------------------------------------------------------
% HeadphoneCal2_TDT_settings_RZ6(iodev, cal)
%------------------------------------------------------------------------
% sets up TDT tag settings for MicrophoneCal2 using RZ6
% 
%------------------------------------------------------------------------
% Input Arguments:
% 	iodev			TDT device interface structure
% 	cal             calibration data structure
% 
% Output Arguments:
%
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%  Sharad Shanbhag & Go Ashida
%	sshanbhag@neomed.edu
%   ashida@umd.edu
%------------------------------------------------------------------------
%------------------------------------------------------------------------
% Originally Written (HeadphoneCal_tdtinit): 2009-2011 by SJS
% Upgraded Version Written (HeadphoneCal2_TDTsettings): 2011-2012 by GA
% 
% Revisions:
% 29 Apr 2016 (SJS): HeadphoneCal2_TDT_settings_RZ6 created for use with
%							RZ6
% 	- removed calls to set filter tags (removed filtering from the 
% 	  circuit to save processing power on single-processor RZ6)
% 	- removed set channels tags - only 2 outputs, inputs for RZ6
%------------------------------------------------------------------------

%npts = 150000;  % size of the serial buffer -- fixed
%mclock = config.RPgettagFunc(iodev, 'mClock');

% set the TTL pulse duration
% RPsettag(iodev, 'TTLPulseDur', ms2samples(cal.TTLPulseDur, iodev.Fs));
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

