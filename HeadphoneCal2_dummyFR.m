function out = HeadphoneCal2_dummyFR(varargin)
%------------------------------------------------------------------------
% out = MicrophonCal2_dummyFR(varargin)
%------------------------------------------------------------------------
% 
% Sets FR data for unused side
% 				- OR -
% for use when calibration mic is used directly
%------------------------------------------------------------------------

%------------------------------------------------------------------------
% Go Ashida
% ashida@umd.edu
% Sharad Shanbhag
% sshanbhag@neomed.edu
%------------------------------------------------------------------------
% Created: November, 2011 by GA
%
% Revisions: 
%	29 Apr 2016 (SJS): updated email addresses
%------------------------------------------------------------------------

out.version = '2.0';
out.F = [0,100000,200000];  % Fmin=0, Fstep=100000, Fmax=200000;
out.Freqs = out.F(1):out.F(2):out.F(3);
out.Nfreqs = length(out.Freqs);
out.DAlevel = 0; 
out.adjmag = ones(1, out.Nfreqs);
out.adjphi = zeros(1, out.Nfreqs); 
out.cal = struct();
out.cal.RefMicSens = 1;
out.cal.MicGain_dB = 0;
