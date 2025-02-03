clear; close all; clc;

% Load subject data (update the filename accordingly)
load('Matlab_data/s1.mat'); % Change 's1' to your actual subject file

% Define conditions in the desired plot order with custom labels
conditions = {'st', 'noC', 'wr', 'c'}; 
condition_labels = {'Standing', 'Sitting without constraints', 'Only wrist constrained', 'Wrist, shoulder, and elbow constrained'};

arms = {'l', 'r'}; % Left, Right
colors = {'b', 'r'}; % Blue for left, Red for right

% Create a figure
figure;
tiledlayout(2,2); % 2x2 grid for 4 conditions

for c = 1:length(conditions)
    condition = conditions{c};

    nexttile;
    hold on;
    title(condition_labels{c}, 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('X [m]', 'FontSize', 10);
    ylabel('Y [m]', 'FontSize', 10);

    for a = 1:length(arms)
        arm = arms{a};

        for trial = 1:7
            if isfield(subjectData.(condition), arm) && length(subjectData.(condition).(arm)) >= trial
                data = subjectData.(condition).(arm){trial};

                if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                    plot(data.posX_m, data.posY_m, 'Color', colors{a}, 'LineWidth', 1.5, 'DisplayName', [upper(arm) '-Trial ' num2str(trial)]);
                end
            end
        end
    end

    legend show;
    hold off;
end

sgtitle('Movement Comparison Across Conditions', 'FontSize', 14, 'FontWeight', 'bold');