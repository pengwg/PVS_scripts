#!/bin/bash

DATA_PATH=/projects/2024-11_Perivascular_Space/PVS_Data4
FS_PATH=/projects/2024-11_Perivascular_Space/PVS_B4_Analysis/FS

source /home/pw0032/lst-ai/lst/bin/activate
    
for i in {1..45}; do
    FILE_ID=$(printf "PVS_4_%03d" $i)

    T1_VOL=$(find $FS_PATH/$FILE_ID/mri/ -type f -name nu.mgz | head -n 1)
    FLAIR_VOL=$(find $DATA_PATH/$FILE_ID -type f -name "${FILE_ID}_T2_SPACE_FLAIR*.nii" | head -n 1)
    T2_VOL=$(find $DATA_PATH/ -type f \( -name "${FILE_ID}_T2_SPACE_AX*" -o -name "${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)

    OUT_PATH=/projects/2024-11_Perivascular_Space/PVS_B4_Analysis/LST/$FILE_ID

    if ! [ -d $OUT_PATH ]; then
        mkdir $OUT_PATH
    fi

    mri_convert $T1_VOL $T1_VOL.nii.gz

    singularity exec -e /cm/shared/containers/ANTs.sif antsRegistrationSyNQuick.sh -d 3 -t r -f $T1_VOL.nii.gz -m $FLAIR_VOL -o $OUT_PATH/flair2T1_ -n 20

    echo "LST processing $OUT_PATH/fair2T1_Warped.nii.gz"
    lst --t1 $T1_VOL.nii.gz --flair $OUT_PATH/flair2T1_Warped.nii.gz --output $OUT_PATH/ --temp $OUT_PATH/tmp/

done
