function results =  bidsVistaPRF(projectDir,subject,session,task,runnums,dataFolder,dataStr,apertureFolder,filesDir,cfg)


%
% results = bidsAnalyzePRF(projectDir, subject, [session], [tasks], [runnums], ...
%        [dataFolder], [apertureFolder], [modelType], [stimwidthdeg], [name4averagefile],[tr]);
%
% Input
%
%   Required
%
%
%
% Dependencies
%     vistasoft repository (https://github.com/vistalab/vistasoft)
%     docker               (https://www.docker.com)
%
%
% Example 1
%     projectDir        = '/Volumes/server/Projects/SampleData/BIDS';
%     subject           = 'wlsubj042';
%     session           = '01';
%     tasks             = 'prf';
%     runnums           = 1:2;
%     dataFolder        = 'fmriprep';
%     dataStr           = 'fsnative*.mgz';
%     apertureFolder    = [];
%     prfOptsPath       = [];
%     tr                = [];
%     modelType         = [];
%
%     % make the stimulus apertures
%     bidsStimulustoApertures(projectDir, subject, session, tasks, runnums, apertureFolder);
%
%     % run the prf analysis
%     bidsAnalyzePRF(projectDir, subject, session, tasks, runnums, ...
%        dataFolder, dataStr, apertureFolder, modelType, prfOptsPath, tr)
%

%% Check inputs





% <dataFolder>
if ~exist('dataFolder', 'var') || isempty(dataFolder)
    dataFolder = 'fmriprep';
end

if ~exist('cfg', 'var') || isempty(dataFolder) || cfg.load == 0
    %% prepare configuration files.
    
    %  Function prepare_configs_vista will create 4 default config files that are necessary
    %  to run pRF vista solver in the docker. First two are configuration files
    %  of the docker "*cfg.json", and fMRI "*bold.json". The
    %  remaining two files are event file with stimulus details and a
    %  coresponding json file. The output is the averge
    
    cfg = preapre_configs_vista(projectDir,subject,session,task,apertureFolder);
    
    
else
    
    cfg.param = loadjson(cfg.param);
    cfg.parambold = loadjson(cfg.parambold);
    
    
end


% <apertureFolder>
if ~exist('apertureFolder', 'var'), apertureFolder = []; end
aperturePath = fullfile(apertureFolder, sprintf('sub-%s',subject), sprintf('ses-%s',session));
if ~exist(aperturePath, 'dir')
    error('Aperture path not found: %s', aperturePath);
end


%% Create vistasoft inputs

%****** Required inputs to vistsasoft *******************

[stimulus, stimwidthpix] = getStimulus(aperturePath, {task}, {runnums});
save_stimulus_aperture_as_nii(stimulus,apertureFolder,subject,session,task)


data = bidsGetPreprocData(filesDir, dataStr, {task}, {runnums});
tr   = cfg.parambold.RepetitionTime;

%% Optional inputs to analyzePRF
%
% [averageScans,stimwidthdeg,opt] = getPRFOpts_vista(prfOptsPath);

averageScans = runnums>0;

if ~isempty(averageScans)
    
    
    dims = ndims(data{1});
    datatmp = mean(cat(dims+1,data{:}),dims+1);
    data = datatmp;
    
end


%     convert to nifti-2
data_tmp = permute(data,[2 1 3 4]);
niftiwrite(data_tmp,[average_name '_bold'],'Version','NIfTI2');
hdr = niftiinfo([average_name '_bold']);
hdr.SpaceUnits = 'Millimeter';
hdr.TimeUnits  = 'Second';

%% debug
hdr.ImageSize(1) = 100;
data_tmp = data_tmp(1:100,:,:,:);
niftiwrite(data_tmp,[average_name '_bold'],hdr,'Compressed',true);



%% Save input arguments

inputVar = struct('projectDir', projectDir, 'subject', param.subjectName, ...
    'session', param.subjectName, 'tasks', parambold.TaskName, 'runnums', runnums, ...
    'dataFolder', dataFolder, 'dataStr', dataStr, 'apertureFolder', apertureFolder, ...
    'modelType', param.options.wsearch(~isspace(param.options.wsearch)), 'tr', tr, 'stimwidthdeg', param.stimulus.stimulus_diameter/2,'stimwidthpix',stimwidthpix)

fname = sprintf('sub-%s_ses-%s_%s_inputVar.json', param.subjectName, param.subjectName, param.options.wsearch(~isspace(param.options.wsearch)));

%   <resultsdir>
resultsdir   = fullfile (projectDir,'derivatives','vistasoft', param.options.wsearch(~isspace(param.options.wsearch)), ...
    sprintf('sub-%s',param.subjectName), sprintf('ses-%s',param.sessionName));

if ~exist(resultsdir, 'dir'); mkdir(resultsdir); end

savejson('',inputVar,fullfile(resultsdir,fname));


%% Run the analyzePRF alogithm
analyzeVISTA(average_name);


% save the results as mgz files
aPRF2Maps_vista(projectDir, subject, session, modelType);

% save out .png files of angle, ecc, sigma, R2 for lh and rh
Maps2PNG(projectDir, subject, session, modelType);

end
%% ******************************
% ******** SUBROUTINES **********
% *******************************

function cfg = preapre_configs_vista(projectDir,subject,session,task,apertureFolder);


param.solver                            = 'vista';
param.isPRFSynthData                    =  false;
param.options.model                     = 'one gaussian';
param.options.grid                      =  false
param.options.wsearch                   = 'coarse to fine';
param.options.detrend                   = 1;
param.options.keepAllPoints             = false;
param.options.numberStimulusGridPoints  = 50;
param.stimulus.stimulus_diameter        = 24;

parambold.RepetitionTime                = 1;
parambold.SliceTiming                   = 0;
parambold.TaskName                      = 'prf';


file99name = sprintf('%ssub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_acq-normal_run-99', ...
    projectDir,subject,session,subject,session,task);

opt.ParseLogical = 1;
opt.FileName = [file99name '_cfg.json'];
savejson('',param,opt);

opt.FileName = [file99name '_bold.json'];
savejson('',parambold,opt);


fid.onset = zeros([aperture_size(3) 1]);
fid.duration = zeros([aperture_size(3) 1]);
fid.stim_file_index = zeros([aperture_size(3) 1]);

for f = 1 : aperture_size(3)
    
    fid.onset(f) = f - 1;
    fid.duration(f) = 1;
    fid.stim_file(f,:) = sprintf('sub-%s_ses-%s_task-%s_apertures.nii.gz',...
        subject,session,task);
    fid.stim_file_index(f) = f;
    
end

tdfwrite([projectDir filesep sprintf('sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.tsv',...
    subject,session,subject,session,task)],fid);

stim_file_index.Description = '1-based index into the stimulus file of the relevant stimulus';
savejson('stim_file_index',stim_file_index,[projectDir filesep sprintf('sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.json',...
    subject,session,subject,session,task)]);

cfg.param = param;
cfg.parambold = parambold;
end


function save_stimulus_aperture_as_nii(stimulus,apertureFolder,subject,session,task)


stim = double(stimulus{1});
niftiwrite(stim,[apertureFolder filesep sprintf('sub-%s/ses-%s/sub-%s_ses-%s_task-%s_apertures',...
    subject,session,subject,session,task)],'Compressed',true)



end


