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
colors = {'b', 'r'};

% Define Start and TP Positions
key_points = [-0.00051, 0.120593; -0.12048, 0.018975; -0.0798, 0.1511; ...
    0.0493, -0.0192; 0.1, 0.06; -0.0951, -0.0404; 0.131264, 0.140562];
key_labels = {'Start', 'TP1', 'TP2', 'TP3', 'TP4', 'TP5', 'TP6'};
radius_threshold = 0.004; % 4 mm radius

%% Segment and Plot Individual Trajectories
% Figure 1: Trials 3,5,7
plot_segmented_trajectories([3, 5, 7], [1, 2, 3, 4, 5, 6, 7], subjectData_all, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, 'Segmented Trajectories (Trials 3, 5, 7)');

% Figure 2: Trials 2,4,6
plot_segmented_trajectories([2, 4, 6], [1, 7, 6, 5, 4, 3, 2], subjectData_all, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, 'Segmented Trajectories (Trials 2, 4, 6)');

