function analyzeVISTA(mainDir,cfg,averageFolDir,subject,session,apertureFolder,dockerscript)



stimulusDir = [apertureFolder filesep sprintf('sub-%s/ses-%s/',subject,session)];
cfgfile = [cfg.average_filename '_cfg.json'];


system(sprintf('chmod 755 ./package/%s',dockerscript))
system(sprintf('./package/%s vista %s %s %s %s',dockerscript,averageFolDir,cfgfile,stimulusDir,mainDir))


end

