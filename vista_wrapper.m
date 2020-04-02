% To run PRF analysis on one subject with BIDS formatting with vista solver (docker)
clc
clear
close all
%% 1. open matlab and add paths:
tbUse docker-vista;


addpath(genpath('./package/')) % consider adding this to external of mritools

session                 = 'nyu3t01';
subject                 = 'wlsubj042';
runnumber               = 99;
task                    = 'prf';



mainDir                 = sprintf('./../'); % points to a folder were your 
                                            % BIDS formated folder is sitting 
                                            % this is needed only for the
                                            % docker so it knows where to
                                            % output the prf fitting
                                            % results
                                            
BidsDir                 = 'BIDS'; % name of the folder with derivatives
projectDir              = sprintf('./../%s/',BidsDir); 
apertureFolder          = sprintf('%sderivatives/stim_apertures',projectDir);
dataFolder              = 'fmriprep';

filesDir                = sprintf('%sderivatives/%s/sub-%s/ses-%s/func',projectDir,dataFolder,subject,session);
averageFolName          = sprintf('%sderivatives/averageTCs',projectDir);

%% path2configs 

cfg.param               = sprintf('%s/sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_acq-normal_run-%i_cfg.json',averageFolName,subject,session,subject,session,task,runnumber);
cfg.parambold           = sprintf('%s/sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_acq-normal_run-%i_bold.json',averageFolName,subject,session,subject,session,task,runnumber);
cfg.events              = sprintf('%s/sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.json',averageFolName,subject,session,subject,session,task);
cfg.events_tsv          = sprintf('%s/sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.tsv',averageFolName,subject,session,subject,session,task);
cfg.average_filename    = sprintf('%s/sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_acq-normal_run-%i',averageFolName,subject,session,subject,session,task,runnumber);
cfg.load                = 0; % create default cfg file (NYU color retinotopy settings)
cfg.space               = 'native';


dockerscript            = 'prfanalyze_Jan_in_out.sh';


debug.ifdebug           = 1; % fit pRFs only in rois specifed below
debug.roiname           = {'V1_exvivo';'V2_exvivo'}; % Roi or Rois from freesurfer label directory for the debug mode
debug.ifdebug           = 2; % fit pRFs only in 10 voxels
%% convert to mgz using freescdurfer

d = dir(sprintf('%s/*%s*.gii',filesDir,cfg.space));
% d = dir(sprintf('%s/*%s*.mgz',filesDir,cfg.space));

for ii = 1:length(d)
    
    [~, fname] = fileparts(d(ii).name);
    str = sprintf('mri_convert %s/%s.gii %s/%s.mgz',filesDir, fname, filesDir,fname);
    
    if ~exist(sprintf('%s/%s.mgz',filesDir, fname'),'file') == 1
        system(str);
    end
    
end

runnums                   =  1:length(d)/2; % / because there are 2 hemi
dataStr                   =  sprintf('%s*.mgz',cfg.space);


bidsVistaPRF(mainDir,projectDir,subject,session,task,runnums,dataFolder,dataStr,apertureFolder,filesDir,debug,averageFolName,cfg,dockerscript);





