%% Clean-up
clear; close all; clc;

%% Load subject data (update the filename accordingly)
subject = 's1';
load( [ 'Matlab_data/', subject ,'.mat'] ); % Change 's1' to your actual subject file

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

%% Segment means
%[segment_means_X, segment_means_Y] = calculate_segment_means([3,5,7], [1,2,3,4,5,6,7], subjectData, 'st', 'l', key_points, radius_threshold);


%% Segment-wise variability
%plot_segment_variability(segment_means_X, segment_means_Y, [1,2,3,4,5,6,7]);


%% Plot stuff

% Determine Global Axis Limits
[x_min, x_max, y_min, y_max] = get_global_axis_limits(subjectData, key_points, conditions, arms);

% Plot mean and include 10-90% percentile shading
orderSwitched = false;
if orderSwitched

    % Plot Figure 1: Trials 2,4,6 (Original Order)
    plot_mean_trajectory([3, 5, 7], [1, 7, 6, 5, 4, 3, 2], [ 'Subject ', subject, '; Trials 3, 5, 7 - Mean Trajectory' ], ...
        subjectData, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max);

    % Plot Figure 1: Trials 3,5,7 (Reversed Order)
    plot_mean_trajectory([2, 4, 6], [1, 2, 3, 4, 5, 6, 7], [ 'Subject ', subject, '; Trials 2, 4, 6 - Mean Trajectory' ], ...
        subjectData, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max);

else

    % Plot Figure 1: Trials 3,5,7 (Original Order)
    plot_mean_trajectory([3, 5, 7], [1, 2, 3, 4, 5, 6, 7], [ 'Subject ', subject, '; Trials 3, 5, 7 - Mean Trajectory' ], ...
        subjectData, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max);

    % Plot Figure 2: Trials 2,4,6 (Reversed Order)
    plot_mean_trajectory([2, 4, 6], [1, 7, 6, 5, 4, 3, 2], [ 'Subject ', subject, '; Trials 2, 4, 6 - Mean Trajectory' ], ...
        subjectData, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max);

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ------------------------- FUNCTION DEFINITIONS -------------------------


% Calculate segment means
function [segment_means_X, segment_means_Y] = calculate_segment_means(trials, movement_order, subjectData, condition, arm, key_points, radius_threshold)
num_segments = length(movement_order) - 1;
segment_means_X = cell(num_segments, 1);
segment_means_Y = cell(num_segments, 1);

for trial = trials
    if isfield(subjectData, condition) && isfield(subjectData.(condition), arm) ...
            && length(subjectData.(condition).(arm)) >= trial
        data = subjectData.(condition).(arm){trial};

        if isfield(data, 'posX_m') && isfield(data, 'posY_m')
            % Get position data
            posX = data.posX_m;
            posY = data.posY_m;

            % Remove data before movement starts
            distances_start = sqrt((posX - key_points(1,1)).^2 + (posY - key_points(1,2)).^2);
            valid_start_idx = find(distances_start <= radius_threshold, 1, 'last');
            if ~isempty(valid_start_idx)
                posX = posX(valid_start_idx:end);
                posY = posY(valid_start_idx:end);
            end

            % Process each segment
            for seg = 1:num_segments
                start_idx = movement_order(seg);
                end_idx = movement_order(seg+1);

                % Find segment start and end points
                dist_from_start = sqrt((posX - key_points(start_idx,1)).^2 + (posY - key_points(start_idx,2)).^2);
                last_idx_start = find(dist_from_start <= radius_threshold, 1, 'last');

                dist_from_end = sqrt((posX - key_points(end_idx,1)).^2 + (posY - key_points(end_idx,2)).^2);
                first_idx_end = find(dist_from_end <= radius_threshold, 1, 'first');

                if ~isempty(last_idx_start) && ~isempty(first_idx_end) && last_idx_start < first_idx_end
                    segmentX = posX(last_idx_start:first_idx_end);
                    segmentY = posY(last_idx_start:first_idx_end);

                    % Store interpolated segment data
                    segment_means_X{seg} = [segment_means_X{seg}; interp1(1:length(segmentX), segmentX, linspace(1, length(segmentX), 100))];
                    segment_means_Y{seg} = [segment_means_Y{seg}; interp1(1:length(segmentY), segmentY, linspace(1, length(segmentY), 100))];
                end
            end
        end
    end
end
end




% Plot segment-wise variability
function plot_segment_variability(segment_means_X, segment_means_Y, movement_order)
num_segments = length(movement_order) - 1;
segment_std_x = zeros(num_segments, 1);
segment_std_y = zeros(num_segments, 1);

for seg = 1:num_segments
    if ~isempty(segment_means_X{seg}) && ~isempty(segment_means_Y{seg})
        segment_std_x(seg) = mean(std(segment_means_X{seg}, 0, 1));
        segment_std_y(seg) = mean(std(segment_means_Y{seg}, 0, 1));
    end
end

% Generate segment labels correctly
segment_labels = arrayfun(@(s, e) sprintf('TP%d → TP%d', s, e), movement_order(1:end-1), movement_order(2:end), 'UniformOutput', false);

