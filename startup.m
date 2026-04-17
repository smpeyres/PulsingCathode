% Project initialization script - run this at beginning of each session

% Get directory where this startup.m file is located
projectRoot = fileparts(mfilename('fullpath'));

% Add all directories to path
addpath(genpath(fullfile(projectRoot, 'ImageProcessing')));
addpath(genpath(fullfile(projectRoot, 'ReactionDiffusion')));
addpath(genpath(fullfile(projectRoot, 'StabilityAnalysis')));

fprintf('Project initialized. Ready to work!\n');