%% Clean-up
clear; close all; clc;

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

%% Compute Global Axis Limits
[x_min, x_max, y_min, y_max] = compute_global_axis_limits(subjectData_all, key_points, conditions, arms);

%% Segment and Plot Individual Trajectories
% Figure 1: Trials 3,5,7
plot_segmented_trajectories([3, 5, 7], [1, 2, 3, 4, 5, 6, 7], subjectData_all, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max, 'Segmented Trajectories (Trials 3, 5, 7)');

% Figure 2: Trials 2,4,6
plot_segmented_trajectories([2, 4, 6], [1, 7, 6, 5, 4, 3, 2], subjectData_all, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max, 'Segmented Trajectories (Trials 2, 4, 6)');

%% Function Definitions

% Compute global axis limits across subjects
function [x_min, x_max, y_min, y_max] = compute_global_axis_limits(subjectData_all, key_points, conditions, arms)
all_x = []; all_y = [];
for s = 1:length(subjectData_all)
    for c = 1:length(conditions)
        for a = 1:length(arms)
            for trial = 1:7
                if isfield(subjectData_all{s}, conditions{c}) && isfield(subjectData_all{s}.(conditions{c}), arms{a}) ...
                        && length(subjectData_all{s}.(conditions{c}).(arms{a})) >= trial
                    data = subjectData_all{s}.(conditions{c}).(arms{a}){trial};
                    if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                        all_x = [all_x; data.posX_m(:)];
                        all_y = [all_y; data.posY_m(:)];
                    end
                end
            end
        end
    end
end
all_x = [all_x; key_points(:,1)];
all_y = [all_y; key_points(:,2)];
x_min = min(all_x); x_max = max(all_x);
y_min = min(all_y); y_max = max(all_y);
end

% Segment and plot all individual subject trajectories
function plot_segmented_trajectories(trials, movement_order, subjectData_all, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max, fig_title)
figure;
tiledlayout(2,2);
sgtitle(fig_title, 'FontSize', 14, 'FontWeight', 'bold');

for c = 1:length(conditions)
    condition = conditions{c};
    nexttile;
    hold on;
    title(condition_labels{c}, 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('X [m]'); ylabel('Y [m]');
    xlim([x_min, x_max]); ylim([y_min, y_max]);

    legend_entries = {};
    legend_labels = {};

    for a = 1:length(arms)
        arm = arms{a};

        for s = 1:length(subjectData_all)
            subjectData = subjectData_all{s}; % Get current subject's data

            for trial = trials
                if isfield(subjectData, condition) && isfield(subjectData.(condition), arm) ...
                        && length(subjectData.(condition).(arm)) >= trial

                    data = subjectData.(condition).(arm){trial};

                    if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                        posX = data.posX_m;
                        posY = data.posY_m;

                        % Trim positions before movement initiation
                        distances_start = sqrt((posX - key_points(1,1)).^2 + (posY - key_points(1,2)).^2);
                        valid_start_idx = find(distances_start <= radius_threshold, 1, 'last');
                        if ~isempty(valid_start_idx)
                            posX = posX(valid_start_idx:end);
                            posY = posY(valid_start_idx:end);
                        end

                        % Segment movement
                        for seg = 1:length(movement_order)-1
                            start_idx = movement_order(seg);
                            end_idx = movement_order(seg+1);

                            % Identify segment start and end points
                            dist_from_start = sqrt((posX - key_points(start_idx,1)).^2 + (posY - key_points(start_idx,2)).^2);
                            last_idx_start = find(dist_from_start <= radius_threshold, 1, 'last');

                            dist_from_end = sqrt((posX - key_points(end_idx,1)).^2 + (posY - key_points(end_idx,2)).^2);
                            first_idx_end = find(dist_from_end <= radius_threshold, 1, 'first');

                            if ~isempty(last_idx_start) && ~isempty(first_idx_end) && last_idx_start < first_idx_end
                                segmentX = posX(last_idx_start:first_idx_end);
                                segmentY = posY(last_idx_start:first_idx_end);

                                % Plot trajectory for the segment
                                plot(segmentX, segmentY, 'Color', colors{a}, 'LineWidth', 1.5);
                            end
                        end
                    end
                end
            end
        end

        % Legend entries (only once per arm)
        if isempty(legend_entries) || ~any(strcmp(legend_labels, [upper(arm) ' Arm']))
            h = plot(NaN, NaN, 'Color', colors{a}, 'LineWidth', 1.5); % Dummy plot for legend
            legend_entries{end+1} = h;
            legend_labels{end+1} = [upper(arm) ' Arm'];
        end
    end
    
    % Plot Key Points
    for k = 1:size(key_points, 1)
        plot(key_points(k,1), key_points(k,2), 'ko', 'MarkerSize', 6, 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
        text(key_points(k,1) + 0.005, key_points(k,2) + 0.005, key_labels{k}, 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'k');
    end

    legend([legend_entries{:}], legend_labels{:}, 'Location', 'Best');
    hold off;
end
end