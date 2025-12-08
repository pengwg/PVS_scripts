clear

p = gcp('nocreate');
if isempty(p)
    parpool(16);
end

parfor n = 1 : 54
    PVS_subject(n)
end

return


%%
function PVS_subject(id)

addpath('filters/frangi_filter_version2a/')
addpath('matlab_auxiliary/')

rerun_frangi = false;
Options.BlackWhite = false;
Options.FrangiScaleRange = [0.5 4];
Options.FrangiScaleRatio = 0.5;
Options.FrangiC = 60;
threshold = 5e-3;

subject = sprintf('PVS_2_%03d', id);

data_path = '/projects/2024-11_Perivascular_Space/PVS_B2_Analysis';
out_path = [data_path '/Frangi_pruned/' subject];

T2_nii = [out_path '/T2toT1_iso.nii.gz'];
seg_nii = [out_path '/aseg_iso.nii.gz'];
cso_nii = [out_path '/cso_mask_iso.nii.gz'];
lst_nii = [data_path '/LST/' subject '/space-flair_seg-lst.nii.gz'];

if exist(T2_nii, 'file') ~= 2
    return
end

if exist(seg_nii, 'file') ~= 2
    return
end

if exist(lst_nii, 'file') ~= 2
    return
end

disp(['Resample LST  ' subject '...' ])
system(['singularity exec -e /cm/shared/containers/ANTs.sif ResampleImageBySpacing 3 ' lst_nii ' ' out_path '/lst.nii.gz 0.4 0.4 0.4 0 0 1'])

info = niftiinfo(T2_nii);
T2_vol = niftiread(info);

out_name = [out_path '/' subject '_vesselness'];

if rerun_frangi || exist([out_name, '.nii.gz'], 'file') ~= 2
    disp(['Frangi filter  ' subject '...' ])
    [vessleness,Scale,~,~,~] = FrangiFilter3D(T2_vol, Options);
    niftiwrite(vessleness, out_name, info, 'Compressed',true)
    % niftiwrite(Scale, [out_path '/' subject '_ScaleC60'], info, 'Compressed',true)
    
else
    vessleness = niftiread([out_name, '.nii.gz']);
end

wmh = niftiread([out_path '/lst.nii.gz']);

seg_vol = niftiread(seg_nii);
ventricals = ismember(seg_vol, [4, 5, 14, 43, 44]);
ventricals = imdilate(ventricals, strel('sphere', 5));
% hippocampus = ismember(seg_vol, [17, 53]);

wmbg_mask = ismember(seg_vol, [2, 41, 11, 12, 13, 26, 50, 51, 52, 58]);
wmbg_mask(ventricals) = 0;

disp(['Segment  ' subject '...' ])

[vesselness_wmbg, vesselmap_wmbg] = vessel_region_threshold(vessleness, wmbg_mask, threshold);
niftiwrite(vesselness_wmbg, [out_path '/' subject '_vesselness_wmbg'], info, 'Compressed',true)
niftiwrite(vesselmap_wmbg, [out_path '/' subject '_vsmask_wmbg_preseg'], info, 'Compressed',true)

vesselmap_wmbg_seg = PVS_segment(vesselmap_wmbg, T2_vol);
niftiwrite(vesselmap_wmbg_seg, [out_path '/' subject '_vsmask_wmbg'], info, 'Compressed',true)

vesselmap_nawmbg = vesselmap_wmbg_seg;
vesselmap_nawmbg(logical(wmh)) = 0;
niftiwrite(vesselmap_nawmbg, [out_path '/' subject '_vsmask_nawmbg'], info, 'Compressed',true)

wm_mask = ismember(seg_vol, [2, 41]);

vesselmap_wm = vesselmap_wmbg_seg;
vesselmap_wm(~logical(wm_mask)) = 0;
niftiwrite(vesselmap_wm, [out_path '/' subject '_vsmask_wm'], info, 'Compressed',true)

cso_mask = niftiread(cso_nii);
vesselmap_cso = vesselmap_wm;
vesselmap_cso(~logical(cso_mask)) = 0;
niftiwrite(vesselmap_cso, [out_path '/' subject '_vsmask_cso'], info, 'Compressed',true)

vesselmap_cso(logical(wmh)) = 0;
niftiwrite(vesselmap_cso, [out_path '/' subject '_vsmask_nacso'], info, 'Compressed',true)

vesselmap_wm(logical(wmh)) = 0;
niftiwrite(vesselmap_wm, [out_path '/' subject '_vsmask_nawm'], info, 'Compressed',true)

vesselmap_bg = vesselmap_wmbg_seg;
vesselmap_bg(logical(wm_mask)) = 0;
niftiwrite(vesselmap_bg, [out_path '/' subject '_vsmask_bg'], info, 'Compressed',true)

end


%%
function [vesselness_region, vesselmap_region] = vessel_region_threshold(vesselness, region_mask, threshold)

vesselness_region = vesselness;
vesselness_region(~region_mask) = 0;

vesselmap_region = vesselness_region;
vesselmap_region(vesselmap_region < threshold) = 0;
vesselmap_region(vesselmap_region >= threshold) = 1;

end

%%
function vesslemap_pruned = PVS_segment(vesslemap, T2)

minVol = 6;
maxVol = 400;

% -------------------------------------------------------------------
%  The following was added for separating the clustered PVS in BG
%--------------------------------------------------------------------
CC = bwconncomp(logical(vesslemap), 18); % Connected component analysis
L = labelmatrix(CC); % label objects
ST = regionprops3(CC, 'Volume', 'BoundingBox', 'VoxelIdxList');

vesslemap_pruned = vesslemap;
% Find volume within expected size
SI = size(T2);
for n = 1 : length(ST.Volume)
    if ST.Volume(n) <= minVol
        vesslemap_pruned(ST.VoxelIdxList{n}) = 0;

    elseif ST.Volume(n) > maxVol
        bbox = ST.BoundingBox(n, :);
        bbox = round(bbox);
        bbox(bbox==0) = 1;
        bbox(4:6) = bbox(4:6) + bbox(1:3) + 1;
        bbox(1:3) = max(bbox(1:3) - 1, 1);
        if bbox(4) > SI(2)
            bbox(4) = SI(2);
        end
        if bbox(5) > SI(1)
            bbox(5) = SI(1);
        end
        if bbox(6) > SI(3)
            bbox(6) = SI(3);
        end
        tempVSL2 = L(bbox(2):bbox(5), bbox(1):bbox(4), bbox(3):bbox(6));
        tempVSL = tempVSL2 == n;
        tempI = T2(bbox(2):bbox(5), bbox(1):bbox(4), bbox(3):bbox(6));
        
        ff = prunePVS(tempVSL,tempI);
        
        vesslemap_pruned(bbox(2):bbox(5), bbox(1):bbox(4), bbox(3):bbox(6)) = ...
            ff + (tempVSL==0 & L(bbox(2):bbox(5), bbox(1):bbox(4), bbox(3):bbox(6)) > 0);
    end
end

end

