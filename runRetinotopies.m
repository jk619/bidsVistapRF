% To run PRF analysis on sample data

%% 1. open matlab and add paths:
tbUse WinawerLab_SampleData;

%% 2. Convert gifti files to mgz files (here we do it in Matlab)
% Note that we might have already done this for the glmDenoise step.
projectDir = '/Volumes/server/Projects/Retinotopy_141'; % E.g., '/Volumes/server/Projects/SampleData/BIDS';
projectDir = fullfile('/Users/jankurzawski/Dropbox/docker-vista/BIDS'); % E.g., '/Volumes/server/Projects/SampleData/BIDS';

cd (fullfile(projectDir, 'derivatives', 'fmriprep','sub-wlsubj042', 'ses-nyu3t01', 'func'));

% finds the gifti files
d = dir('./*fsnative*.gii');

% convert to mgz using freesurfer
% for ii = 1:2
%     [~, fname] = fileparts(d(ii).name);
%     str = sprintf('mri_convert %s.gii %s.mgz', fname, fname);
%     system(str);
% end

%% 3. Analyze PRF
subject           = 'wlsubj042';
session           = 'nyu3t01';
tasks             = 'prf';
runnums           = 1:2;
dataFolder        = 'fmriprep';
dataStr           = 'fsnative*.mgz';
apertureFolder    = [];
prfOptsPathCoarse = fullfile(projectDir, 'derivatives', 'stim_apertures', sprintf('sub-%s', subject), sprintf('ses-%s', session), 'prfOptsCoarse.json');
prfOptsPathFine   = fullfile(projectDir, 'derivatives', 'stim_apertures', sprintf('sub-%s', subject), sprintf('ses-%s', session), 'prfOptsFine.json');
modelTypeCoarse   = 'coarse';
modelTypeFine     = 'fine';
tr                = [];

cd(projectDir)
% run the coarse PRF analysis (GRID only; should be very fast - minutes)
bidsAnalyzePRF(projectDir, subject, session, tasks, runnums, ...
    dataFolder, dataStr, apertureFolder, modelTypeCoarse, prfOptsPathCoarse, tr)
   
%%
% run the full PRF analysis (optimze each voxel, can be many hours)
bidsAnalyzePRF(projectDir, subject, session, tasks, runnums, ...
       dataFolder, dataStr, apertureFolder, modelTypeFine, prfOptsPathFine, tr)