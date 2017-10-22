function Calibrate_testplot(testdata, figtitle)
%------------------------------------------------------------------------
% out = Calibrate_testplot(testdata, figtitle)
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
% Evolving Version Written (Calibrate): 22Oct2017 by SJS
%------------------------------------------------------------------------

if ~isstruct(testdata)
	disp([mfilename ': invalid TEST data']);
	return;
end
if ~isfield(testdata, 'freq')
	disp([mfilename ': invalid TEST frequency data: freq not found']);
	return;
end
if isempty(testdata.freq)
	disp([mfilename ': invalid TEST frequency data: freq is empty']);
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
errorbar(testdata.freq, testdata.mag(L, :), testdata.mag_stderr(L, :), '.-g');
hold on;
errorbar(testdata.freq, testdata.mag(R, :), testdata.mag_stderr(R, :), '.-r');
hold off;
title('Calibration Test Results');
ylabel('Max Intensity (db SPL)');
legend('L', 'R', 'Location', 'Best');
xlim([testdata.F(1) testdata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

subplot(3,2,3);
errorbar(testdata.freq, unwrap(testdata.phase(L, :)), testdata.phase_stderr(L, :), '.-g');
hold on;
errorbar(testdata.freq, unwrap(testdata.phase(R, :)), testdata.phase_stderr(R, :), '.-r');
hold off;
ylabel('Phase');
% legend('L','R');
xlim([testdata.F(1) testdata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

subplot(3,2,5);
errorbar(testdata.freq, testdata.dist(L, :)*100, testdata.dist_stderr(L, :)*100, '.-g');
hold on;
errorbar(testdata.freq, testdata.dist(R, :)*100, testdata.dist_stderr(R, :)*100, '.-r');
hold off;
ylabel('Distortion (%)');
% legend('L', 'R');
xlim([testdata.F(1) testdata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

subplot(3,2,2);
errorbar(testdata.freq, testdata.leakmag(L, :), testdata.leakmag_stderr(L, :), '.-g');
hold on;
errorbar(testdata.freq, testdata.leakmag(R, :), testdata.leakmag_stderr(R, :), '.-r');
hold off;
ylabel('Leak magnitude (dB)');
% legend('L','R');
xlim([testdata.F(1) testdata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

subplot(3,2,4);
errorbar(testdata.freq, unwrap(testdata.leakphase(L, :)), testdata.leakphase_stderr(L, :), '.-g');
hold on;
errorbar(testdata.freq, unwrap(testdata.leakphase(R, :)), testdata.leakphase_stderr(R, :), '.-r');
hold off;
ylabel('Leak phase');
% legend('L','R');
xlim([testdata.F(1) testdata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

subplot(3,2,6);
errorbar(testdata.freq, testdata.leakdist(L, :)*100, testdata.leakdist_stderr(L, :)*100, '.-g');
hold on;
errorbar(testdata.freq, testdata.leakdist(R, :)*100, testdata.leakdist_stderr(R, :)*100, '.-r');
hold off;
ylabel('Leak distortion (%)');
% legend('L','R');
xlim([testdata.F(1) testdata.F(3)]);
set(gca, 'XGrid', 'on');
set(gca, 'YGrid', 'on');

