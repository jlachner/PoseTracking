function segments = compute_segments(trials, movement_order, subjectData_all, condition, arm, key_points, radius_threshold)

segments = {};
total_segments = 0;  % Initialize segment counter
num_subjects = length(subjectData_all);

for s = 1:num_subjects
    subjectData = subjectData_all{s};

    for trial = trials
        if isfield(subjectData, condition) && isfield(subjectData.(condition), arm) ...
                && length(subjectData.(condition).(arm)) >= trial

            data = subjectData.(condition).(arm){trial};

            if isfield(data, 'posX_m') && isfield(data, 'posY_m')
                posX = data.posX_m;
                posY = data.posY_m;

                distances_start = sqrt((posX - key_points(1,1)).^2 + (posY - key_points(1,2)).^2);
                valid_start_idx = find(distances_start <= radius_threshold, 1, 'last');
                if ~isempty(valid_start_idx)
                    posX = posX(valid_start_idx:end);
                    posY = posY(valid_start_idx:end);
                end

                for seg = 1:length(movement_order)-1
                    start_idx = movement_order(seg);
                    end_idx = movement_order(seg+1);

                    dist_from_start = sqrt((posX - key_points(start_idx,1)).^2 + (posY - key_points(start_idx,2)).^2);
                    last_idx_start = find(dist_from_start <= radius_threshold, 1, 'last');

                    dist_from_end = sqrt((posX - key_points(end_idx,1)).^2 + (posY - key_points(end_idx,2)).^2);
                    first_idx_end = find(dist_from_end <= radius_threshold, 1, 'first');

                    if ~isempty(last_idx_start) && ~isempty(first_idx_end) && last_idx_start < first_idx_end
                        segment.X = posX(last_idx_start:first_idx_end);
                        segment.Y = posY(last_idx_start:first_idx_end);
                        segments{end+1} = segment;
                        total_segments = total_segments + 1;  % Increment counter
                    end
                end
            end
        end
    end
end

% Display the total segments found
disp(['Total segments found for ', condition, ' (', upper(arm), ' Arm): ', num2str(total_segments)]);

% Calculate the expected number of segments
% 6 segments per trial x 3 trials x 2 arms x 4 conditions x N subjects
expected_segments = 6 * 3 * 2 * 4 * num_subjects;

% Throw an error if the total segments are different from the expected count
if total_segments ~= 54
    error(['Segment count mismatch! Expected 54 segments per condition-arm combination, but found ', num2str(total_segments)]);
end

end

