function accumulationWrap(imageListOrProcess, varargin)
% accumulationWrap wrapper function for AccumulationProcess
%
% INPUT
% imageListOrProcess - either a ImageList (legacy)
%                      or a Process (new as of July 2016)
%
% param - (optional) A struct describing the parameters, overrides the
%                    parameters stored in the process (as of Aug 2016)
%
% OUTPUT
% none (saved to p.OutputDirectory)
%
% Changes
% As of July 2016, the first argument could also be a Process. Use
% getOwnerAndProcess to simplify compatability.
%
% As of August 2016, the standard second argument should be the parameter
% structure
%
%
% Qiongjing (Jenny) Zou, Mar 2026
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

%% ------------------ Input ---------------- %%
ip = inputParser;
ip.addRequired('imageListOrProcess', @isProcessOrImageList);
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(imageListOrProcess, varargin{:});
paramsIn = ip.Results.paramsIn;

%% Registration
% Get ImageList object and Process
[imageList, thisProc] = getOwnerAndProcess(imageListOrProcess, 'AccumulationProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in AccumulationProcess

% Parameters
% p % for now, all ImDs use same p - QZ

numImDs = numel(imageList.imageDataFile_);
if isfield(p,'ImageDataIndex') && ~isempty(p.ImageDataIndex)
    imageDataIndex = p.ImageDataIndex;
else
    imageDataIndex = 1:numImDs;
end
if max(imageDataIndex) > numImDs || min(imageDataIndex)<1 || ~isequal(round(imageDataIndex), imageDataIndex)
    error('Invalid ImageData numbers specified! Check ImageDataIndex input!!')
end

% precondition / error checking
% check if CancerDetectionProcess was run
if isempty(p.ProcessIndex)
    iCancerDetectionProc = imageList.getProcessIndex('CancerDetectionProcess',1,true); % nDesired = 1 ; askUser = true
    if isempty(iCancerDetectionProc)
        error('CancerDetectionProcess needs to be done before run this process.')
    end
elseif isa(imageList.processes_{p.ProcessIndex},'CancerDetectionProcess')
    iCancerDetectionProc = p.ProcessIndex;
else
    error('The process specified by ProcessIndex is not a valid CancerDetectionProcess! Check input!')
end
cancerDetectionProc = imageList.processes_{iCancerDetectionProc};

% Find the index of FishRegistrationProcess for the refImage used in this step:
iFishRegProcessingProc = imageList.getProcessIndex('FishRegistrationProcess',1,true); % nDesired = 1 ; askUser = true
if isempty(iFishRegProcessingProc)
    error('FishRegistrationProcess needs to be done before run this process.')
end
fishRegProcessingProc = imageList.processes_{iFishRegProcessingProc};

ImDs = cell(1, numImDs);
for iImD = imageDataIndex
    ImDs{iImD} = ImageData.load(imageList.imageDataFile_{1,iImD});
end

% Do below on the ImD level:

allInFilePaths = cell(1, numImDs);
allOutFilePaths = cell(1, numImDs);
[packageOutputDirectory, processOutputName] = fileparts(p.OutputDirectory);
[~, packageOutputName] = fileparts(packageOutputDirectory);
mkClrDir(p.OutputDirectory);

for iImD = imageDataIndex
    imageData = ImDs{1, iImD};

    % Sanity Checks
    nImFol = numel(imageData.imFolders_);
    if max(p.ImFolderIndex) > nImFol || min(p.ImFolderIndex)<1 || ~isequal(round(p.ImFolderIndex), p.ImFolderIndex)
        error('Invalid imFolder numbers specified! Check ImFolderIndex input!!')
    end

    cancerDetectionOutFilePaths = cancerDetectionProc.outFilePaths_{1,iImD};

    % logging input paths (bookkeeping)
    inFilePaths = cell(1, numel(imageData.imFolders_));
    for iImFolder = p.ImFolderIndex
        inFilePaths{1,iImFolder} = cancerDetectionOutFilePaths{2,iImFolder}; % use .mat files as input
    end
    allInFilePaths{1,iImD} = inFilePaths;

    % logging output paths.
    imageOutputDirectory = fullfile(imageData.outputDirectory_, packageOutputName, processOutputName);
    mkClrDir(imageOutputDirectory);
    outFilePaths = cell(2, numel(imageData.imFolders_));
    for iImFolder = p.ImFolderIndex
        outFilePaths{1,iImFolder} = [imageOutputDirectory filesep 'ch' num2str(iImFolder)]; % save image output per chan
        outFilePaths{2,iImFolder} = imageOutputDirectory; % save .mat files for all channels
        mkClrDir(outFilePaths{1,iImFolder}); % no need to do mkClrDir(outFilePaths{2,iImFolder}) here.
    end
    allOutFilePaths{1,iImD} = outFilePaths;
end

% logging input/output paths on the ImL level.
thisProc.setInFilePaths(allInFilePaths);
thisProc.setOutFilePaths(allOutFilePaths);


% Run below Algorithm on the ImD level:


for iImD = imageDataIndex
    imageData = ImDs{1, iImD};
    inFilePaths = allInFilePaths{1,iImD};
    outFilePaths = allOutFilePaths{1,iImD};

%% Algorithm
% Package process mapping:
% Process 5 AccumulationProcess wraps module 6 from
% scriptFishAtlas4Jenny_QZ.m:
%   module 6: accumulator
% I kept the algorithm most unchanged, just change the way how ImD handles params and input/output paths.. - QZ
params.accumulation = p;

tic;

% savePath = [saveDirectory filesep 'Accumulation']; 
savePath = outFilePaths{2,p.ImFolderIndex(1)}; % QZ

% load a refImage
fishRegOutFilePaths = fishRegProcessingProc.outFilePaths_{1,iImD};
refImagePath = fullfile(fishRegOutFilePaths{2,p.ImFolderIndex(1)}, 'RefImage.tif');
if exist(refImagePath, 'file')
    RefImage = tiffreadVolume(refImagePath);
else
    RefImage = tiffreadVolume(fullfile(fishRegProcessingProc.funParams_.RefImagePath, fishRegProcessingProc.funParams_.RefImageName));
end

% step 6-1: create nonrigid points and corresponding fishID
fishIDsAll = [];
pointCoodAll = [];
weightPointsAll = [];

load([inFilePaths{1,p.ImFolderIndex(1)} filesep 'TransferCancer' filesep 'allPoints.mat']); % load output from CancerDetectionProcess - QZ
for iFile = 1: size(nonRigidPoints,1) % QZ nonRigidPoints is in allPoints.mat
    X = nonRigidPoints{iFile};
    %skip for fish those have fail registration
    if isempty(X)
        continue
    end
    W = weightPoints{iFile}; % QZ weightPoints is in allPoints.mat

    % find the fish index from the channel 1 folder  - QZ added   
    imFileNamesF = imageData.getImageFileNames(1);
    foldername= imFileNamesF{1}; 
    fileList = cellfun(@(x) str2double(regexp(x, '\d+', 'match')), foldername);

    fishID = ones(size(X,1),1)*fileList(iFile); % QZ fileList was obtained in step 1 from ch1, but is here for ch2?
    fishIDsAll = cat(1,fishIDsAll,fishID);
    pointCoodAll = cat(1,pointCoodAll,X);
    weightPointsAll = cat(1,weightPointsAll,W);
end


% stpe 6-2: removing the outliers by masking the reference image --> fish
% body:
%load a binaryImage of fish body to define outliers
if ~isempty(params.accumulation.fishBodyImage)
    binaryImage = tiffreadVolume(fullfile(params.accumulation.fishBodyImageDir,params.accumulation.fishBodyImage));
else
    binaryImage = makeBinaryFishBody(RefImage);
    figure;
    imshow(binaryImage);
    warning('The generated binary image may require manual verification before creating an accumulator')
end

if params.accumulation.removeOutsides
    [pointCoodIn  InsideFlag binaryImage] = remove_outside_points(pointCoodAll, binaryImage);
    fishIDsIn = fishIDsAll(find(InsideFlag));
    weightPointsIn = weightPointsAll(find(InsideFlag));
else
    pointCoodIn = pointCoodAll;
    weightPointsIn = weightPointsAll;
    fishIDsIn = fishIDsAll;
end


% save all points
figure;
imshow(RefImage,[0 round(max(RefImage(:))/5)])
hold on
plot(pointCoodAll(:,1),pointCoodAll(:,2),'.r')
saveas(gcf,fullfile(savePath,'nonRigidPattern.png'))

plot(pointCoodIn(:,1),pointCoodIn(:,2),'.g')

saveas(gcf,fullfile(savePath,'nonRigidPatternIn.png'))

save(fullfile(savePath,'pointPattern.mat'), 'pointCoodAll','fishIDsAll','weightPointsAll',...
    'pointCoodIn','fishIDsIn','weightPointsIn','binaryImage')

imwrite(im2uint8(binaryImage),fullfile(savePath,'fishBodyImage.tif'));

% % save parameters
% save(fullfile(saveDirectory,'params.mat'), 'params');

t = toc;
save(fullfile(savePath,'processingTime.mat'),'t')

end

disp('Finished accumulation!')
