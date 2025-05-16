#!/bin/bash

#SBATCH --array=1-140%10
#SBATCH --partition=bigmem
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=1

matlab -nodisplay -r "PVS_subject($SLURM_ARRAY_TASK_ID); exit;"

