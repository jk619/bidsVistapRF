% To run PRF analysis on sample data
clc
clear
close all
%% 1. open matlab and add paths:
tbUse vista_docker;
addpath(genpath('./tdfwrite'))


param.solver                            = 'vista';
param.isPRFSynthData                    =  false;
param.options.model                     = 'one gaussian';
param.options.grid                      =  false
param.options.wsearch                   = 'coarse to fine';
% param.options.wsearch                   = 'coarse sample';
param.options.detrend                   = 1;
param.options.keepAllPoints             = false;
param.options.numberStimulusGridPoints  = 50;
param.stimulus.stimulus_diameter        = 24;

parambold.RepetitionTime                = 1;
parambold.SliceTiming                   = 0;
parambold.TaskName                      = 'prf';


[~,homedir]        = system('echo $HOME');
projectDir         = sprintf('%s/Dropbox/bidsAnalyzeVista/BIDS/bidsVistapRF',deblank(homedir));
fmriprepDir        = sprintf('%s/derivatives/fmriprep',projectDir);
subjects           = dir(sprintf('%s/*sub*',fmriprepDir));
subjects           = subjects([subjects.isdir]);
apertureFolder     = fullfile(projectDir,'Stimuli');


for s = 1  : length(subjects)
    
    tmp = strfind(subjects(s).name,'-');
    subject = subjects(s).name(tmp+1:end);
    
    param.sessionName        = 'nyu3t01';
    param.subjectName        = subject;
    
    file99name = sprintf('%s/sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_acq-normal_run-99', ...
        projectDir,param.subjectName,param.sessionName,param.subjectName,param.sessionName,parambold.TaskName);
    
    opt.ParseLogical = 1;
    
    opt.FileName = [file99name '_cfg.json'];
    savejson('',param,opt);
    
    opt.FileName = [file99name '_bold.json'];
    savejson('',parambold,opt);
    
    %% convert to mgz using freesurfer
    files_dir      = sprintf('%s/sub-%s/ses-%s/',fmriprepDir,subject,param.sessionName);
    
    d = dir(sprintf('%s/*fsnative*.gii',files_dir));
    for ii = 1:length(d)
        
        [~, fname] = fileparts(d(ii).name);
        str = sprintf('mri_convert %s/%s.gii %s/%s.mgz',files_dir, fname, files_dir,fname);
        
        if ~exist(sprintf('%s/%s.mgz',files_dir, fname'),'file') == 1
            system(str);
        end
        
    end
    
%     %% add an aperture file
    copyfile([apertureFolder filesep 'apertures.nii.gz'],...
        [apertureFolder filesep sprintf('sub-%s_ses-%s_task-%s_apertures.nii.gz',...
        subject,param.sessionName,parambold.TaskName)])
%     
%     %%  add events tsv
%         copyfile([apertureFolder filesep 'events.tsv'],...
%             [projectDir filesep sprintf('sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.tsv',...
%             subject,param.sessionName,subject,param.sessionName,parambold.TaskName)])
%     
    
%     fid = fopen([projectDir filesep sprintf('sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.tsv',...
%         subject,param.sessionName,subject,param.sessionName,parambold.TaskName)],'wt');
%     for f = 1 : 193
%         
%         if f == 1
%             thisline = ['onset duration stim_file stim_file_index'];
%             fprintf(fid,thisline);
%             
%         else
%             thisline = [num2str(f-1) '' num2str(1) ' ' sprintf('sub-%s_ses-%s_task-%s_apertures.nii.gz ',...
%                 subject,param.sessionName,parambold.TaskName) ' ' num2str(f-1) '\n']
%         end
%         
%         
%     end
%     fclose(fid);

    
    aperture_size = size(niftiread([apertureFolder filesep 'apertures.nii.gz']));
    fid.onset = zeros([aperture_size(3) 1]);
    fid.duration = zeros([aperture_size(3) 1]);
    fid.stim_file_index = zeros([aperture_size(3) 1]);
    
    for f = 1 : aperture_size(3)
        
        fid.onset(f) = f - 1;
        fid.duration(f) = 1;
        fid.stim_file(f,:) = sprintf('sub-%s_ses-%s_task-%s_apertures.nii.gz',...
        subject,param.sessionName,parambold.TaskName);
        fid.stim_file_index(f) = f;
        
    end
%%
     tdfwrite([projectDir filesep sprintf('sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.tsv',...
        subject,param.sessionName,subject,param.sessionName,parambold.TaskName)],fid)
    
     stim_file_index.Description = '1-based index into the stimulus file of the relevant stimulus'
     savejson('stim_file_index',stim_file_index,[projectDir filesep sprintf('sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.json',...
        subject,param.sessionName,subject,param.sessionName,parambold.TaskName)])
     
%%
%     fid.stim_file = stim_file;
%     T = table(fid.onset, fid.duration, fid.stim_file,fid.stim_file_index,'VariableNames',fieldnames(fid))
%     writetable(T,[projectDir filesep sprintf('sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.txt',...
%         subject,param.sessionName,subject,param.sessionName,parambold.TaskName)],'Delimiter',' ')

    
    %% add events json
%     copyfile([apertureFolder filesep 'events.json'],...
%         [projectDir filesep sprintf('sub-%s/ses-%s/func/sub-%s_ses-%s_task-%s_events.json',...
%         subject,param.sessionName,subject,param.sessionName,parambold.TaskName)])
%     
    %%
    dataFolder        = 'fmriprep';
    dataStr           = 'fsnative*.nii.gz';
    runnums           = 1:length(d)/2;
    modelType         = param.options.wsearch(~isspace(param.options.wsearch));
    stimulusinDeg     = param.stimulus.stimulus_diameter/2;
    
    bidspRFVista(projectDir, subject, param.sessionName, parambold.TaskName, runnums, ...
        dataFolder,dataStr,apertureFolder,modelType,stimulusinDeg,file99name,parambold.RepetitionTime)
    
    
end