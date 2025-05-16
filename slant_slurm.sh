#!/bin/bash

#SBATCH --array=084
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=1            
#SBATCH --partition=gpu
#SBATCH --gpus=1

DATA_PATH=/home/pw0032/PVS_nii

# FILE_ID=$(printf "%03d" $SLURM_ARRAY_TASK_ID)
FILE_ID=084

T1_VOL=$(find $DATA_PATH/ -type f -name "PVS_${FILE_ID}_T1_RAGE_*.nii.gz" | head -n 1)
FLAIR_VOL=$(find $DATA_PATH/ -type f -name "PVS_${FILE_ID}_T2_SPACE_FLAIR*.nii.gz" | head -n 1)
T2_VOL=$(find $DATA_PATH/ -type f \( -name "PVS_${FILE_ID}_T2_SPACE_AX*" -o -name "PVS_${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)

export INDIR=/home/pw0032/Data/batch1_output/SLANT/input_$FILE_ID
export OUTDIR=/home/pw0032/Data/batch1_output/SLANT/output_$FILE_ID
export tempDIR=/home/pw0032/Data/batch1_output/SLANT/tmp_$FILE_ID
export TMPDIR=$tempDIR
export SINGULARITYENV_LD_PRELOAD=""

echo $T1_VOL
echo $INDIR

if ! [ -d "$INDIR" ]; then
    mkdir $INDIR
fi

if ! [ -d "$OUTDIR" ]; then
    mkdir $OUTDIR
fi

if ! [ -d "$tempDIR" ]; then
    mkdir $tempDIR
fi

cp $T1_VOL $INDIR/

module load singularity 
singularity exec --nv -e -B $INDIR:/INPUTS -B $OUTDIR:/OUTPUTS -B $tempDIR:/tmp /cm/shared/containers/SLANT.sif /extra/run_deep_brain_seg.sh
