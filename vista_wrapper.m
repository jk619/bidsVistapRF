% To run PRF analysis on one subject with BIDS formatting with vista solver (docker)
clc
clear
close all
%% 1. open matlab and add paths:
tbUse docker-vista;


addpath(genpath('./package/')) % consider adding this to external of mritools
setenv('PATH', ['/usr/local/bin:' getenv('PATH')]);

session                 = 'nyu3t01';
subject                 = 'wlsubj042';
runnumber               = 99;
task                    = 'prf';


projectDir              = sprintf('./../BIDS/'); % path to folder with derivatives
apertureFolder          = sprintf('%sStimuli',projectDir); % needs to be changed by Gari
% apertureFolder      = sprintf('%sderivatives/stim_apertures',projectDir);
dataFolder              = 'fmriprep';

filesDir                = sprintf('%sderivatives/%s/sub-%s/ses-%s/func',projectDir,dataFolder,subject,session);
filesDir_wrong          = sprintf('%ssub-%s/ses-%s/func/',projectDir,subject,session);
%% path2configs 

cfg.param               = sprintf('%ssub-%s_ses-%s_task-%s_acq-normal_run-%i_cfg.json',filesDir_wrong,subject,session,task,runnumber);
cfg.parambold           = sprintf('%ssub-%s_ses-%s_task-%s_acq-normal_run-%i_bold.json',filesDir_wrong,subject,session,task,runnumber);
cfg.events              = sprintf('%ssub-%s_ses-%s_task-%s_events.json',filesDir_wrong,subject,session,task);
cfg.events_tsv          = sprintf('%ssub-%s_ses-%s_task-%s_events.tsv',filesDir_wrong,subject,session,task);
cfg.average_filename    = sprintf('%ssub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_acq-normal_run-%i',projectDir,subject,session,subject,session,task,runnumber);
cfg.load                = 0; % create default cfg file (NYU color retinotopy settings)
cfg.space               = 'native';

debug                   = 0; % fit only 10 voxels to see if the code runs

%% convert to mgz using freesurfer

d = dir(sprintf('%s/*%s*.gii',filesDir,cfg.space));
for ii = 1:length(d)
    
    [~, fname] = fileparts(d(ii).name);
    str = sprintf('mri_convert %s/%s.gii %s/%s.mgz',filesDir, fname, filesDir,fname);
    
    if ~exist(sprintf('%s/%s.mgz',filesDir, fname'),'file') == 1
        system(str);
    end
    
end

runnums                   =  1:length(d)/2; % / because there are 2 hemi
dataStr                   = sprintf('%s*.mgz',cfg.space);


results = bidsVistaPRF(projectDir,subject,session,task,runnums,dataFolder,dataStr,apertureFolder,filesDir,cfg,debug,runnumber);





