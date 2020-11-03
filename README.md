#bidsVistapRF

to run it as a singularity image we need to build the image remotely (if on mac)

singularity build --remote vista.simg docker 

where docker files is 

---------------------------------------
Bootstrap: docker
From: garikoitz/prfanalyze-vista:latest

%post
chmod 755 /compiled/run_prfanalyze_vista.sh 
chmod 755 /compiled/prfanalyze_vista

---------------------------------------

To use remote build you need to login to singularity sylabs on the cloud - > singularity remote login 
