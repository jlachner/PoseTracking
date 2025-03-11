%% Clean-up
clear; close all; clc;

%% Load subject data (update the filename accordingly)
load('Matlab_data/s2.mat'); % Change 's1' to your actual subject file

% Ensure subjectData exists
if ~exist('subjectData', 'var')
    error('Variable subjectData not found. Ensure the correct file is loaded.');
end

%% Define conditions and labels
conditions = {'st', 'noC', 'wr', 'c'};
condition_labels = {'Standing', 'Sitting without constraints', 'Only wrist constrained', 'Wrist, shoulder, and elbow constrained'};

arms = {'l', 'r'}; % Left, Right
colors = {'b', 'r'}; % Blue for left, Red for right

% Define Start and TP Positions
key_points = [-0.00051, 0.120593; -0.12048, 0.018975; -0.0798, 0.1511; ...
              0.0493, -0.0192; 0.1, 0.06; -0.0951, -0.0404; 0.131264, 0.140562];
key_labels = {'Start', 'TP1', 'TP2', 'TP3', 'TP4', 'TP5', 'TP6'};
radius_threshold = 0.004; % 4 mm radius

%% Plot stuff

% Determine Global Axis Limits
[x_min, x_max, y_min, y_max] = get_global_axis_limits(subjectData, key_points, conditions, arms);

% Calculate Mean Trajectories
segment_means = calculate_segment_means([3, 5, 7], [1, 2, 3, 4, 5, 6, 7], subjectData, key_points, conditions, arms, radius_threshold);
plot_mean_trajectory(segment_means, 'Trials 3, 5, 7 - Mean Trajectory', key_points, key_labels, conditions, condition_labels, arms, colors, x_min, x_max, y_min, y_max);
plot_max_velocity(segment_means, 'Trials 3, 5, 7 - Max Velocity', conditions, condition_labels, arms, colors);


segment_means = calculate_segment_means([2, 4, 6], [1, 7, 6, 5, 4, 3, 2], subjectData, key_points, conditions, arms, radius_threshold);
plot_mean_trajectory(segment_means, 'Trials 2, 4, 6 - Mean Trajectory', key_points, key_labels, conditions, condition_labels, arms, colors, x_min, x_max, y_min, y_max);
plot_max_velocity(segment_means, 'Trials 2, 4, 6 - Max Velocity', conditions, condition_labels, arms, colors);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- FUNCTION DEFINITIONS -------------------------

% Function to calculate segment means
function segment_means = calculate_segment_means(trials, movement_order, subjectData, key_points, conditions, arms, radius_threshold)
    segment_means = struct();
    
    for c = 1:length(conditions)
        condition = conditions{c};
        for a = 1:length(arms)
            arm = arms{a};
            num_segments = length(movement_order) - 1;
            segment_means.(condition).(arm).X = cell(num_segments, 1);
            segment_means.(condition).(arm).Y = cell(num_segments, 1);
            segment_means.(condition).(arm).MaxVel = nan(num_segments, 1); % Store max velocity per segment

            for seg = 1:num_segments
                all_segmentX = [];
                all_segmentY = [];
                all_max_vel = [];

                for trial = trials
                    if isfield(subjectData, condition) && isfield(subjectData.(condition), arm) ...
                            && length(subjectData.(condition).(arm)) >= trial
                        
                        data = subjectData.(condition).(arm){trial};
                        if isfield(data, 'posX_m') && isfield(data, 'posY_m') && isfield(data, 'velX_mps') && isfield(data, 'velY_mps')
                            posX = data.posX_m;
                            posY = data.posY_m;
                            velX = data.velX_mps;
                            velY = data.velY_mps;
                            
                            % Compute Euclidean velocity
                            euclidean_velocity = sqrt(velX.^2 + velY.^2);
                            
                            % Find last position within the start radius before movement begins
                            distances_start = sqrt((posX - key_points(1,1)).^2 + (posY - key_points(1,2)).^2);
                            valid_start_idx = find(distances_start <= radius_threshold, 1, 'last');
                            if ~isempty(valid_start_idx)
                                posX = posX(valid_start_idx:end);
                                posY = posY(valid_start_idx:end);
                                euclidean_velocity = euclidean_velocity(valid_start_idx:end);
                            end

                            % Get start and end points for the segment
                            start_idx = movement_order(seg);
                            end_idx = movement_order(seg+1);

                            dist_from_start = sqrt((posX - key_points(start_idx,1)).^2 + (posY - key_points(start_idx,2)).^2);
                            last_idx_start = find(dist_from_start <= radius_threshold, 1, 'last');
                            
                            dist_from_end = sqrt((posX - key_points(end_idx,1)).^2 + (posY - key_points(end_idx,2)).^2);
                            first_idx_end = find(dist_from_end <= radius_threshold, 1, 'first');

                            if ~isempty(last_idx_start) && ~isempty(first_idx_end) && last_idx_start < first_idx_end
                                segmentX = posX(last_idx_start:first_idx_end);
                                segmentY = posY(last_idx_start:first_idx_end);
                                maxVel = max(euclidean_velocity(last_idx_start:first_idx_end));

                                all_segmentX = [all_segmentX; interp1(1:length(segmentX), segmentX, linspace(1, length(segmentX), 100))];
                                all_segmentY = [all_segmentY; interp1(1:length(segmentY), segmentY, linspace(1, length(segmentY), 100))];
                                all_max_vel = [all_max_vel; maxVel];
                            end
                        end
                    end
                end

                % Store averaged results across trials
                if ~isempty(all_segmentX)
                    segment_means.(condition).(arm).X{seg} = mean(all_segmentX, 1);
                    segment_means.(condition).(arm).Y{seg} = mean(all_segmentY, 1);
                    segment_means.(condition).(arm).MaxVel(seg) = mean(all_max_vel);
                end
            end
        end
    end
