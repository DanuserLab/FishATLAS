function accumulationWrap(imageDataOrProcess, varargin)
% accumulationWrap wrapper function for AccumulationProcess
%
% INPUT
% imageDataOrProcess - either a ImageData (legacy)
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
ip.addRequired('ImD', @(x) isa(x,'ImageData') || isa(x,'Process') && isa(x.getOwner(),'ImageData'));
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(imageDataOrProcess, varargin{:});
paramsIn = ip.Results.paramsIn;

%% Registration
% Get ImageData object and Process
[imageData, thisProc] = getOwnerAndProcess(imageDataOrProcess, 'AccumulationProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in AccumulationProcess

% Parameters
% p

% Sanity Checks
nImFol = numel(imageData.imFolders_);
if max(p.ImFolderIndex) > nImFol || min(p.ImFolderIndex)<1 || ~isequal(round(p.ImFolderIndex), p.ImFolderIndex)
    error('Invalid imFolder numbers specified! Check ImFolderIndex input!!')
end

% precondition / error checking
% check if CancerDetectionProcess was run
if isempty(p.ProcessIndex)
    iCancerDetectionProc = imageData.getProcessIndex('CancerDetectionProcess',1,true); % nDesired = 1 ; askUser = true
    if isempty(iCancerDetectionProc)
        error('CancerDetectionProcess needs to be done before run this process.')
    end
elseif isa(imageData.processes_{p.ProcessIndex},'CancerDetectionProcess')
    iCancerDetectionProc = p.ProcessIndex;
else
    error('The process specified by ProcessIndex is not a valid CancerDetectionProcess! Check input!')
end

% Find the index of FishRegistrationProcess for the refImage used in this step:
iFishRegProcessingProc = imageData.getProcessIndex('FishRegistrationProcess',1,true); % nDesired = 1 ; askUser = true
if isempty(iFishRegProcessingProc)
    error('FishRegistrationProcess needs to be done before run this process.')
end


% logging input paths (bookkeeping)
inFilePaths = cell(1, numel(imageData.imFolders_));
for i = p.ImFolderIndex
    inFilePaths{1,i} = imageData.processes_{iCancerDetectionProc}.outFilePaths_{2,i}; % use .mat files as input
end
thisProc.setInFilePaths(inFilePaths);

% logging output paths.
mkClrDir(p.OutputDirectory);
outFilePaths = cell(1, numel(imageData.imFolders_));
for i = p.ImFolderIndex
    outFilePaths{1,i} = [p.OutputDirectory filesep 'ch' num2str(i)]; % save image output per chan
    outFilePaths{2,i} = [p.OutputDirectory]; % save .mat files for all channels
    mkClrDir(outFilePaths{1,i}); % no need to do mkClrDir(outFilePaths{2,i}) here.
end
thisProc.setOutFilePaths(outFilePaths);

%% Algorithm
% See module 6: accumulator in scriptFishAtlas4Jenny_QZ.m
% I kept the algorithm most unchanged, just change the way how ImD handles params and input/output paths.. - QZ
params.accumulation = p;

tic;

% savePath = [saveDirectory filesep 'Accumulation']; 
savePath = p.OutputDirectory; % QZ

% load a refImage
RefImage = tiffreadVolume(fullfile(imageData.processes_{iFishRegProcessingProc}.funParams_.RefImagePath, imageData.processes_{iFishRegProcessingProc}.funParams_.RefImageName));

% step 6-1: create nonrigid points and corresponding fishID
fishIDsAll = [];
pointCoodAll = [];
weightPointsAll = [];

load([inFilePaths{1,1} filesep 'TransferCancer' filesep 'allPoints.mat']); % load output from CancerDetectionProcess - QZ
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
% t = toc;
% save(fullfile(savePath,'processingTime.mat'),'t')

toc

disp('Finished accumulation!')

