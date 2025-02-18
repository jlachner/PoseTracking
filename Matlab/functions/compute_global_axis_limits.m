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

