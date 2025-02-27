% Clean-up
close all
clear
clc

% Add paths for TDMS file reading
addpath('ReadTDMS')
addpath('ReadTDMS/tdmsSubfunctions')

% Define the folder containing .tdms files
base_folder = '/Users/johanneslachner/MIT Dropbox/Johannes Lachner/forHannah/Data/InMotion/';
subject = 's4';

% Construct the file path for the specific condition of the subject
subject_folder = fullfile( base_folder, subject );

tdmsFiles = dir(fullfile(subject_folder, '*.tdms'));

% Check if there are any .tdms files in the folder
if isempty(tdmsFiles)
    disp('No .tdms files found in the folder.');
    return;
end

% Initialize structure for subject data
subjectData = struct();

% Process each .tdms file
for fileIdx = 1:length(tdmsFiles)
    FileName = tdmsFiles(fileIdx).name;
    PathName = tdmsFiles(fileIdx).folder;
    
    disp(['Reading in data from ', FileName, '...']);
    
    % Read TDMS file
    [finalOutput, metaStruct] = TDMS_readTDMSFile(fullfile(PathName, FileName));
    filearray = strsplit(FileName, '.');
    file = filearray{1};
    
    % Extract condition, arm, and trial from the filename (assuming structure: s1_c_l_1)
    tokens = regexp(file, [ subject, '_([a-zA-Z]+)_([lr])_(\d+)' ], 'tokens');
    if isempty(tokens)
        disp(['Skipping unrecognized file format: ', FileName]);
        continue;
    end
    
    condition = tokens{1}{1};  % Condition type (c, noC, st, wr)
    arm = tokens{1}{2};        % Arm (l or r)
    trial = str2double(tokens{1}{3}); % Trial number

    disp('Assigning data to variable names...');
    
    % Assign data to variable names
    trialData = struct();
    for i = 1:size(finalOutput.chanNames{1}, 2)
        name = finalOutput.chanNames{1}{i};
        name = replace(name, '-', '_');
        name = replace(name, '/', 'p');
        trialData.(name) = finalOutput.data{i + 2};
        
        % Remove first sample if necessary
        if size(trialData.(name), 2) > 1
            trialData.(name) = trialData.(name)(2:end);
        end
    end
    
    % Store data in structured format
    subjectData.(condition).(arm){trial} = trialData;
    
    % Adjust time variable (if applicable)
    if isfield(trialData, 'time_s')
        subjectData.(condition).(arm){trial}.time = trialData.time_s - trialData.time_s(1);
    end
end

% Save structured data to a single .mat file using the folder name
outputFile = fullfile('Matlab_data', strcat(subject, '.mat'));
disp(['Saving consolidated data to ', outputFile]);
save(outputFile, 'subjectData');

disp('All .tdms files have been processed and saved into a single .mat file.');
