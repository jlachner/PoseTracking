clear
close all
clc

% Add paths for TDMS file reading
addpath('ReadTDMS')
addpath('ReadTDMS/tdmsSubfunctions')

% Define the folder containing .tdms files
dataFolder = './subject1/'; % Adjust the path to point to the correct folder
tdmsFiles = dir(fullfile(dataFolder, '*.tdms'));

% Check if there are any .tdms files in the folder
if isempty(tdmsFiles)
    disp('No .tdms files found in the folder.');
    return;
end

% Process each .tdms file
for fileIdx = 1:length(tdmsFiles)
    FileName = tdmsFiles(fileIdx).name;
    PathName = tdmsFiles(fileIdx).folder;
    
    disp(['Reading in data from ', FileName, '...']);
    
    % Read TDMS file
    [finalOutput, metaStruct] = TDMS_readTDMSFile(fullfile(PathName, FileName));
    filearray = strsplit(FileName, '.');
    file = filearray{1};
    
    disp('Assigning data to variable names...');
    
    % Assign data to variable names
    for i = 1:size(finalOutput.chanNames{1}, 2)
        name = finalOutput.chanNames{1}{i};
        name = replace(name, '-', '_');
        name = replace(name, '/', 'p');
        eval([name, '=finalOutput.data{', num2str(i + 2), '};']);
        lengthVar = size(eval(name), 2);
        eval([name, '=', name, '(2:lengthVar);']);
    end
    
    % Generate timestamp for the output file name
    currenttime = clock;
    hour = sprintf('%02d', currenttime(4));
    minute = sprintf('%02d', currenttime(5));
    dateandtime = strcat(date, '-', hour, '-', minute);
    
    % Save data to a .mat file
    outputFile = fullfile('Matlab_data', strcat(file, '-', dateandtime, '.mat'));
    disp(['Saving data to ', outputFile]);
    save(outputFile);
    
    % Adjust time variable (if applicable)
    if exist('time_s', 'var')
        time = time_s - time_s(1);
    end
end

disp('All .tdms files have been processed.');