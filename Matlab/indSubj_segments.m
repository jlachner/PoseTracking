% Clean-up
clear; close all; clc;

% Load subject data (update the filename accordingly)
load('Matlab_data/s4.mat'); % Change 's1' to your actual subject file

% Ensure subjectData exists
if ~exist('subjectData', 'var')
    error('Variable subjectData not found. Ensure the correct file is loaded.');
end

% Define conditions and labels
conditions = {'st', 'noC', 'wr', 'c'};
condition_labels = {'Standing', 'Sitting without constraints', 'Only wrist constrained', 'Wrist, shoulder, and elbow constrained'};

arms = {'l', 'r'}; % Left, Right
colors = {'b', 'r'}; % Blue for left, Red for right

% Define Start and TP Positions
key_points = [-0.00051, 0.120593; -0.12048, 0.018975; -0.0798, 0.1511; ...
    0.0493, -0.0192; 0.1, 0.06; -0.0951, -0.0404; 0.131264, 0.140562];
key_labels = {'Start', 'TP1', 'TP2', 'TP3', 'TP4', 'TP5', 'TP6'};
radius_threshold = 0.004; % **Updated to 3mm radius**

% **Compute and Plot Figure 1: Trials 2,4,6 (Reversed Order)**
segments = compute_segments([2, 4, 6], [1, 7, 6, 5, 4, 3, 2], subjectData, key_points, radius_threshold, conditions, arms);
plot_segments(segments, 'Trials 2, 4, 6 - Segmented Movements', key_points, key_labels, conditions, condition_labels, arms, colors);
plot_vmax(segments, 'Trials 2, 4, 6 - Max Velocity Across Segments', [1, 7, 6, 5, 4, 3, 2], conditions, condition_labels, arms, colors);

% **Compute and Plot vMax for Figure 2: Trials 3,5,7 (Original Order)**
segments = compute_segments([3, 5, 7], [1, 2, 3, 4, 5, 6, 7], subjectData, key_points, radius_threshold, conditions, arms);
plot_segments(segments, 'Trials 3, 5, 7 - Segmented Movements', key_points, key_labels, conditions, condition_labels, arms, colors);
plot_vmax(segments, 'Trials 3, 5, 7 - Max Velocity Across Segments', [1, 2, 3, 4, 5, 6, 7], conditions, condition_labels, arms, colors);


% ------------------------- FUNCTION DEFINITIONS -------------------------

function segments = compute_segments(trials, movement_order, subjectData, key_points, radius_threshold, conditions, arms)
% Computes movement segments for given trials and conditions
segments = struct();

for c = 1:length(conditions)
    condition = conditions{c};

    for a = 1:length(arms)
        arm = arms{a};
        segments.(condition).(arm) = {};

        for trial = trials
            if isfield(subjectData, condition) && isfield(subjectData.(condition), arm) ...
                    && length(subjectData.(condition).(arm)) >= trial

                data = subjectData.(condition).(arm){trial};

                if isfield(data, 'posX_m') && isfield(data, 'posY_m') && ...
                        isfield(data, 'velX_mps') && isfield(data, 'velY_mps')

                    posX = data.posX_m;
                    posY = data.posY_m;
                    velX = data.velX_mps;
                    velY = data.velY_mps;

                    % Find last position within the start radius before movement begins
                    distances_start = sqrt((posX - key_points(1,1)).^2 + (posY - key_points(1,2)).^2);
                    valid_start_idx = find(distances_start <= radius_threshold, 1, 'last');
                    if ~isempty(valid_start_idx)
                        posX = posX(valid_start_idx:end);
                        posY = posY(valid_start_idx:end);
                        velX = velX(valid_start_idx:end);
                        velY = velY(valid_start_idx:end);
                    end

                    % Segment movements
                    segment_data = {};
                    for seg = 1:length(movement_order)-1
                        start_idx = movement_order(seg);
                        end_idx = movement_order(seg+1);

                        % Find last position at start of segment
                        dist_from_start = sqrt((posX - key_points(start_idx,1)).^2 + (posY - key_points(start_idx,2)).^2);
                        last_idx_start = find(dist_from_start <= radius_threshold, 1, 'last');

                        % Find first position at end of segment
                        dist_from_end = sqrt((posX - key_points(end_idx,1)).^2 + (posY - key_points(end_idx,2)).^2);
                        first_idx_end = find(dist_from_end <= radius_threshold, 1, 'first');

                        if ~isempty(last_idx_start) && ~isempty(first_idx_end) && last_idx_start < first_idx_end
                            segmentX = posX(last_idx_start:first_idx_end);
                            segmentY = posY(last_idx_start:first_idx_end);
                            segmentVelX = velX(last_idx_start:first_idx_end);
                            segmentVelY = velY(last_idx_start:first_idx_end);

                            % Compute Euclidean norm of max velocity
                            vMax = max(sqrt(segmentVelX.^2 + segmentVelY.^2));

                            segment_data{end+1} = struct(...
                                'X', segmentX, ...
                                'Y', segmentY, ...
                                'dX', max(abs(segmentVelX)), ...
                                'dY', max(abs(segmentVelY)), ...
                                'vMax', vMax ...  % Max Euclidean velocity
                                );
                        end
                    end

                    segments.(condition).(arm){trial} = segment_data;
                end
            end
        end
    end
