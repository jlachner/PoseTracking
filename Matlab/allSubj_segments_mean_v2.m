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
radius_threshold = 0.003; % 4 mm radius

%% Compute Global Axis Limits
[x_min, x_max, y_min, y_max] = compute_global_axis_limits(subjectData_all, key_points, conditions, arms);

%% Compute and Plot Mean Trajectories
% Figure 1: Trials 3,5,7
plot_average_segmented_trajectories([3, 5, 7], [1, 2, 3, 4, 5, 6, 7], subjectData_all, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max, 'Average Segmented Trajectories (Trials 3, 5, 7)');
plot_max_velocity(subjectData_all, [3, 5, 7], [1, 2, 3, 4, 5, 6, 7], key_points, conditions, condition_labels, arms, colors, radius_threshold, 'Max Velocity (Trials 3, 5, 7)');

% Figure 2: Trials 2,4,6
plot_average_segmented_trajectories([2, 4, 6], [1, 7, 6, 5, 4, 3, 2], subjectData_all, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max, 'Average Segmented Trajectories (Trials 2, 4, 6)');
plot_max_velocity(subjectData_all, [2, 4, 6], [1, 7, 6, 5, 4, 3, 2], key_points, conditions, condition_labels, arms, colors, radius_threshold, 'Max Velocity (Trials 2, 4, 6)');

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

% Compute and plot average segmented trajectories
function plot_average_segmented_trajectories(trials, movement_order, subjectData_all, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max, fig_title)
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

    for a = 1:length(arms)
        arm = arms{a};
        [mean_X, mean_Y] = calculate_segment_means(trials, movement_order, subjectData_all, condition, arm, key_points, radius_threshold);

        if ~isempty(mean_X) && ~isempty(mean_Y)
            plot(cell2mat(mean_X')', cell2mat(mean_Y')', 'Color', colors{a}, 'LineWidth', 2.5, 'DisplayName', [upper(arm) ' Arm']);
        end
    end

    % Plot Key Points (Now Hidden from Legend)
    for k = 1:size(key_points, 1)
        plot(key_points(k,1), key_points(k,2), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5, 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
        text(key_points(k,1) + 0.005, key_points(k,2) + 0.005, key_labels{k}, 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'k', 'HandleVisibility', 'off');
    end

    legend('show');
    hold off;
end
end

% Compute segment means across subjects
function [mean_X, mean_Y] = calculate_segment_means(trials, movement_order, subjectData_all, condition, arm, key_points, radius_threshold)
num_segments = length(movement_order) - 1;
all_segments_X = cell(num_segments, 1);
all_segments_Y = cell(num_segments, 1);

for s = 1:length(subjectData_all)
    subjectData = subjectData_all{s};

    for trial = trials
        if isfield(subjectData, condition) && isfield(subjectData.(condition), arm) && length(subjectData.(condition).(arm)) >= trial
            data = subjectData.(condition).(arm){trial};
            if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                posX = data.posX_m; posY = data.posY_m;
                
                for seg = 1:num_segments
                    start_idx = movement_order(seg);
                    end_idx = movement_order(seg+1);
                    start_dist = sqrt((posX - key_points(start_idx,1)).^2 + (posY - key_points(start_idx,2)).^2);
                    end_dist = sqrt((posX - key_points(end_idx,1)).^2 + (posY - key_points(end_idx,2)).^2);
                    idx_start = find(start_dist <= radius_threshold, 1, 'last');
                    idx_end = find(end_dist <= radius_threshold, 1, 'first');

                    if ~isempty(idx_start) && ~isempty(idx_end) && idx_start < idx_end
                        segment_X = posX(idx_start:idx_end);
                        segment_Y = posY(idx_start:idx_end);
                        all_segments_X{seg} = [all_segments_X{seg}; interp1(1:length(segment_X), segment_X, linspace(1, length(segment_X), 100))];
                        all_segments_Y{seg} = [all_segments_Y{seg}; interp1(1:length(segment_Y), segment_Y, linspace(1, length(segment_Y), 100))];
                    end
                end
            end
        end
    end
end

mean_X = cellfun(@(x) mean(x,1,'omitnan'), all_segments_X, 'UniformOutput', false);
mean_Y = cellfun(@(y) mean(y,1,'omitnan'), all_segments_Y, 'UniformOutput', false);
end


% Function to plot max velocity across movement order
function plot_max_velocity(subjectData_all, trials, movement_order, key_points, conditions, condition_labels, arms, colors, radius_threshold, fig_title)
    figure;
    tiledlayout(2,2);
    sgtitle(fig_title, 'FontSize', 14, 'FontWeight', 'bold');
    
    for c = 1:length(conditions)
        condition = conditions{c};
        nexttile;
        hold on;
        title(condition_labels{c}, 'FontSize', 12, 'FontWeight', 'bold');
        xlabel('Segment Number', 'FontSize', 10);
        ylabel('Max Velocity (m/s)', 'FontSize', 10);
        xticks(1:6);
        
        for a = 1:length(arms)
            arm = arms{a};
            num_segments = length(movement_order) - 1;
            all_max_vel = nan(num_segments, length(subjectData_all));
            
            for s = 1:length(subjectData_all)
                subjectData = subjectData_all{s};
                max_vel = compute_max_velocity(trials, movement_order, subjectData, condition, arm, key_points, radius_threshold);
                all_max_vel(:,s) = max_vel;
            end
            
            mean_max_vel = mean(all_max_vel, 2, 'omitnan');
            if any(~isnan(mean_max_vel))
                plot(1:num_segments, mean_max_vel, '-o', 'Color', colors{a}, 'LineWidth', 2.5, 'MarkerSize', 6, 'DisplayName', [upper(arm) ' Arm']);
            end
        end
        
        legend;
        hold off;
    end
end

% Function to compute max velocity per segment for a given subject
function max_vel = compute_max_velocity(trials, movement_order, subjectData, condition, arm, key_points, radius_threshold)
    num_segments = length(movement_order) - 1;
    max_vel = nan(num_segments, 1);
    
    for trial = trials
        if isfield(subjectData, condition) && isfield(subjectData.(condition), arm) && length(subjectData.(condition).(arm)) >= trial
            data = subjectData.(condition).(arm){trial};
            if isfield(data, 'velX_mps') && isfield(data, 'velY_mps')
                velX = data.velX_mps;
                velY = data.velY_mps;
                euclidean_velocity = sqrt(velX.^2 + velY.^2);
                
                for seg = 1:num_segments
                    start_idx = movement_order(seg);
                    end_idx = movement_order(seg+1);
                    
                    start_dist = sqrt((data.posX_m - key_points(start_idx,1)).^2 + (data.posY_m - key_points(start_idx,2)).^2);
                    end_dist = sqrt((data.posX_m - key_points(end_idx,1)).^2 + (data.posY_m - key_points(end_idx,2)).^2);
                    idx_start = find(start_dist <= radius_threshold, 1, 'last');
                    idx_end = find(end_dist <= radius_threshold, 1, 'first');
                    
                    if ~isempty(idx_start) && ~isempty(idx_end) && idx_start < idx_end
                        max_vel(seg) = max(euclidean_velocity(idx_start:idx_end));
                    end
                end
            end
        end
    end
end
