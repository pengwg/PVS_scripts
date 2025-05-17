clear

p = gcp('nocreate');
if isempty(p)
    parpool(12);
end

parfor n = 33 : 33
    PVS_subject(n)
end

return

function PVS_subject(id)

addpath('filters/frangi_filter_version2a/')

data_path = '/projects/2024-11_Perivascular_Space/batch1_output/FS';
out_path = '/projects/2024-11_Perivascular_Space/batch1_output/PVS_vessel';

Options.BlackWhite = false;
Options.FrangiScaleRange = [0.5 4];
Options.FrangiScaleRatio = 0.5;
Options.FrangiC = 60;


subject = sprintf('PVS_%03d', id);
T2_fs = [data_path '/' subject '/mri/T2.prenorm.mgz'];
T2_nii = [data_path '/' subject '/mri/T2.prenorm.nii'];
seg_fs = [data_path '/' subject '/mri/aparc+aseg.mgz'];
seg_nii = [data_path '/' subject '/mri/aparc+aseg.nii'];

if exist(T2_fs, 'file') ~= 2
    return
end

if exist(T2_nii, 'file') ~= 2
    system(['mri_convert ' T2_fs ' ' T2_nii]);
end

if exist(seg_nii, 'file') ~= 2
    system(['mri_convert ' seg_fs ' ' seg_nii]);
end

disp(['Measure  ' subject '...' ])

info = niftiinfo(T2_nii);
T2_vol = niftiread(info);

[J,Scale,Vx,Vy,Vz] = FrangiFilter3D(T2_vol, Options);

niftiwrite(J, [out_path '/' subject '_vesselness'], info, 'Compressed',true)
% niftiwrite(Scale, [out_path '/' subject '_ScaleC60'], info, 'Compressed',true)
% J = niftiread([out_path '/' subject '_vesselness.nii.gz']);
vessels = J;

seg_vol = niftiread(seg_nii);
ventricals = ismember(seg_vol, [4, 5, 14, 43, 44]);
ventricals = imdilate(ventricals, strel('sphere', 5));
hippocampus = ismember(seg_vol, [17, 53]);

wmbg_mask = ismember(seg_vol, [2, 41, 11, 12, 13, 26, 50, 51, 52, 58]);
wmbg_mask(ventricals | hippocampus) = 0;

vessels(~wmbg_mask) = 0;
threshold = 5e-3;
vessels(vessels < threshold) = 0;
vessels(vessels >= threshold) = 1;

niftiwrite(vessels, [out_path '/' subject '_PVS_wmbg'], info, 'Compressed',true)

end
