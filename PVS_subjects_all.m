clear

p = gcp('nocreate');
if isempty(p)
    parpool(12);
end

parfor n = 1 : 140
    PVS_subject(n)
end

return


%%
function PVS_subject(id)

addpath('filters/frangi_filter_version2a/')

data_path = '/projects/2024-11_Perivascular_Space/batch1_output/FS';
out_path = '/projects/2024-11_Perivascular_Space/batch1_output/PVS_vessel';
lst_path = '/projects/2024-11_Perivascular_Space/batch1_output/LST';

Options.BlackWhite = false;
Options.FrangiScaleRange = [0.5 4];
Options.FrangiScaleRatio = 0.5;
Options.FrangiC = 60;
threshold = 5e-3;

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

if exist([out_path '/' subject '_vesselness.nii.gz'], 'file') == 2
    vessleness = niftiread([out_path '/' subject '_vesselness.nii.gz']);
else
    T2_vol = niftiread(info);
    [vessleness,Scale,Vx,Vy,Vz] = FrangiFilter3D(T2_vol, Options);

    niftiwrite(vessleness, [out_path '/' subject '_vesselness'], info, 'Compressed',true)
    % niftiwrite(Scale, [out_path '/' subject '_ScaleC60'], info, 'Compressed',true)
end

wmh = niftiread([lst_path '/' subject '/space-flair_seg-lst.nii.gz']);

seg_vol = niftiread(seg_nii);
ventricals = ismember(seg_vol, [4, 5, 14, 43, 44]);
ventricals = imdilate(ventricals, strel('sphere', 5));
% hippocampus = ismember(seg_vol, [17, 53]);

wmbg_mask = ismember(seg_vol, [2, 41, 11, 12, 13, 26, 50, 51, 52, 58]);
wmbg_mask(ventricals) = 0;

vesselmask = vessel_region_threshold(vessleness, wmbg_mask, threshold);
niftiwrite(vesselmask, [out_path '/' subject '_vsmask_wmbg'], info, 'Compressed',true)

vesselmask(logical(wmh)) = 0;
niftiwrite(vesselmask, [out_path '/' subject '_vsmask_nawmbg'], info, 'Compressed',true)

wm_mask = ismember(seg_vol, [2, 41]);
wm_mask(ventricals) = 0;

vesselmask = vessel_region_threshold(vessleness, wm_mask, threshold);
niftiwrite(vesselmask, [out_path '/' subject '_vsmask_wm'], info, 'Compressed',true)

vesselmask(logical(wmh)) = 0;
niftiwrite(vesselmask, [out_path '/' subject '_vsmask_nawm'], info, 'Compressed',true)

bg_mask = ismember(seg_vol, [11, 12, 13, 26, 50, 51, 52, 58]);
bg_mask(ventricals) = 0;

vesselmask = vessel_region_threshold(vessleness, bg_mask, threshold);
niftiwrite(vesselmask, [out_path '/' subject '_vsmask_bg'], info, 'Compressed',true)


% caudate_mask = ismember(seg_vol, [11, 50]);
% caudate_mask(ventricals) = 0;
% 
% putamen_mask = ismember(seg_vol, [12, 51]);
% putamen_mask(ventricals) = 0;
% 
% pallidum_mask = ismember(seg_vol, [13, 52]);
% pallidum_mask(ventricals) = 0;
% 
% accumbens_mask = ismember(seg_vol, [26, 58]);
% accumbens_mask(ventricals) = 0;

end


%%
function vesselmask = vessel_region_threshold(vesselness, region_mask, threshold)

vesselmask = vesselness;
vesselmask(~region_mask) = 0;
vesselmask(vesselmask < threshold) = 0;
vesselmask(vesselmask >= threshold) = 1;

end

