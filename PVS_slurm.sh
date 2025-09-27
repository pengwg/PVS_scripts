#!/bin/bash

#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=16

matlab -batch "PVS_subjects_all"
matlab -batch "PVS_measurement"
