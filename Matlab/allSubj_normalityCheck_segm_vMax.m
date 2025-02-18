%% Clean-up
clear; close all; clc;

%% Summary of experiment:
% Objective: Track arm movements of subjects under different conditions.
% Conditions:
%           1.	Standing
%           2.	Sitting without constraint
%           3.	Wrist constrained
%           4.	Wrist, shoulder, and elbow constrained
% Left arm and right arm for each condition
% Number of Trials for each arm: 6 trials per condition after ignoring the first trial.
% Segments: Movements between specific key points (Start → TP1, TP1 → TP2, …, TP5 → TP6).
% Number of Subjects: 4 subjects so far.
% Measurements: Peak velocity during arm movements.
% Data Type: Continuous numerical data (peak velocities in m/s).


%% Load subject data (s1, s2, s3)
subjects = {'s1', 's2', 's3'};
num_subjects = length(subjects);
subjectData_all = cell(1, num_subjects);

for i = 1:num_subjects
    load(['Matlab_data/', subjects{i}, '.mat']); % Load subject file
    if ~exist('subjectData', 'var')
        error(['Variable subjectData not found in ', subjects{i}, '.mat']);
    end
    subjectData_all{i} = subjectData; % Store data
end

%% Define conditions and labels
conditions = {'st', 'noC', 'wr', 'c'};
condition_labels = {'Standing', 'Sitting without constraints', 'Only wrist constrained', 'Wrist, shoulder, and elbow constrained'};
arms = {'l', 'r'};

% Define Start and TP Positions
key_points = [-0.00051, 0.120593; -0.12048, 0.018975; -0.0798, 0.1511; ...
    0.0493, -0.0192; 0.1, 0.06; -0.0951, -0.0404; 0.131264, 0.140562];
key_labels = {'Start', 'TP1', 'TP2', 'TP3', 'TP4', 'TP5', 'TP6'};
num_segments = length(key_points) - 1;
radius_threshold = 0.003; % 3 mm radius

%% Extract Peak Velocities per Segment
peak_velocities = struct();

for c = 1:length(conditions)
    condition = conditions{c};

    for seg = 1:num_segments
        peak_velocities.(condition).x{seg} = [];
        peak_velocities.(condition).y{seg} = [];
    end

    for s = 1:num_subjects
        for a = 1:length(arms)
            arm = arms{a};

            for trial = 2:7 % Ignore trial 1
                if isfield(subjectData_all{s}, condition) && isfield(subjectData_all{s}.(condition), arm) ...
                        && length(subjectData_all{s}.(condition).(arm)) >= trial

                    data = subjectData_all{s}.(condition).(arm){trial};

                    if isfield(data, 'velX_mps') && isfield(data, 'velY_mps')
                        velX = data.velX_mps;
                        velY = data.velY_mps;
                        posX = data.posX_m;
                        posY = data.posY_m;

                        % Segment movements
                        for seg = 1:num_segments
                            start_idx = seg;
                            end_idx = seg + 1;

                            % Find movement start and end indices
                            start_dist = sqrt((posX - key_points(start_idx,1)).^2 + (posY - key_points(start_idx,2)).^2);
                            idx_start = find(start_dist <= radius_threshold, 1, 'last');

                            end_dist = sqrt((posX - key_points(end_idx,1)).^2 + (posY - key_points(end_idx,2)).^2);
                            idx_end = find(end_dist <= radius_threshold, 1, 'first');

                            if ~isempty(idx_start) && ~isempty(idx_end) && idx_start < idx_end
                                segmentVelX = velX(idx_start:idx_end);
                                segmentVelY = velY(idx_start:idx_end);

                                % Extract Peak Velocity
                                peakVelX = max(abs(segmentVelX));
                                peakVelY = max(abs(segmentVelY));

                                % Store peak velocity data
                                peak_velocities.(condition).x{seg} = [peak_velocities.(condition).x{seg}; peakVelX];
                                peak_velocities.(condition).y{seg} = [peak_velocities.(condition).y{seg}; peakVelY];
                            end

                        end


                        
                        % % Inside your segmentation loop:
                        % for seg = 1:num_segments
                        %     start_idx = seg;
                        %     end_idx = seg + 1;
                        % 
                        %     start_dist = sqrt((posX - key_points(start_idx,1)).^2 + (posY - key_points(start_idx,2)).^2);
                        %     idx_start = find(start_dist <= radius_threshold, 1, 'last');
                        % 
                        %     end_dist = sqrt((posX - key_points(end_idx,1)).^2 + (posY - key_points(end_idx,2)).^2);
                        %     idx_end = find(end_dist <= radius_threshold, 1, 'first');
                        % 
                        %     fprintf('Subject %d, Condition %s, Arm %s, Trial %d, Segment %d: Start_idx = %d, End_idx = %d\n', ...
                        %         s, condition, arm, trial, seg, idx_start, idx_end);
                        % 
                        %     if isempty(idx_start) || isempty(idx_end) || idx_start >= idx_end
                        %         warning('Invalid indices for Segment %d in Trial %d for %s (%s)', seg, trial, condition, arm);
                        %     end
                        % end




                    end
                end
            end
        end
    end
