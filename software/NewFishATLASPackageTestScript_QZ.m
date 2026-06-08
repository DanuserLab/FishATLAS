% A sample script to create an ImageList and run NewFishATLAS Package by script.
% Qiongjing (Jenny) Zou, Feb 2026
%
% Copyright (C) 2026, Danuser Lab - UTSouthwestern 
%
% This file is part of FishATLAS_Package.
% 
% FishATLAS_Package is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% FishATLAS_Package is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with FishATLAS_Package.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

clear

%% ImageList creation

if ispc
    dataRoot = 'C:\Users\s184919\Documents\Data\NewFishATLASPackWriting202511\testScript\data4Jenny';
elseif isunix
    dataRoot = '/work/bioinformatics/s184919/Analysis/Hanieh/202511NewFishATLASPack/testScript/data4Jenny';
end

conditionNames = {'CHLA9', 'CHLA10'}; 
ImDs = cell(1, numel(conditionNames));

for iCondition = 1:numel(conditionNames)
    conditionDir = fullfile(dataRoot, conditionNames{iCondition});

    clear imFolder
    imFolder(1) = ImFolder(fullfile(conditionDir, 'ch1'));
    imFolder(1).pixelSize_ = 100; % fake value to test pixelSize_ can be properly set -QZ
    imFolder(2) = ImFolder(fullfile(conditionDir, 'ch2'));
    imFolder

    ImD = ImageData(imFolder, conditionDir); % saveFolder here is ImD's outputDirectory_
    ImD.setPath(conditionDir); % set imageDataPath_, where to save .mat file
    ImD.setFilename('imageData.mat');

    % Set some additional image data properties
    ImD.notes_= ['NewFishATLAS Package test run: ' conditionNames{iCondition}];

    % Run sanityCheck on ImageData.
    % Save the image data if successful
    ImD.sanityCheck; % add reader to the object, also does ImD.save(), Also add reader and nImages_ to ImD.imFolders(i);
                     % Also, set/update both ImD and ImD.imFolders(i)'s readers' properties - sizeXmax, sizeYmax, nImages, bitDepthMax, sizeZ, and filenames
                     % if pixelSize_ of one imFolder was set, copy it to the readers of that imFolder and ImD.
    ImD.save; % included in the ImD.sanityCheck
    ImD.reset(); % to clean up processes_ and packages_

    %% Load the image data contents
    clear ImD; % verify we can reload the object as intended.
    ImDs{iCondition} = ImageData.load(fullfile(conditionDir,'imageData.mat')); % if isMatFile, also does ImD.sanityCheck
    ImDs{iCondition}
end

imageListAnalysisDir = fullfile(dataRoot, 'AnalysisImLPack20260521');
if ~isdir(imageListAnalysisDir) mkdir(imageListAnalysisDir); end
ImL = ImageList(ImDs, imageListAnalysisDir);
ImL.setPath(imageListAnalysisDir);
ImL.setFilename('imageList.mat');
ImL.sanityCheck;
ImL.save;
ImL.reset();

%% Load the image list contents
clear ImL; % verify we can reload the object as intended.
ImL = ImageList.load(fullfile(imageListAnalysisDir,'imageList.mat'));

%% Create FishATLAS Package and retrieve package index
Package_ = NewFishATLASPackage(ImL);
ImL.addPackage(Package_);
stepNames = Package_.getProcessClassNames;
iPack =  ImL.getPackageIndex('NewFishATLASPackage');
disp('=====================================');
disp('|| Available Package Process Steps ||');
disp('=====================================');
disp(ImL.getPackage(1).getProcessClassNames');

steps2Test = [1 2 3 4 5];
assert(length(Package_.processes_) >= length(steps2Test));
assert(length(Package_.processes_) >= max(steps2Test));
disp('Selected Package Process Steps');

for i=steps2Test
  disp(['Step ' num2str(i) ': ' stepNames{i}]);
end

%% Step 1: FishPreProcessingProcess
disp('===================================================================');
disp('Running (1st) FishPreProcessingProcess');
disp('===================================================================');
iPack = 1;
step_ = 1;
ImL.getPackage(iPack).createDefaultProcess(step_)
params = ImL.getPackage(iPack).getProcess(step_).funParams_;

ImL.getPackage(iPack).getProcess(step_).setPara(params);
ImL.save;
params = ImL.getPackage(iPack).getProcess(step_).funParams_
ImL.getPackage(iPack).getProcess(step_).run(); % also does obj.getOwner().save(), i.e. ImL.save()

%% Step 2: CreateReferenceImageProcess 
disp('===================================================================');
disp('Running (2nd) CreateReferenceImageProcess'); 
disp('===================================================================');
iPack = 1;
step_ = 2;
ImL.getPackage(iPack).createDefaultProcess(step_)
params = ImL.getPackage(iPack).getProcess(step_).funParams_;

ImL.getPackage(iPack).getProcess(step_).setPara(params);
ImL.save;
params = ImL.getPackage(iPack).getProcess(step_).funParams_
ImL.getPackage(iPack).getProcess(step_).run();

%% Step 3: FishRegistrationProcess 
disp('===================================================================');
disp('Running (3rd) FishRegistrationProcess'); 
disp('===================================================================');
iPack = 1;
step_ = 3;
ImL.getPackage(iPack).createDefaultProcess(step_)
params = ImL.getPackage(iPack).getProcess(step_).funParams_;

params.useRefImage = 1; % use the reference image; Can also run with 0 - no RefImage.
params.RefImagePath = dataRoot;

ImL.getPackage(iPack).getProcess(step_).setPara(params);
ImL.save;
params = ImL.getPackage(iPack).getProcess(step_).funParams_
ImL.getPackage(iPack).getProcess(step_).run(); % took 21 min!

%% Step 4: CancerDetectionProcess
disp('===================================================================');
disp('Running (4th) CancerDetectionProcess'); 
disp('===================================================================');
iPack = 1;
step_ = 4;
ImL.getPackage(iPack).createDefaultProcess(step_)
params = ImL.getPackage(iPack).getProcess(step_).funParams_;

ImL.getPackage(iPack).getProcess(step_).setPara(params);
ImL.save;
params = ImL.getPackage(iPack).getProcess(step_).funParams_
ImL.getPackage(iPack).getProcess(step_).run();

%% Step 5: AccumulationProcess
disp('===================================================================');
disp('Running (5th) AccumulationProcess'); 
disp('===================================================================');
iPack = 1;
step_ = 5;
ImL.getPackage(iPack).createDefaultProcess(step_)
params = ImL.getPackage(iPack).getProcess(step_).funParams_;

ImL.getPackage(iPack).getProcess(step_).setPara(params);
ImL.save;
params = ImL.getPackage(iPack).getProcess(step_).funParams_
ImL.getPackage(iPack).getProcess(step_).run();


%% test NewFishATLASPackage GUI:
% method 0
movieSelectorGUI('ImL',ImL)

% method 1
NewFishATLASPackage.GUI(ImL)

% method 2
NewFishATLASPackageGUI(ImL)
