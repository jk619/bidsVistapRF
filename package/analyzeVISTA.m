function analyzeVISTA(cfg)


newfilename = cfg.average_filename;

BIDS = strfind(newfilename,'BIDS')
BIDSdir = newfilename(1:BIDS-1);
cfgfile = [newfilename '_cfg.json'];

!chmod 755 ./package/prfanalyze.sh
system(sprintf('./package/prfanalyze.sh vista %s %s', ...
        BIDSdir,cfgfile))


end

