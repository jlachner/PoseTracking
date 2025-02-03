% Define the folder structure
%base_folder = "/Users/johanneslachner/Documents/InMotion_Tracking/Input";
base_folder = "/Users/johanneslachner/MIT Dropbox/Johannes Lachner/forHannah/Data/InMotion/";
subject = "s1";
condition = "constraint";

% Construct the file path for the specific condition of the subject
subject_folder = fullfile(base_folder, subject, "InMotion");
mat_file = fullfile(subject_folder, condition + ".mat");

% Check if the file exists
if isfile(mat_file)
    try
        % Load the .mat file
        data = load(mat_file);
        
        % Extract variables
        if isfield(data, 'posX_m') && isfield(data, 'posY_m')
            posX = data.posX_m(:); % Ensure column vector
            posY = data.posY_m(:);
            
            % Debugging: Print first few values and lengths
            disp("First 5 values of posX:");
            disp(posX(1:min(5, end)));
            disp("First 5 values of posY:");
            disp(posY(1:min(5, end)));
            disp("Length of posX: " + num2str(length(posX)));
            disp("Length of posY: " + num2str(length(posY)));

            % Debugging: Print min and max values
            disp("Min/Max of posX: " + num2str(min(posX)) + " / " + num2str(max(posX)));
            disp("Min/Max of posY: " + num2str(min(posY)) + " / " + num2str(max(posY)));

            % Validate and plot data
            if isempty(posX) || isempty(posY)
                disp("Error: One or both arrays are empty.");
            elseif length(posX) ~= length(posY)
                disp("Error: Mismatched lengths! posX has " + num2str(length(posX)) + ...
                     " entries, posY has " + num2str(length(posY)) + " entries.");
            elseif all(posX == posX(1)) && all(posY == posY(1))
                disp("Error: Data is constant; no variation to plot.");
            else
                % Plot the data
                figure;
                plot(posX, posY, 'r-', 'LineWidth', 2);
                xlabel("posX_m");
                ylabel("posY_m");
                title("2D Path for Subject 1 - Constraint Condition");
                xlim([min(posX) - 0.01, max(posX) + 0.01]);
                ylim([min(posY) - 0.01, max(posY) + 0.01]);
                legend(subject + "_" + condition, 'Location', 'best');
                disp("Data plotted successfully: " + num2str(length(posX)) + " points.");
            end
        else
            disp("Error: posX_m or posY_m not found in the .mat file.");
        end
    catch ME
        disp("Error processing file " + mat_file + ": " + ME.message);
    end
else
    disp("File does not exist: " + mat_file);
end