end



% Function to plot mean trajectories
function plot_mean_trajectory(segment_means, fig_title, key_points, key_labels, conditions, condition_labels, arms, colors, x_min, x_max, y_min, y_max)
    figure;
    tiledlayout(2,2);
    sgtitle(fig_title, 'FontSize', 14, 'FontWeight', 'bold');
    
    for c = 1:length(conditions)
        condition = conditions{c};
        nexttile;
        hold on;
        title(condition_labels{c}, 'FontSize', 12, 'FontWeight', 'bold');
        xlabel('X [m]', 'FontSize', 10);
        ylabel('Y [m]', 'FontSize', 10);
        xlim([x_min, x_max]);
        ylim([y_min, y_max]);
        legend_entries = {};
        
        for a = 1:length(arms)
            arm = arms{a};
            isFirstPlot = true; % Ensure only one legend entry per arm
            for seg = 1:length(segment_means.(condition).(arm).X)
                if ~isempty(segment_means.(condition).(arm).X{seg})
                    meanX = mean(segment_means.(condition).(arm).X{seg}, 1);
                    meanY = mean(segment_means.(condition).(arm).Y{seg}, 1);
                    
                    if isFirstPlot
                        plot(meanX, meanY, 'Color', colors{a}, 'LineWidth', 2.5, 'DisplayName', [upper(arm) ' Arm']);
                        legend_entries{end+1} = [upper(arm) ' Arm'];
                        isFirstPlot = false;
                    else
                        plot(meanX, meanY, 'Color', colors{a}, 'LineWidth', 2.5, 'HandleVisibility', 'off');
                    end
                end
            end
        end
        
        % Plot key points after the trajectories
        for k = 1:size(key_points, 1)
            plot(key_points(k,1), key_points(k,2), 'ko', 'MarkerSize', 8, 'LineWidth', 2, 'MarkerFaceColor', 'k');
            text(key_points(k,1) + 0.005, key_points(k,2) + 0.005, key_labels{k}, 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
        end
        
        legend(legend_entries);
        hold off;
    end
end


% Function to plot max velocity across movement order
function plot_max_velocity(segment_means, fig_title, conditions, condition_labels, arms, colors)
    figure;
    tiledlayout(2,2);
    sgtitle(fig_title, 'FontSize', 14, 'FontWeight', 'bold');
    
    for c = 1:length(conditions)
        condition = conditions{c};
        nexttile;
        hold on;
        title(condition_labels{c}, 'FontSize', 12, 'FontWeight', 'bold');
        xlabel('Movement Order', 'FontSize', 10);
        ylabel('Max Velocity (m/s)', 'FontSize', 10);
        
        for a = 1:length(arms)
            arm = arms{a};
            vMax = segment_means.(condition).(arm).MaxVel;
            
            if ~isnan(vMax)
                plot(1:length(vMax), vMax, '-o', 'Color', colors{a}, 'LineWidth', 2.5, 'MarkerSize', 6, 'DisplayName', [upper(arm) ' Arm']);
            end
        end
        
        legend;
        hold off;
    end
end


% Calculate the global axis limits
function [x_min, x_max, y_min, y_max] = get_global_axis_limits(subjectData, key_points, conditions, arms)
    all_x = []; all_y = [];

    for c = 1:length(conditions)
        for a = 1:length(arms)
            for trial = 1:7  % Assuming max 7 trials
                if isfield(subjectData, conditions{c}) && isfield(subjectData.(conditions{c}), arms{a}) ...
                        && length(subjectData.(conditions{c}).(arms{a})) >= trial
                    data = subjectData.(conditions{c}).(arms{a}){trial};
                    if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                        all_x = [all_x; data.posX_m(:)];
                        all_y = [all_y; data.posY_m(:)];
                    end
                end
            end
        end
    end

    % Include key points to ensure they fit inside the plot
    all_x = [all_x; key_points(:,1)];
    all_y = [all_y; key_points(:,2)];

    % Compute limits
    x_min = min(all_x); x_max = max(all_x);
    y_min = min(all_y); y_max = max(all_y);
end
