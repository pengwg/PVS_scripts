function export_stats(subjectIDs, eTIV, vol_brainmask, structure, structure_name)

VariableNames = ["subjectIDs", "eTIV", "BrainMask Vol", [structure_name ' Vol'], "Num PVS", "PVS Total Vol", "PVS Vol Mean", "PVS Vol Median", ...
                 "PVS Length Mean", "PVS Lenght Median", "PVS Width Mean", "PVS Width Median"];
T = table(subjectIDs, eTIV, vol_brainmask, [structure.Vol]', [structure.numPVS]', [structure.pvsVol]', [structure.pvsVolMean]', [structure.pvsVolMedian]', [structure.lengthMean]', [structure.lengthMedian]', [structure.widthMean]', [structure.widthMedian]', ...
            'VariableNames', VariableNames);
writetable(T, 'stats_all/PVS_stats_nnUNet_Apr21.xlsx', 'Sheet', structure_name, 'WriteMode', 'overwritesheet')

end

