#bidsVistapRF

To run it as a singularity image we need to build the image remotely (if on mac)

singularity build --remote vista.simg docker 

where docker file is 

------------------

Bootstrap: docker <br/>
From: garikoitz/prfanalyze-vista:latest

%post<br/>
chmod 755 /compiled/run_prfanalyze_vista.sh<br/> 
chmod 755 /compiled/prfanalyze_vista

------------------

To use remote build you need to login to singularity sylabs on the cloud - > singularity remote login 
