#!/bin/bash

#SBATCH --partition=bigmem
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=12

matlab -nodisplay -r "PVS_subjects_all; exit;"

