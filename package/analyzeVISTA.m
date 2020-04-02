function analyzeVISTA(mainDir,cfg,averageFolName,subject,session,apertureFolder,dockerscript)



mystimdir = [apertureFolder filesep sprintf('sub-%s/ses-%s/',subject,session)];
cfgfile = [cfg.average_filename '_cfg.json'];
% outputdir = sprintf('%s',projectDir)
% outputdir = averageFolName;


system(sprintf('chmod 755 ./package/%s',dockerscript))
system(sprintf('./package/%s vista %s %s %s %s',dockerscript,averageFolName,cfgfile,mystimdir,mainDir))


end

