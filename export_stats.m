function export_stats(subjectIDs, eTIV, vol_brainmask, structure, structure_name)

VariableNames = ["subjectIDs", "eTIV", "BrainMask Vol", "Num PVS", [structure_name ' Vol'], "PVS Vol", "PVS Vol Mean", "PVS Vol Median", ...
                 "PVS Length Mean", "PVS Lenght Median", "PVS Width Mean", "PVS Width Median"];
T = table(subjectIDs, eTIV, vol_brainmask, [structure.numPVS]', [structure.Vol]', [structure.pvsVol]', [structure.pvsVolMean]', [structure.pvsVolMedian]', [structure.lengthMean]', [structure.lengthMedian]', [structure.widthMean]', [structure.widthMedian]', ...
            'VariableNames', VariableNames);
writetable(T, 'PVS_stats_nnUNet_Apr16.xlsx', 'Sheet', structure_name, 'WriteMode', 'overwritesheet')

end

