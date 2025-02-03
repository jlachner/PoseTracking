clear; close all; clc;

% Define subject list and colors
subjects = {'s1', 's2', 's3', 's4'};
subject_colors = {'b', 'r', 'g', 'm'}; % Blue, Red, Green, Magenta

% Define conditions in desired plot order with custom labels
conditions = {'st', 'noC', 'wr', 'c'}; 
condition_labels = {'Standing', 'Sitting without constraints', 'Only wrist constrained', 'Wrist, shoulder, and elbow constrained'};

arms = {'l', 'r'}; % Left, Right

% Create figure for LEFT ARM
figure;
tiledlayout(2,2); % 2x2 grid for 4 conditions

for c = 1:length(conditions)
    condition = conditions{c};

    nexttile;
    hold on;
    title([condition_labels{c}, ' - Left Arm'], 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('posX_m', 'FontSize', 10);
    ylabel('posY_m', 'FontSize', 10);

    for s = 1:length(subjects)
        subject = subjects{s};
        subject_file = fullfile('Matlab_data', strcat(subject, '.mat'));

        if exist(subject_file, 'file')
            load(subject_file); % Load subject data
            
            arm = 'l'; % Only left arm in this figure
            if isfield(subjectData.(condition), arm)
                % Extract trajectory data
                posX_all = [];
                posY_all = [];
                min_length = inf;

                for trial = 1:7
                    if length(subjectData.(condition).(arm)) >= trial
                        data = subjectData.(condition).(arm){trial};
                        if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                            min_length = min(min_length, length(data.posX_m));
                        end
                    end
                end

                if isinf(min_length), continue; end % Skip if no valid data

                for trial = 1:7
                    if length(subjectData.(condition).(arm)) >= trial
                        data = subjectData.(condition).(arm){trial};
                        if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                            posX_all(trial, :) = interp1(linspace(0,1,length(data.posX_m)), data.posX_m, linspace(0,1,min_length), 'linear');
                            posY_all(trial, :) = interp1(linspace(0,1,length(data.posY_m)), data.posY_m, linspace(0,1,min_length), 'linear');
                        end
                    end
                end

                % Compute mean trajectory
                meanX = mean(posX_all, 1, 'omitnan');
                meanY = mean(posY_all, 1, 'omitnan');

                % Plot Mean Trajectory as a Thick Line
                plot(meanX, meanY, 'Color', subject_colors{s}, 'LineWidth', 2.5, 'DisplayName', subject);
            end
        else
            disp(['Warning: File not found - ' subject_file]);
        end
    end

    legend show;
    hold off;
end
sgtitle('Comparison of Left Arm Movements Across Subjects', 'FontSize', 14, 'FontWeight', 'bold');

%% NOW, CREATE A SEPARATE FIGURE FOR RIGHT ARM

figure;
tiledlayout(2,2); % 2x2 grid for 4 conditions

for c = 1:length(conditions)
    condition = conditions{c};

    nexttile;
    hold on;
    title([condition_labels{c}, ' - Right Arm'], 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('posX_m', 'FontSize', 10);
    ylabel('posY_m', 'FontSize', 10);

    for s = 1:length(subjects)
        subject = subjects{s};
        subject_file = fullfile('Matlab_data', strcat(subject, '.mat'));

        if exist(subject_file, 'file')
            load(subject_file); % Load subject data
            
            arm = 'r'; % Only right arm in this figure
            if isfield(subjectData.(condition), arm)
                % Extract trajectory data
                posX_all = [];
                posY_all = [];
                min_length = inf;

                for trial = 1:7
                    if length(subjectData.(condition).(arm)) >= trial
                        data = subjectData.(condition).(arm){trial};
                        if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                            min_length = min(min_length, length(data.posX_m));
                        end
                    end
                end

                if isinf(min_length), continue; end % Skip if no valid data

                for trial = 1:7
                    if length(subjectData.(condition).(arm)) >= trial
                        data = subjectData.(condition).(arm){trial};
                        if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                            posX_all(trial, :) = interp1(linspace(0,1,length(data.posX_m)), data.posX_m, linspace(0,1,min_length), 'linear');
                            posY_all(trial, :) = interp1(linspace(0,1,length(data.posY_m)), data.posY_m, linspace(0,1,min_length), 'linear');
                        end
                    end
                end

                % Compute mean trajectory
                meanX = mean(posX_all, 1, 'omitnan');
                meanY = mean(posY_all, 1, 'omitnan');

                % Plot Mean Trajectory as a Thick Line
                plot(meanX, meanY, 'Color', subject_colors{s}, 'LineWidth', 2.5, 'DisplayName', subject);
            end
        else
            disp(['Warning: File not found - ' subject_file]);
        end
    end

    legend show;
    hold off;
end
sgtitle('Comparison of Right Arm Movements Across Subjects', 'FontSize', 14, 'FontWeight', 'bold');