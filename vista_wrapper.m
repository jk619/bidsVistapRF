% To run PRF analysis on sample data with vista solver
clc
clear
close all
%% 1. open matlab and add paths:
tbUse docker-vista;


addpath(genpath('./package/')) % consider adding this to external of mritools

session             = 'nyu3t01';
subject             = 'wlsubj042';
runnum              = 99;
task                = 'prf';


projectDir          = sprintf('./../BIDS/'); % path to folder with derivatives
apertureFolder      = sprintf('%sStimuli',projectDir);
filesDir            = sprintf('%sderivatives/fmriprep/sub-%s/ses-%s/func',projectDir,subject,session);

%% path2configs

cfg.param               = sprintf('sub-%s_ses-%s_task-%s_acq-normal_run-%i_cfg.json',subject,session,task,runnum);
cfg.parambold           = sprintf('sub-%s_ses-%s_task-%s_acq-normal_run-%i_bold.json',subject,session,task,runnum);
cfg.events              = sprintf('sub-%s_ses-%s_task-%s_events.json',subject,session,task);
cfg.events_tsv          = sprintf('sub-%s_ses-%s_task-%s_events.tsv',subject,session,task);

%% add an aperture file
% copyfile([apertureFolder filesep 'apertures.nii.gz'],...
%     [apertureFolder filesep sprintf('sub-%s_ses-%s_task-%s_apertures.nii.gz',...
%     param.subjectName,param.sessionName,parambold.TaskName)])

%% convert to mgz using freesurfer

d = dir(sprintf('%s/*fsnative*.gii',filesDir));
for ii = 1:length(d)
    
    [~, fname] = fileparts(d(ii).name);
    str = sprintf('mri_convert %s/%s.gii %s/%s.mgz',filesDir, fname, filesDir,fname);
    
    if ~exist(sprintf('%s/%s.mgz',filesDir, fname'),'file') == 1
        system(str);
    end
    
end

runnums           =  ones(1,length(d)/2);
dataFolder        = 'fmriprep';
dataStr           = 'fsnative*.mgz';


% results = bidsVistaPRF(projectDir,subject,session,task,runnums,dataFolder,dataStr,apertureFolder,filesDir,cfg);
results = bidsVistaPRF(projectDir,subject,session,task,runnums,dataFolder,dataStr,apertureFolder,filesDir);





