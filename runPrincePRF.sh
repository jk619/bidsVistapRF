#! /bin/bash

## the following script can be used to run analyzePRF on the HPC cluster
## using the command 'sbatch runPrincePRF.sh'

## First we set up some SBATCH directives. Note that these are hard values
## if you go beyond your job will be killed by SLURM

#SBATCH --job-name=docker-vista
#SBATCH -a 0    # run this script as 2 jobs with SLURM_ARRAY_TASK_ID = 0 and 1. Add more numbers for more jobs!
#SBATCH --nodes=1 # nodes per job
#SBATCH --cpus-per-task=16 #~2 days to run PRFs
#SBATCH --mem=32g # More memory you request the less priority you get
#SBATCH --time=168:00:00 # Max request to be safe...
#SBATCH --output=/scratch/jk7127/logs/out_%x-%a.txt # Define output log location
#SBATCH --error=/scratch/jk7127/logs/err_%x-%a.txt # and the error logs for when it inevitably crashes
#SBATCH --mail-user=jk7127@nyu.edu #email
#SBATCH --mail-type=END #email me when it crashes or better, ends

# load matlab module
module load matlab/2019a

# load the freesurfer module
module load freesurfer/6.0.0



# We can bulk process by listing which subjects we want to run.
# Note, no comma seperation!
all_subjects=('wlsubj042')

# this variable tells us the job number:
jobnum=$SLURM_ARRAY_TASK_ID
if [ $jobnum -ge ${#all_subjects[@]} ]
then echo "Invalid subject id: $jobnum"
     exit 1
fi
sub=${all_subjects[$jobnum]}

# startup matlab...
matlab -nodesktop -nodisplay -nosplash <<EOF
subject='$sub';
warning off
% Different subjects have different run numbers so I tend to process them in groups
% that have the same EPI count.

% run the wrapper stript

vista_wrapper();

disp('Complete!');


EOF

exit 0
