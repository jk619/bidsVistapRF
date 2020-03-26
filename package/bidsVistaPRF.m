function bidsVistaPRF(projectDir, subject, session, tasks, runnums, ...
        dataFolder, dataStr,apertureFolder,modelType,stimwidthdeg,file99name,tr)
%
% results = bidsAnalyzePRF(projectDir, subject, [session], [tasks], [runnums], ...
%        [dataFolder], [apertureFolder], [modelType], [stimwidthdeg], [name4averagefile],[tr]);
%
% Input
%
%   Required
%
%     subject           name of the subject
%     session           name of the session
%     task              name of the experiment task
%     runnum            number of runs to be averaged
%     dataFolder        folder containing fmriPrep data
%     dataStr           string specyfinig analysis space fsnative, fsaveraged 
%     apertureFolder    folder with nifti aperture
%     modelType         type of fit from vistasoft  
%     stimwidthdeg      stimuluswidth (mostly for reporting purposes)
%     name4averagefile  string containing the path to the average data (BIDS style)
%     tr                Repetition time (TR) for reporting purposes
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

if ~exist('session', 'var'),     session = [];      end
if ~exist('tasks', 'var'),       tasks   = [];      end
if ~exist('runnums', 'var'),     runnums  = [];     end
if ~exist('dataStr', 'var'),     dataStr = 'bold';  end

[session, tasks, runnums] = bidsSpecifyEPIs(projectDir, subject,...
    session, tasks, runnums);


% <dataFolder>
if ~exist('dataFolder', 'var') || isempty(dataFolder)
    dataFolder = 'fmriprep';
end
dataPath = fullfile (projectDir,'derivatives', dataFolder,...
    sprintf('sub-%s',subject), sprintf('ses-%s',session));
if exist(fullfile(dataPath, 'func'), 'dir')
    dataPath = fullfile (dataPath, 'func');
end
rawDataPath = fullfile(projectDir, sprintf('sub-%s', subject), ...
    sprintf('ses-%s', session), 'func');

% <apertureFolder>
% if ~exist('apertureFolder', 'var'), apertureFolder = []; end
% aperturePath = fullfile(projectDir, 'derivatives', 'stim_apertures', ...
%     apertureFolder, sprintf('sub-%s',subject), sprintf('ses-%s',session));
% if ~exist(aperturePath, 'dir')
%     error('Aperture path not found: %s', aperturePath); 
% end
 
% <modelType>
if ~exist('modelType', 'var') || isempty(modelType)
    modelType = apertureFolder;
end

%% Create vistasoft inputs

%****** Required inputs to vistsasoft *******************

data = bidsGetPreprocData(dataPath, dataStr, tasks, runnums);

% <tr>
if ~exist('tr', 'var') || isempty(tr)
    tr = bidsGetJSONval(rawDataPath,tasks, runnums, 'RepetitionTime');
    tr = cell2mat(tr);
    if length(unique(tr)) > 1
        disp(unique(tr))
        error(['More than one TR found:' ...
            'GLMdenoise expects all scans to have the same TR.'])
    else
        tr = unique(tr);
    end
end

%% Optional inputs to analyzePRF 
%
% [averageScans,stimwidthdeg,opt] = getPRFOpts_vista(prfOptsPath);

averageScans = cell2mat(runnums)>0;

if ~isempty(averageScans)
   
    % average the requested scans

    [~, ia] = unique(averageScans);
    dims = ndims(data{1});
    
    mn = cell(1,length(ia));
    
    for ii = 1:length(ia)
        whichscans = averageScans==ia(ii);
        datatmp = catcell(dims+1, data(whichscans));
        mn{ii} =  mean(datatmp, dims+1);
    end
    data = mn;
    
    % stimulus = stimulus(ia);
end


%     convert to nifti-2
niftiwrite(data{1},[file99name '_bold'],'Version','NIfTI2');
nii_tmp = niftiRead([file99name '_bold.nii']);
nii_tmp.dim = nii_tmp.dim([2 1 3 4]);
nii_tmp.data =  permute(nii_tmp.data,[2 1 3 4]);
nii_tmp.pixdim = ones(1,4);
nii_tmp.xyz_units = 'mm';
nii_tmp.time_units = 'sec';


%% debug
nii_tmp.dim(1) = 100;
nii_tmp.data = nii_tmp.data(1:100,:,:,:);
niftiWrite(nii_tmp,[file99name '_bold.nii.gz']);



%% Save input arguments

inputVar = struct('projectDir', projectDir, 'subject', subject, ...
    'session', session, 'tasks', tasks, 'runnums', runnums, ...
    'dataFolder', dataFolder, 'dataStr', dataStr, 'apertureFolder', apertureFolder, ...
    'modelType', modelType, 'tr', tr, 'stimwidthdeg', stimwidthdeg)
    
fname = sprintf('sub-%s_ses-%s_%s_inputVar.json', subject, session, modelType);

%   <resultsdir>
resultsdir   = fullfile (projectDir,'derivatives','vistasoft', modelType, ...
                 sprintf('sub-%s',subject), sprintf('ses-%s',session));

if ~exist(resultsdir, 'dir'); mkdir(resultsdir); end

savejson('',inputVar,fullfile(resultsdir,fname));


%% Run the analyzePRF alogithm
analyzeVISTA(file99name);


% save the results as mgz files
aPRF2Maps_vista(projectDir, subject, session, modelType);

% save out .png files of angle, ecc, sigma, R2 for lh and rh
Maps2PNG(projectDir, subject, session, modelType);

end


%% ******************************
% ******** SUBROUTINES **********
% *******************************

function [averageScans, stimwidth, opt] = getPRFOpts_vista(prfOptsPath)

if ~exist('prfOptsPath', 'var') || isempty(prfOptsPath)
    prfOptsPath = prfOptsMakeDefaultFile; 
end

json = jsondecode(fileread(prfOptsPath));


if isfield(json, 'averageScans'), averageScans = json.averageScans;
else, averageScans = []; end

if isfield(json, 'stimwidth'), stimwidth = json.stimwidth;
else, error('Stim width not specified in options file'); end

if isfield(json, 'opt'), opt = json.opt; else, opt = []; end

end


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
  
           