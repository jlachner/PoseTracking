%% Clean-up
clear; close all; clc;

%% Include subfolders
addpath('functions')

%% Summary of experiment:
% Objective: Track arm movements of subjects under different conditions.
% Conditions:
%           1.	Standing
%           2.	Sitting without constraint
%           3.	Wrist constrained
%           4.	Wrist, shoulder, and elbow constrained
% Left arm and right arm for each condition
% Two movement direction for each arm and condition
            % (Start → TP1, TP1 → TP2, …, TP5 → TP6)
            % (Start → TP6, TP6 → TP5, …, TP2 → TP1)
% Number of trials for each direction: 3 trials after ignoring the first trial.
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
colors = {'b', 'r'};

% Define Start and TP Positions
key_points = [-0.00051, 0.120593; -0.12048, 0.018975; -0.0798, 0.1511; ...
    0.0493, -0.0192; 0.1, 0.06; -0.0951, -0.0404; 0.131264, 0.140562];
key_labels = {'Start', 'TP1', 'TP2', 'TP3', 'TP4', 'TP5', 'TP6'};
radius_threshold = 0.004; % 4 mm radius

%% Extract segments

%%%% (1) HERE!!!!!! TODO: for function "compute_segments" add fields to segments -> segment.Vx = ... %%%%%%%%%%%


%%%% (2) For given movement direction and condition, calculate f over v
%%%% across subjects for each segment (two colors for each arm)
%%%% -> 2 figures, 4 subplots, legend with "L Arm" and "R Arm", 
%%%% x-axis: v [m/s], y-axis: f

%% Calculate peak velocity per segment
dir_1 = [3, 5, 7];
dir_2 = [2, 4, 6];
mov_order_1 = [1, 2, 3, 4, 5, 6, 7];
mov_order_2 = [1, 7, 6, 5, 4, 3, 2];

% Struct: trial_order -> arm -> vMax / segment (array of 6 doubles)
peak_velocity_struct_1 = compute_peak_velocities(dir_1, mov_order_1, subjectData_all, key_points, conditions, arms, radius_threshold);
peak_velocity_struct_2 = compute_peak_velocities(dir_2, mov_order_2, subjectData_all, key_points, conditions, arms, radius_threshold);













%% Normality Tests: Jarque-Bera & Kolmogorov-Smirnov
% Jarque-Bera test: Checks skewness and kurtosis.
% Kolmogorov-Smirnov test: Compares the empirical distribution to a normal distribution.
% Null hypothesis: data is normal
% h = 0 (p-value > 0.05): Data is normal (fail to reject H0) -> parametric tests (e.g., t-tests, ANOVA)
% h = 1 (p-value <= 0.05): Data is not normal (reject H0) -> non-parametric tests (e.g., Mann-Whitney U test, Kruskal-Wallis test)











%% Functions

function peak_velocity_struct = compute_peak_velocities(trials, movement_order, subjectData_all, key_points, conditions, arms, radius_threshold)
peak_velocity_struct = struct();

for c = 1:length(conditions)
    condition = conditions{c};
    for a = 1:length(arms)
        arm = arms{a};

        % Use compute_segments to get segments
        segments = compute_segments(trials, movement_order, subjectData_all, condition, arm, key_points, radius_threshold);

        % Initialize arrays for peak velocities in x and y directions
        peak_x = zeros(1, length(movement_order)-1);
        peak_y = zeros(1, length(movement_order)-1);

        % Compute peak velocities for each segment
        for seg = 1:length(segments)
            if ~isempty(segments{seg})
                data = subjectData_all{1}.(condition).(arm){trials(1)}; % Using the first trial data for velocity
                velX = data.velX_mps;
                velY = data.velY_mps;

                segX = segments{seg}.X;
                segY = segments{seg}.Y;

                idx_start = find(data.posX_m == segX(1) & data.posY_m == segY(1), 1);
                idx_end = find(data.posX_m == segX(end) & data.posY_m == segY(end), 1);

                if ~isempty(idx_start) && ~isempty(idx_end)
                    peak_x(seg) = max(abs(velX(idx_start:idx_end))); % Peak velocity in x
                    peak_y(seg) = max(abs(velY(idx_start:idx_end))); % Peak velocity in y
                end
            end
        end

        % Store results in the struct
        peak_velocity_struct.(sprintf('trials_%s', strjoin(string(trials), '_'))).(arm).peak_x = peak_x;
        peak_velocity_struct.(sprintf('trials_%s', strjoin(string(trials), '_'))).(arm).peak_y = peak_y;
    end
end
end



