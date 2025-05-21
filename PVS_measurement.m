clear

addpath('matlab_auxiliary/')

PVS_measure_region('wmbg')
PVS_measure_region('wm')
PVS_measure_region('caudate')
PVS_measure_region('putamen')
PVS_measure_region('pallidum')
PVS_measure_region('accumbens')

return


function PVS_measure_region(region)

data_path = '/tm/Data/vesselmask';
FS_path = '/tm/Data/FS_PVS';

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
    mask_file = [data_path '/' subject];

    if exist(mask_file, 'file') ~= 2
        continue
    end

    disp(['Measure ' subject '...' ])

    brain_fs = sprintf('%s/PVS_%03d/mri/brainmask.mgz', FS_path, n);
    brain_nii = sprintf('%s/PVS_%03d/mri/brainmask.nii.gz', FS_path, n);
    if exist(brain_nii, 'file') ~= 2
        system(['mri_convert ' brain_fs ' ' brain_nii]);
    end
    info = niftiinfo(brain_nii);
    brain = niftiread(info);
    brainVol(n) = nnz(brain > 0) * prod(info.PixelDimensions);

    info = niftiinfo(mask_file);
    mask_vol = niftiread(info);

    [stats_subject, measure_all] = measurePVSstats(mask_vol, info.PixelDimensions);
    stats(n, :) = stats_subject';
    number(n) = size(measure_all, 1);
    
    if isempty(measure_all) 
        continue
    end

    length = measure_all(:, 1);
    width = measure_all(:, 2);
    volume = measure_all(:, 3);
    pvsTotalVol(n) = sum(volume);

    writetable(table(length, width, volume), sprintf('../output/PVS_%03d_%s_measurement.xlsx', n, region));
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

writetable(T, ['../output/PVS_stats_' region, '.xlsx'])

end