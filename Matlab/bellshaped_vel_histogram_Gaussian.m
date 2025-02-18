%% Simulated Example: Velocity Profile Over Time

% Clean-up
clc;
clear;
close all;

% Generate bell-shaped velocity profiles for 100 trials
num_trials = 300;
time_points = linspace(0, 1, 1000); 
peak_velocity = 1; % Max velocity

velocity_profiles = zeros(num_trials, length(time_points));

for i = 1:num_trials
    duration = 1 + 0.1 * randn(); % Slight variation in movement duration
    time_var = linspace(0, duration, length(time_points));
    peak_var = peak_velocity + 0.05 * randn(); % Add small random peak variations

    % Sinusoidal movement
    %velocity_profiles(i, :) = peak_var * sin(linspace(0, pi, length(time_var)));

    % minimum jerk trajectory: v(\tau) = 30\tau^2(1-\tau)^
    tau = time_var / max(time_var);                                             %tau is normalized to [0,1]
    velocity_profiles(i, :) = peak_var * (30 * tau.^2 .* (1 - tau).^2);
end

% Plot Velocity Profiles Over Time
figure;
hold on;
for i = 1:length(num_trials) % Plot only 10 trials for clarity
    plot(time_points, velocity_profiles(i, :), 'LineWidth', 1.5);
end
hold off;
xlabel('Time [s]'); ylabel('Velocity [m/s]');
title('Simulated Velocity Profiles Over Time');
grid on;

% Flatten all velocity values into a single array
all_velocities = velocity_profiles(:);

% Plot Histogram
figure;
histogram(all_velocities, 30, 'Normalization', 'pdf', 'FaceColor', 'b', 'BinWidth', 0.01);
xlabel('Velocity [m/s]'); ylabel('Density');
title('Velocity Histogram from Multiple Trials');
grid on;


%% Compute and Plot Peak Velocity Distribution

% Compute the peak velocity for each trial
peak_velocities = max(velocity_profiles, [], 2); % Maximum velocity per trial

% Plot histogram of peak velocities
figure;
histogram(peak_velocities, 20, 'Normalization', 'pdf', 'FaceColor', 'b'); 
xlabel('Peak Velocity [m/s]'); 
ylabel('Density'); 
title('Distribution of Peak Velocities Across Trials');
grid on;

% Display basic statistics
mean_peak = mean(peak_velocities);
std_peak = std(peak_velocities);
fprintf('Mean Peak Velocity: %.4f m/s\n', mean_peak);
fprintf('Standard Deviation of Peak Velocity: %.4f m/s\n', std_peak);

%% Normality Tests
% Jarque-Bera Test
[h_jb, p_jb] = jbtest(peak_velocities);

% Kolmogorov-Smirnov Test (against normal distribution)
[h_ks, p_ks] = kstest((peak_velocities - mean_peak) / std_peak);

% Print results
fprintf('Mean Peak Velocity: %.4f m/s\n', mean_peak);
fprintf('Standard Deviation of Peak Velocity: %.4f m/s\n', std_peak);
fprintf('Jarque-Bera Test: p = %.4f (h = %d)\n', p_jb, h_jb);
fprintf('Kolmogorov-Smirnov Test: p = %.4f (h = %d)\n', p_ks, h_ks);

%% Decision on Normality
if p_jb > 0.05 && p_ks > 0.05
    fprintf('The peak velocity distribution is Gaussian.\n');
else
    fprintf('The peak velocity distribution is NOT Gaussian.\n');
end

