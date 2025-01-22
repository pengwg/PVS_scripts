clear

job_array_size = 30;

x0 = 1;
while x0 <= 140
    xn = min(140, x0 + job_array_size - 1);
    file_numbers = arrayfun(@(x) sprintf('%03d', x), x0:xn , 'UniformOutput', false);

    fid = fopen('file_numbers.txt', 'w');
    fprintf(fid, '%s\n', file_numbers{:});
    fclose(fid);

    x0 = x0 + job_array_size;

    [status, output] = system('sbatch freesurfer_local_slurm.sh');

    if status == 0
        jobID = str2double(regexp(output, '(\d+)', 'match', 'once'));
        fprintf('Job submitted with ID: %d\n', jobID);

        jobFinished = false;

        while ~jobFinished
            [status, jobStatus] = system(['squeue --job ', num2str(jobID)]);

            if status == 0
                % Split jobStatus into lines
                jobLines = strsplit(strtrim(jobStatus), '\n');
		disp(jobLines)

                if length(jobLines) <= 1
                    jobFinished = true;
                    disp('All jobs have finished! Next batch ...');
                else
                    disp('There are still running jobs...');
                    pause(30); % Wait 30 seconds before checking again
                end
            else
                disp('Error checking job status');
                break;
            end
        end

    else
        disp('Failed to submit job');
    end

end

disp('All batch finished!')

