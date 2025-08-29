#!/bin/bash

#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=12

matlab -batch "PVS_subjects_all"

