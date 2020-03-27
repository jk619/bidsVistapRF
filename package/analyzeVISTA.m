function analyzeVISTA(file99name)


BIDS = strfind(file99name,'BIDS')
BIDSdir = file99name(1:BIDS-1);
cfgfile = [file99name '_cfg.json'];
!chmod 755 ./package/prfanalyze.sh
system(sprintf('./package/prfanalyze.sh vista %s %s', ...
        BIDSdir,cfgfile))


end

