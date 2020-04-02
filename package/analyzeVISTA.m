function analyzeVISTA(mainDir,cfg,averageFolDir,subject,session,apertureFolder,dockerscript)



stimulusDir = [apertureFolder filesep sprintf('sub-%s/ses-%s/',subject,session)];
cfgfile = [cfg.average_filename '_cfg.json'];

system(sprintf('chmod u+x ./package/%s',dockerscript))


% if contains(dockerscript,'singularity')
    
tmp = [tempdir 'config_pRF'];
mkdir(tmp)
% copyfile(cfgfile,[tmp filesep cfg.param.basename '_cfg.json'])
copyfile(cfgfile,[tmp filesep 'config.json'])

    
    
% elseif contains(dockerscript,'docker')

% end

system(sprintf('./package/%s vista %s %s %s %s',dockerscript,averageFolDir,tmp,stimulusDir,mainDir))

end

