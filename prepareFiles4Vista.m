% To run PRF analysis on sample data with vista solver
clc
clear
close all
%% 1. open matlab and add paths:
tbUse docker-vista;


addpath(genpath('./package/')) % consider adding this to external of mritools


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


projectDir                              = sprintf('./../BIDS/'); % path to folder with derivatives
fmriprepDir                             = sprintf('%sderivatives/fmriprep',projectDir);
subjects                                = dir(sprintf('%s/*sub*',fmriprepDir));
subjects                                = subjects([subjects.isdir]);

apertureFolder                          = fullfile(projectDir,'Stimuli');
%%

%% prepare configuration files.
%
%  Function prepare_configs_vista will create 4 config files that are necessary
%  to run pRF vista solver in the docker. First two are configuration files
%  of the docker "*cfg.json", and fMRI "*bold.json" (param and
%  parambold variables defined in the beginning of this code) The
%  remaining two files are event file with stimulus details and a
%  coresponding json file. The output is the averge

param.sessionName        = 'nyu3t01';
param.subjectName        = 'wlsubj042';

average_name = preapre_configs_vista(projectDir,param,parambold,apertureFolder);


%% add an aperture file
copyfile([apertureFolder filesep 'apertures.nii.gz'],...
    [apertureFolder filesep sprintf('sub-%s_ses-%s_task-%s_apertures.nii.gz',...
    param.subjectName,param.sessionName,parambold.TaskName)])

%% convert to mgz using freesurfer
files_dir      = sprintf('%s/sub-%s/ses-%s/func',fmriprepDir,param.subjectName,param.sessionName);

d = dir(sprintf('%s/*fsnative*.gii',files_dir));
for ii = 1:length(d)
    
    [~, fname] = fileparts(d(ii).name);
    str = sprintf('mri_convert %s/%s.gii %s/%s.mgz',files_dir, fname, files_dir,fname);
    
    if ~exist(sprintf('%s/%s.mgz',files_dir, fname'),'file') == 1
        system(str);
    end
    
end

runnums           =  ones(1,length(d)/2);
dataFolder        = 'fmriprep';
dataStr           = 'fsnative*.mgz';


results = bidsVistaPRF(projectDir, param, parambold,runnums,dataFolder,dataStr,average_name,apertureFolder);





%% ******************************
% ******** SUBROUTINES **********
% *******************************

function file99name = preapre_configs_vista(projectDir,param,parambold,apertureFolder)


file99name = sprintf('%ssub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_acq-normal_run-99', ...
    projectDir,param.subjectName,param.sessionName,param.subjectName,param.sessionName,parambold.TaskName);

opt.ParseLogical = 1;
opt.FileName = [file99name '_cfg.json'];
savejson('',param,opt);

opt.FileName = [file99name '_bold.json'];
savejson('',parambold,opt);


aperture_size = size(niftiread([apertureFolder filesep 'apertures.nii.gz']));
fid.onset = zeros([aperture_size(3) 1]);
fid.duration = zeros([aperture_size(3) 1]);
fid.stim_file_index = zeros([aperture_size(3) 1]);

for f = 1 : aperture_size(3)
    
    fid.onset(f) = f - 1;
    fid.duration(f) = 1;
    fid.stim_file(f,:) = sprintf('sub-%s_ses-%s_task-%s_apertures.nii.gz',...
        param.subjectName,param.sessionName,parambold.TaskName);
    fid.stim_file_index(f) = f;
    
end

tdfwrite([projectDir filesep sprintf('sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.tsv',...
    param.subjectName,param.sessionName,param.subjectName,param.sessionName,parambold.TaskName)],fid);

stim_file_index.Description = '1-based index into the stimulus file of the relevant stimulus';
savejson('stim_file_index',stim_file_index,[projectDir filesep sprintf('sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.json',...
    param.subjectName,param.sessionName,param.subjectName,param.sessionName,parambold.TaskName)]);

end