end

%% Normality Tests: Jarque-Bera & Kolmogorov-Smirnov
% Jarque-Bera test: Checks skewness and kurtosis.
% Kolmogorov-Smirnov test: Compares the empirical distribution to a normal distribution.
% Null hypothesis: data is normal
% h = 0 (p-value > 0.05): Data is normal (fail to reject H0) -> parametric tests (e.g., t-tests, ANOVA)
% h = 1 (p-value <= 0.05): Data is not normal (reject H0) -> non-parametric tests (e.g., Mann-Whitney U test, Kruskal-Wallis test)

alpha = 0.05; % Significance level

% for seg = 1:num_segments
%     fprintf('=== Normality Tests: %s → %s ===\n', key_labels{seg}, key_labels{seg+1});
%     for c = 1:length(conditions)
%         condition = conditions{c};
%         peak_x = peak_velocities.(condition).x{seg};
%         peak_y = peak_velocities.(condition).y{seg};
%         [h_x_jb, p_x_jb] = jbtest(peak_x, alpha);
%         [h_y_jb, p_y_jb] = jbtest(peak_y, alpha);
%         [h_x_ks, p_x_ks] = kstest((peak_x - mean(peak_x)) / std(peak_x));
%         [h_y_ks, p_y_ks] = kstest((peak_y - mean(peak_y)) / std(peak_y));
%         fprintf('Condition: %s\n', condition_labels{c});
%         fprintf('  Jarque-Bera Test (X): p = %.4f (h = %d)\n', p_x_jb, h_x_jb);
%         fprintf('  Jarque-Bera Test (Y): p = %.4f (h = %d)\n', p_y_jb, h_y_jb);
%         fprintf('  Kolmogorov-Smirnov Test (X): p = %.4f (h = %d)\n', p_x_ks, h_x_ks);
%         fprintf('  Kolmogorov-Smirnov Test (Y): p = %.4f (h = %d)\n', p_y_ks, h_y_ks);
%     end
% end

% Result from Normality Tests: Peak velocity data is normally distributed for all segments and conditions.

%% Effect size
% Quantative measure of magnitude of difference between groups
% ( p-value -> tells you if effect exists )
% Effect size -> tells you how large that effect is

% Choice: One-Way Repeated Measures ANOVA (within-subjects design):
% Test: statistically significant differences in peak velocity across the four conditions.
% Why ANOVA:
%       - Data is normally distributed.
%       - Multiple measurements from the same subjects under different conditions.
%       - The dependent variable (peak velocity) is continuous.
%       - The independent variable (condition) has more than two levels.
% Repeated measures ANOVA accounts for within-subject variability, increasing statistical power.

% Why NOT a t-test? A t-test is only suitable for comparing two groups at a time.
% Why NOT Cohen's d (difference between standard deviation): I have four conditions and not just two

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform Repeated Measures ANOVA on Peak Velocity Data

% Gather all peak velocities into a matrix
% Rows: subjects, Columns: conditions, Layers: segments
num_conditions = length(conditions);

% Calculate Mean Peak Velocity per Subject
mean_peak_data = zeros(num_subjects, num_conditions, num_segments);

for seg = 1:num_segments
    for c = 1:num_conditions
        all_trials = peak_velocities.(conditions{c}).x{seg};

        fprintf('Segment %d, Condition %s: Number of trials = %d\n', seg, conditions{c}, length(all_trials));
    end
end

for seg = 1:num_segments
    for c = 1:num_conditions
        all_trials = peak_velocities.(conditions{c}).x{seg};

        % Ensure correct number of trials per subject
        num_trials = length(all_trials) / num_subjects;

        if mod(length(all_trials), num_subjects) ~= 0
            error('Mismatch in the number of trials per subject. Check your data.');
        end

        reshaped_data = reshape(all_trials, [num_subjects, num_trials])';  % Transpose for correct dimensions

        mean_peak_data(:, c, seg) = mean(reshaped_data, 1)';
    end
end

for seg = 1:num_segments
    fprintf('=== Repeated Measures ANOVA for Segment: %s → %s ===\n', key_labels{seg}, key_labels{seg+1});

    % Extract data for current segment
    segment_data = squeeze(mean_peak_data(:, :, seg));

    % Create factor table for conditions
    condition_factor = table(repmat((1:num_conditions), num_subjects, 1), 'VariableNames', {'Condition'});
    subject_factor = table((1:num_subjects)', 'VariableNames', {'Subject'});

    % Convert data to table
    data_tbl = array2table(segment_data, 'VariableNames', conditions);
    data_tbl.Subject = subject_factor.Subject;

    % Reshape data for ANOVA
    data_long = stack(data_tbl, conditions, 'NewDataVariableName', 'PeakVelocity', 'IndexVariableName', 'Condition');

    % Run Repeated Measures ANOVA
    rm = fitrm(data_long, 'PeakVelocity ~ Condition + Subject', 'WithinDesign', condition_factor);
    ranovatbl = ranova(rm);

    % Display results
    disp(ranovatbl);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Partial η^2



%% Power Analysis (Approximate Required Sample Size)
% Determins the sample size required for an experiment