% Plot standard deviation for each segment
figure;
bar(1:num_segments, [segment_std_x, segment_std_y]);
xticks(1:num_segments);
xticklabels(segment_labels);
xlabel('Movement Segment');
ylabel('Standard Deviation (m)');
legend({'X Variability', 'Y Variability'});
title('Segment-Wise Variability');
grid on;
end




% Plot mean trajectory
function plot_mean_trajectory(trials, movement_order, fig_title, subjectData, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, x_min, x_max, y_min, y_max)
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
    xlim([x_min, x_max]);  % **Ensure shading stays within bounds**
    ylim([y_min, y_max]);

    legend_entries = {}; % Store legend entries

    for a = 1:length(arms)
        arm = arms{a};
        segment_means_X = cell(length(movement_order)-1, 1);
        segment_means_Y = cell(length(movement_order)-1, 1);

        % Collect segment trajectories across trials
        for trial = trials
            if isfield(subjectData, condition) && isfield(subjectData.(condition), arm) ...
                    && length(subjectData.(condition).(arm)) >= trial

                data = subjectData.(condition).(arm){trial};

                if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                    posX = data.posX_m;
                    posY = data.posY_m;

                    % Trim start positions
                    distances_start = sqrt((posX - key_points(1,1)).^2 + (posY - key_points(1,2)).^2);
                    valid_start_idx = find(distances_start <= radius_threshold, 1, 'last');
                    if ~isempty(valid_start_idx)
                        posX = posX(valid_start_idx:end);
                        posY = posY(valid_start_idx:end);
                    end

                    % Segment movements
                    for seg = 1:length(movement_order)-1
                        start_idx = movement_order(seg);
                        end_idx = movement_order(seg+1);

                        dist_from_start = sqrt((posX - key_points(start_idx,1)).^2 + (posY - key_points(start_idx,2)).^2);
                        last_idx_start = find(dist_from_start <= radius_threshold, 1, 'last');

                        dist_from_end = sqrt((posX - key_points(end_idx,1)).^2 + (posY - key_points(end_idx,2)).^2);
                        first_idx_end = find(dist_from_end <= radius_threshold, 1, 'first');

                        if ~isempty(last_idx_start) && ~isempty(first_idx_end) && last_idx_start < first_idx_end
                            segmentX = posX(last_idx_start:first_idx_end);
                            segmentY = posY(last_idx_start:first_idx_end);

                            % Store segment data
                            segment_means_X{seg} = [segment_means_X{seg}; interp1(1:length(segmentX), segmentX, linspace(1, length(segmentX), 100))];
                            segment_means_Y{seg} = [segment_means_Y{seg}; interp1(1:length(segmentY), segmentY, linspace(1, length(segmentY), 100))];
                        end
                    end
                end
            end
        end

        % Compute and plot percentile-based shading
        for seg = 1:length(segment_means_X)
            if ~isempty(segment_means_X{seg}) && ~isempty(segment_means_Y{seg})
                % Compute percentile range (10th to 90th percentile)
                p10_x = prctile(segment_means_X{seg}, 10, 1);
                p90_x = prctile(segment_means_X{seg}, 90, 1);
                meanX = mean(segment_means_X{seg}, 1);

                p10_y = prctile(segment_means_Y{seg}, 10, 1);
                p90_y = prctile(segment_means_Y{seg}, 90, 1);
                meanY = mean(segment_means_Y{seg}, 1);

                % Ensure there is visible variability in shading (at least 0.5mm difference)
                visible_variability = any((p90_x - p10_x) > 0.0005) || any((p90_y - p10_y) > 0.0005);

                if visible_variability
                    % **Shaded area for X-direction (10-90%)**
                    fill_area_X = fill([meanX, fliplr(meanX)], [p10_y, fliplr(p90_y)], ...
                        colors{a}, 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off');

                    % **Shaded area for Y-direction (10-90%)**
                    fill_area_Y = fill([p10_x, fliplr(p90_x)], [meanY, fliplr(meanY)], ...
                        colors{a}, 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off');

                    % **Ensure shaded areas are behind the mean lines**
                    uistack(fill_area_X, 'bottom');
                    uistack(fill_area_Y, 'bottom');

                    % **Store shaded area in the legend only once per arm**
                    if seg == 1
                        legend_entries = [legend_entries, plot(NaN, NaN, 'Color', colors{a}, 'LineWidth', 2.5, 'DisplayName', [upper(arm) ' Arm (10-90%)'])];
                    end
                end

                % **Plot mean trajectory on top**
                mean_line = plot(meanX, meanY, 'Color', colors{a}, 'LineWidth', 2.5, 'DisplayName', [upper(arm) ' Arm (Mean)']);

                % Store mean trajectory legend entry only once per arm
                if seg == 1
                    legend_entries = [legend_entries, mean_line];
                end
            end
        end


    end

    % **Plot Key Points**
    for k = 1:size(key_points, 1)
        plot(key_points(k,1), key_points(k,2), 'ko', 'MarkerSize', 12, 'LineWidth', 3, 'MarkerFaceColor', 'k', 'HandleVisibility', 'off');
        text(key_points(k,1) + 0.01, key_points(k,2) + 0.015, key_labels{k}, 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
    end

    % **Add Correct Legend**
    legend(legend_entries, 'Location', 'Best');
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