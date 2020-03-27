function results = bidsVistaPRF(projectDir,param,parambold,runnums,dataFolder,dataStr,average_name,apertureFolder);


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

dataPath = fullfile(projectDir,'derivatives', dataFolder,...
    sprintf('sub-%s',param.subjectName),filesep,sprintf('ses-%s',param.sessionName),'func');


% <apertureFolder>
% if ~exist('apertureFolder', 'var'), apertureFolder = []; end
% aperturePath = fullfile(projectDir, 'derivatives', 'stim_apertures', ...
%     apertureFolder, sprintf('sub-%s',subject), sprintf('ses-%s',session));
% if ~exist(aperturePath, 'dir')
%     error('Aperture path not found: %s', aperturePath); 
% end


%% Create vistasoft inputs

%****** Required inputs to vistsasoft *******************

data = bidsGetPreprocData(dataPath, dataStr, {parambold.TaskName}, {runnums});
tr   = parambold.RepetitionTime;

%% Optional inputs to analyzePRF 
%
% [averageScans,stimwidthdeg,opt] = getPRFOpts_vista(prfOptsPath);

averageScans = runnums>0;

if ~isempty(averageScans)
   
    % average the requested scans

    [~, ia] = unique(averageScans);
    dims = ndims(data{1});
    
    mn = cell(1,length(ia));
    datatmp = mean(cat(dims+1,data{:}),dims+1);
      
    data = datatmp;
    
    % stimulus = stimulus(ia);
end


%     convert to nifti-2
data_tmp = permute(data,[2 1 3 4]);
niftiwrite(data_tmp,[average_name '_bold'],'Version','NIfTI2');
hdr = niftiinfo([average_name '_bold']);
hdr.SpaceUnits = 'Millimeter';
hdr.TimeUnits  = 'Second';

% nii_tmp = niftiRead([average_name '_bold.nii']);
% nii_tmp.dim = nii_tmp.dim([2 1 3 4]);
% nii_tmp.data =  permute(nii_tmp.data,[2 1 3 4]);
% nii_tmp.pixdim = ones(1,4);
% nii_tmp.xyz_units = 'mm';
% nii_tmp.time_units = 'sec';


%% debug
hdr.ImageSize(1) = 100;
data_tmp = data_tmp(1:100,:,:,:);
niftiwrite(data_tmp,[average_name '_bold'],hdr,'Compressed',true);



%% Save input arguments

inputVar = struct('projectDir', projectDir, 'subject', param.subjectName, ...
    'session', param.subjectName, 'tasks', parambold.TaskName, 'runnums', runnums, ...
    'dataFolder', dataFolder, 'dataStr', dataStr, 'apertureFolder', apertureFolder, ...
    'modelType', param.options.wsearch(~isspace(param.options.wsearch)), 'tr', tr, 'stimwidthdeg', param.stimulus.stimulus_diameter/2)
    
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

function pth = prfOptsMakeDefaultFile()
    % see analyzePRF for descriptions of optional input 
    
    % average scans with identical stimuli
    json.averageScans = [];  % 
    json.stimwidth    = 24.2;  % degrees
    
    % other opts
    json.opt.vxs            = []; 
    json.opt.wantglmdenoise = []; 
    json.opt.hrf            = [];
    json.opt.maxpolydeg     = [];
    json.opt.numperjob      = [];
    json.opt.xvalmode       = [];
    json.opt.seedmode       = [];
    json.opt.maxiter        = [];
    json.opt.display        = 'off';
    json.opt.typicalgain    = [];

                  
    pth = fullfile(tempdir, 'prfOpts.json');
    savejson('', json, 'FileName', pth);
end      
  
           