function makeReport_vista(projectDir,subject,session,runnums)


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



latestDir = find_latest_dir(projectDir);


resultsdir   = fullfile (projectDir,'derivatives',latestDir, ...
    sprintf('sub-%s',subject), sprintf('ses-%s',session));

Maps2PNG_vista(projectDir,resultsdir,subject,runnums);

end
%% ******************************
% ******** SUBROUTINES **********
% *******************************


function latestDir = find_latest_dir(projectDir)


d = dir(sprintf('%s/derivatives/',projectDir));
d = d([d(:).isdir]==1);
[~,id] = sort([d.datenum]);
d = d(id);
latestDir = d(end).name;

end
