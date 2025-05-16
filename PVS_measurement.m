clear
addpath('matlab_auxiliary/')

data_path = '/tm/Data/vesselmask';

stats = zeros(140, 15);
number = zeros(140, 1);
totalVol = zeros(140, 1);

for n = 1 : 140
    subject = sprintf('PVS_%03d_vesselmask60.nii.gz', n);
    mask_file = [data_path '/' subject];

    if exist(mask_file, 'file') ~= 2
        continue
    end

    disp(['Measure  ' subject '...' ])

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
    totalVol(n) = sum(volume);

    writetable(table(length, width, volume), ['subject_stats/PVS_' subject '_measure.xlsx']);
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

T = table(subjectID, totalVol, number, lengthMean, lengthMedian, lengthStd, lengthPrc25, lengthPrc75, ...
          widthMean, widthMedian, widthStd, widthPrc25, widthPrc75, ...
          sizeMean, sizeMedian, sizeStd, sizePrc25, sizePrc75);

writetable(T, 'PVS_stats_all.xlsx')
