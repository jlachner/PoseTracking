%% Plot segments
function plot_segmented_trajectories(trials, movement_order, subjectData_all, key_points, key_labels, conditions, condition_labels, arms, colors, radius_threshold, fig_title)
    figure;
    tiledlayout(2,2);
    sgtitle(fig_title, 'FontSize', 14, 'FontWeight', 'bold');

    % Compute global axis limits within this function
    [x_min, x_max, y_min, y_max] = compute_global_axis_limits(subjectData_all, key_points, conditions, arms);

    for c = 1:length(conditions)
        condition = conditions{c};
        nexttile;
        hold on;
        title(condition_labels{c}, 'FontSize', 12, 'FontWeight', 'bold');
        xlabel('X [m]'); ylabel('Y [m]');
        xlim([x_min, x_max]); ylim([y_min, y_max]);

        legend_entries = [];
        legend_labels = [];

        for a = 1:length(arms)
            arm = arms{a};

            segments = compute_segments(trials, movement_order, subjectData_all, condition, arm, key_points, radius_threshold);

            for i = 1:length(segments)
                plot(segments{i}.X, segments{i}.Y, 'Color', colors{a}, 'LineWidth', 1.5);
            end

            if a == 1
                legend_entries(end+1) = plot(NaN, NaN, 'Color', colors{1}, 'LineWidth', 1.5);
                legend_labels{end+1} = 'L Arm';
            elseif a == 2
                legend_entries(end+1) = plot(NaN, NaN, 'Color', colors{2}, 'LineWidth', 1.5);
                legend_labels{end+1} = 'R Arm';
            end
        end

        for k = 1:size(key_points, 1)
            plot(key_points(k,1), key_points(k,2), 'ko', 'MarkerSize', 6, 'LineWidth', 1.5, 'MarkerFaceColor', 'k');
            text(key_points(k,1) + 0.005, key_points(k,2) + 0.005, key_labels{k}, 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
        end

        legend(legend_entries, legend_labels, 'Location', 'Best');
        hold off;
    end
end