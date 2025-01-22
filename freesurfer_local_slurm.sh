#!/bin/bash

#SBATCH --array=0-29  
#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=10            

FILE_PATH=/home/pw0032/PVS_nii

mapfile -t FILES_NUM < file_numbers.txt

FILE_TO_PROCESS=PVS_${FILES_NUM[$SLURM_ARRAY_TASK_ID]}_T1_RAGE_SAG.nii.gz

srun recon-all -all -hires -parallel -openmp 10 -i "$FILE_PATH/$FILE_TO_PROCESS" -s PVS_${FILES_NUM[$SLURM_ARRAY_TASK_ID]}
