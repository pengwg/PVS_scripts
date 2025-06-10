clear

addpath('matlab_auxiliary/')

data_path = '/projects/2024-11_Perivascular_Space/batch1_output';
% data_path = '~/Data';
PVS_path = [data_path '/PVS_vessel'];
FS_path = [data_path '/FS'];

PVS_measure_region('wmbg', PVS_path, FS_path)
PVS_measure_region('nawmbg', PVS_path, FS_path)
PVS_measure_region('wm', PVS_path, FS_path)
PVS_measure_region('nawm', PVS_path, FS_path)
PVS_measure_region('bg', PVS_path, FS_path)

return


function PVS_measure_region(region, PVS_path, FS_path)

ar_threshold = 1.5;

stats = zeros(140, 15);
number = zeros(140, 1);
pvsTotalVol = zeros(140, 1);
brainVol = zeros(140, 1);

p = gcp('nocreate');
if isempty(p)
    parpool(6);
end

parfor n = 1 : 140
    subject = sprintf('PVS_%03d_vsmask_%s.nii.gz', n, region);
    mask_file = [PVS_path '/' subject];

    if exist(mask_file, 'file') ~= 2
        continue
    end

    disp(['Measure ' subject '...' ])

    brain_fs = sprintf('%s/PVS_%03d/mri/brainmask.mgz', FS_path, n);
    brain_nii = sprintf('%s/PVS_%03d/mri/brainmask.nii.gz', FS_path, n);
    disp(brain_nii)
    
    if exist(brain_nii, 'file') ~= 2
        system(['mri_convert ' brain_fs ' ' brain_nii]);
    end
    info = niftiinfo(brain_nii);
    brain = niftiread(info);
    brainVol(n) = nnz(brain > 0) * prod(info.PixelDimensions);

    info = niftiinfo(mask_file);
    mask_vol = niftiread(info);

    filtered_vol = threashold_PVS_ar(mask_vol, ar_threshold);
    niftiwrite(filtered_vol, sprintf('%s/PVS_%03d_vsmask_%s_noblob', PVS_path, n, region), info, 'Compressed', true);

    [stats_subject, measure_all] = measurePVSstats(filtered_vol, info.PixelDimensions);
    stats(n, :) = stats_subject';
    number(n) = size(measure_all, 1);
    
    if isempty(measure_all) 
        continue
    end

    length = measure_all(:, 1);
    width = measure_all(:, 2);
    volume = measure_all(:, 3);
    pvsTotalVol(n) = sum(volume);

    writetable(table(length, width, volume), sprintf('subjects_stats/PVS1_%03d_%s_noblob.xlsx', n, region));

end

lengthMean = stats(:, 1);
lengthMedian = stats(:, 2);
lengthStd = stats(:, 3);
lengthPrc25 = stats(:, 4);
lengthPrc75 = stats(:, 5);

widthMean = stats(:, 6);
widthMedian = stats(:, 7);
widthStd = stats(:, 8);
widthPrc25 = stats(:, 9);
widthPrc75 = stats(:, 10);

sizeMean = stats(:, 11);
sizeMedian = stats(:, 12);
sizeStd = stats(:, 13);
sizePrc25 = stats(:, 14);
sizePrc75 = stats(:, 15);
subjectID = (1 : 140)';

T = table(subjectID, brainVol, pvsTotalVol, number, lengthMean, lengthMedian, lengthStd, lengthPrc25, lengthPrc75, ...
          widthMean, widthMedian, widthStd, widthPrc25, widthPrc75, ...
          sizeMean, sizeMedian, sizeStd, sizePrc25, sizePrc75);

writetable(T, ['PVS1_stats_' region, '_noblob.xlsx'])

end

%%
function out_vol = threashold_PVS_ar(PVS_vol, threshold)
    PVSstats3 = regionprops3(logical(PVS_vol),"PrincipalAxisLength", "VoxelIdxList", "Volume");
    ar = PVSstats3.PrincipalAxisLength(:,1) ./ PVSstats3.PrincipalAxisLength(:,2);

    for i = 1 : height(PVSstats3)
        if ar(i) < threshold || PVSstats3.Volume(i) < 3
            PVS_vol(PVSstats3.VoxelIdxList{i}) = 0;
        end
    end
    out_vol = PVS_vol;
end
