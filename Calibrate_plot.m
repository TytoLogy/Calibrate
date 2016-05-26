function Calibrate_plot(caldata, figtitle)
%------------------------------------------------------------------------
% out = Calibrate_plot(caldata, figtitle)
%------------------------------------------------------------------------
% 
% Plots CAL data.
%
%------------------------------------------------------------------------

%------------------------------------------------------------------------
%  Go Ashida & Sharad Shanbhag
%  ashida@umd.edu
%	sshanbhag@neomed.edu
%------------------------------------------------------------------------
% Original Version Written (PlotCal): 2008-2010 by SJS
% Upgraded Version Written (HeadphoneCal2_plot): 2011-2012 by GA
% Evolving Version Written (Calibrate): 2016-? by SJS
%------------------------------------------------------------------------

if ~isstruct(caldata)
	disp([mfilename ': invalid CAL data']);
	return;
end
if ~isfield(caldata, 'freq')
	disp([mfilename ': invalid CAL frequency data: freq not found']);
	return;
end
if isempty(caldata.freq)
	disp([mfilename ': invalid CAL frequency data: freq is empty']);
	return; 
end

L = 1; 
R = 2;

% open figure window and set figure title 
figure;
if nargin > 1  % if figure title is provided, then set it
	set(gcf, 'name', figtitle);
end

subplot(3,2,1);
errorbar(caldata.freq, caldata.mag(L, :), caldata.mag_stderr(L, :), '.-g');
hold on;
errorbar(caldata.freq, caldata.mag(R, :), caldata.mag_stderr(R, :), '.-r');
hold off;
title('Calibration Results');
ylabel('Max Intensity (db SPL)');
legend('L', 'R', 'Location', 'Best');
xlim([caldata.F(1) caldata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

subplot(3,2,3);
errorbar(caldata.freq, unwrap(caldata.phase(L, :)), caldata.phase_stderr(L, :), '.-g');
hold on;
errorbar(caldata.freq, unwrap(caldata.phase(R, :)), caldata.phase_stderr(R, :), '.-r');
hold off;
ylabel('Phase');
% legend('L','R');
xlim([caldata.F(1) caldata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

subplot(3,2,5);
errorbar(caldata.freq, caldata.dist(L, :)*100, caldata.dist_stderr(L, :)*100, '.-g');
hold on;
errorbar(caldata.freq, caldata.dist(R, :)*100, caldata.dist_stderr(R, :)*100, '.-r');
hold off;
ylabel('Distortion (%)');
% legend('L', 'R');
xlim([caldata.F(1) caldata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

subplot(3,2,2);
errorbar(caldata.freq, caldata.leakmag(L, :), caldata.leakmag_stderr(L, :), '.-g');
hold on;
errorbar(caldata.freq, caldata.leakmag(R, :), caldata.leakmag_stderr(R, :), '.-r');
hold off;
ylabel('Leak magnitude (dB)');
% legend('L','R');
xlim([caldata.F(1) caldata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

subplot(3,2,4);
errorbar(caldata.freq, unwrap(caldata.leakphase(L, :)), caldata.leakphase_stderr(L, :), '.-g');
hold on;
errorbar(caldata.freq, unwrap(caldata.leakphase(R, :)), caldata.leakphase_stderr(R, :), '.-r');
hold off;
ylabel('Leak phase');
% legend('L','R');
xlim([caldata.F(1) caldata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

subplot(3,2,6);
errorbar(caldata.freq, caldata.leakdist(L, :)*100, caldata.leakdist_stderr(L, :)*100, '.-g');
hold on;
errorbar(caldata.freq, caldata.leakdist(R, :)*100, caldata.leakdist_stderr(R, :)*100, '.-r');
hold off;
ylabel('Leak distortion (%)');
% legend('L','R');
xlim([caldata.F(1) caldata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

