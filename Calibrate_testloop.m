%--------------------------------------------------------------------------
% Calibrate_testloop.m
%--------------------------------------------------------------------------
% Calibration Toolbox:Calibrate
%--------------------------------------------------------------------------
%
% test loop for Calibrate program
%
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Sharad Shanbhag & Go Ashida
% sshanbhag@neomed.edu
% ashida@umd.edu
%--------------------------------------------------------------------------
% Original Version Written (MicrophoneCal_RunCalibration): 2008-2010 by SJS
% Upgraded Version Written (MicrophoneCal2_Run_mainloop): 2011-2012 by GA
% Evolving Version Written (Calibrate): 22 Oct 2017 by SJS
%--------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% synthesize stimulus
stim = synmonosine(	cal.Duration, ...
							iodev.Fs, ...
							freq, ...
							caldata.DAscale, ...
							caldata);
S(PLAYED, :) = stim;
S(SILENT, :) = 0*stim;
S = sin2array(S, cal.Ramp, iodev.Fs);
% plot the stim array
stimvecP = 0 * tvec; % reset to zero
stimvecP(delay_bin+1 : delay_bin+duration_bin) = S(PLAYED, :); % copy stim data
plot(axesStimP, tvec, stimvecP, Pcolor);
% plot the 'silent' array
stimvecS = 0 * tvec; % reset to zero
stimvecS(delay_bin+1 : delay_bin+duration_bin) = S(SILENT, :); % copy stim data
plot(axesStimS, tvec, stimvecS, Scolor);
% figure out attenuation value
atten_val(PLAYED) = figure_mono_atten(Patten, rms(stim), caldata);
atten_val(SILENT) = MAX_ATTEN;
if strcmpi(config.AttenMode, 'PA5')
	% no need to test attenuation but do need to set the attenuators
	config.setattenFunc([PA5P PA5S], atten_val);
elseif strcmpi(config.AttenMode, 'RZ6')
	config.setattenFunc(iodev, atten_val);
elseif strcmpi(config.AttenMode, 'DIGITAL')
	% do something
end
update_ui_str(editAttenP, Patten);
update_ui_str(editAttenS, Satten);


% now, collect the data for frequency FREQ
for rep = 1:cal.Reps
	% show rep number to user
	update_ui_str(handles.editRepVal, [ num2str(rep) ' / ' num2str(cal.Reps) ]);
	% play the sound;
	[resp, rate] = config.ioFunc(iodev, S, acqpts);
	% filter raw data
	resp{PLAYED} = filtfilt(fcoeffb, fcoeffa, sin2array(resp{PLAYED}, 1, iodev.Fs));
	resp{SILENT} = filtfilt(fcoeffb, fcoeffa, sin2array(resp{SILENT}, 1, iodev.Fs));
	% plot the response
	plot(axesRespP, tvec, resp{PLAYED}, Pcolor);
	plot(axesRespS, tvec, resp{SILENT}, Scolor);
	% determine the magnitude and phase of the response/leak
	[pmag, pphi] = fitsinvec(resp{PLAYED}(start_bin:end_bin), 1, iodev.Fs, freq);
	[smag, sphi] = fitsinvec(resp{SILENT}(start_bin:end_bin), 1, iodev.Fs, freq);
	[pdistmag, pdistphi] = fitsinvec(resp{PLAYED}(start_bin:end_bin), 1, iodev.Fs, 2*freq);    
	[sdistmag, sdistphi] = fitsinvec(resp{SILENT}(start_bin:end_bin), 1, iodev.Fs, 2*freq);                
	% compute 2nd harmonic distortion ratio
	tmpdists{PLAYED}(freq_index, rep) = pdistmag / pmag; %#ok<*SAGROW>
	tmpleakdists{SILENT}(freq_index, rep) = sdistmag / smag;
	tmpdistphis{PLAYED}(freq_index, rep) = pdistphi - pphiadjval(freq_index);
	tmpleakdistphis{SILENT}(freq_index, rep) = sdistphi - sphiadjval(freq_index);
	% adjust for the gain of the preamp and convert to RMS
	pmag = cal.RMSsin * pmag / ( pmagadjval(freq_index) * cal.MicGain(PLAYED) );
	smag = cal.RMSsin * smag / ( smagadjval(freq_index) * cal.MicGain(SILENT) );
	% store the data in arrays
	tmprawmags{PLAYED}(freq_index, rep) = dbspl( cal.VtoPa(PLAYED) * pmag );
	tmpleakmags{SILENT}(freq_index, rep) = dbspl( cal.VtoPa(SILENT) * smag );
	tmpphis{PLAYED}(freq_index, rep) = pphi - pphiadjval(freq_index);
	tmpleakphis{SILENT}(freq_index, rep) = sphi - sphiadjval(freq_index);
	% show calculated values
	update_ui_str(editValP, sprintf('%.4f', 1000*pmag));
	update_ui_str(editSPLP, sprintf('%.2f', dbspl(cal.VtoPa(PLAYED)*pmag)));
	update_ui_str(editValS, sprintf('%.4f', 1000*smag));
	update_ui_str(editSPLS, sprintf('%.2f', dbspl(cal.VtoPa(SILENT)*smag)));
	% save mags
	tmpmaxmags{PLAYED}(freq_index, rep) = ...
											tmprawmags{PLAYED}(freq_index, rep) + ...
											caldata.atten(PLAYED, freq_index);
	% store the raw response data
	rawdata.resp{freq_index, rep} = cell2mat(resp');
	% check if user pressed ABORT button 
	if read_ui_val(handles.buttonAbort) == 1
		str = 'ABORT button pressed';
		break;
	end
	% pause
	pause(cal.ISI/1000);
end	