end
end

function plot_segments(segments, fig_title, key_points, key_labels, conditions, condition_labels, arms, colors)
% Plots the movement segments
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

    legend_entries = {}; % Store legend entries

    for a = 1:length(arms)
        arm = arms{a};
        isFirstPlot = true; % Track first plot for legend

        if isfield(segments, condition) && isfield(segments.(condition), arm)
            trial_data = segments.(condition).(arm);

            for trial_idx = 1:length(trial_data)
                segment_data = trial_data{trial_idx};

                for seg = 1:length(segment_data)
                    segmentX = segment_data{seg}.X;
                    segmentY = segment_data{seg}.Y;

                    if isFirstPlot
                        plot(segmentX, segmentY, 'Color', colors{a}, 'LineWidth', 1.5, 'DisplayName', [upper(arm) ' Arm']);
                        isFirstPlot = false;
                        legend_entries{end+1} = [upper(arm) ' Arm'];
                    else
                        plot(segmentX, segmentY, 'Color', colors{a}, 'LineWidth', 1.5, 'HandleVisibility', 'off');
                    end
                end
            end
        end
    end

    % **Plot Key Points**
    for k = 1:size(key_points, 1)
        plot(key_points(k,1), key_points(k,2), 'ko', 'MarkerSize', 10, 'LineWidth', 3, 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
        text(key_points(k,1) + 0.01, key_points(k,2) + 0.015, key_labels{k}, 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
    end

    legend(legend_entries);
    hold off;
end

end


function plot_vmax(segments, fig_title, movement_order, conditions, condition_labels, arms, colors)
    % Plots max velocity norm (vMax) across movement order for each condition and arm

    figure;
    tiledlayout(2,2);
    sgtitle(fig_title, 'FontSize', 14, 'FontWeight', 'bold');

    num_segments = length(movement_order) - 1;  % Always plot on 1 to 6

    for c = 1:length(conditions)
        condition = conditions{c};
        nexttile;
        hold on;
        title(condition_labels{c}, 'FontSize', 12, 'FontWeight', 'bold');
        xlabel('Segment Number', 'FontSize', 10);
        ylabel('Max Velocity [m/s]', 'FontSize', 10);
        xticks(1:num_segments); % Show only 1,2,3,...,6 on x-axis

        for a = 1:length(arms)
            arm = arms{a};
            vMax_values = nan(num_segments, length(segments.(condition).(arm))); % Store vMax per segment

            if isfield(segments, condition) && isfield(segments.(condition), arm)
                trial_data = segments.(condition).(arm);

                for trial_idx = 1:length(trial_data)
                    segment_data = trial_data{trial_idx};

                    for seg = 1:length(segment_data)
                        vMax_values(seg, trial_idx) = segment_data{seg}.vMax;
                    end
                end
            end

            % Compute mean and std of vMax across trials
            mean_vMax = nanmean(vMax_values, 2);
            std_vMax = nanstd(vMax_values, 0, 2);

            % Plot mean with error bars
            errorbar(1:num_segments, mean_vMax, std_vMax, '-o', 'Color', colors{a}, ...
                     'LineWidth', 1.5, 'MarkerFaceColor', colors{a}, 'DisplayName', [upper(arm) ' Arm']);
        end

        legend;
        hold off;
    end
end