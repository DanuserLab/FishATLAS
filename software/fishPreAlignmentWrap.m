function fishPreAlignmentWrap(imageListOrProcess, varargin)
% fishPreAlignmentWrap wrapper function for FishPreProcessingProcess
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

%% ------------------ Input ---------------- %%
ip = inputParser;
ip.addRequired('imageListOrProcess', @isProcessOrImageList);
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(imageListOrProcess, varargin{:});
paramsIn = ip.Results.paramsIn;

%% Registration
% Get ImageList object and Process
[imageList, thisProc] = getOwnerAndProcess(imageListOrProcess, 'FishPreProcessingProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in FishPreProcessingProcess

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

% precondition / error checking
% must have at least 2 imFolders_
if numel(imageData.imFolders_) < 2
    error('imageData.imFolders_ must contain at least 2 image folders!');
end

% nImages_ in each ImFolder must be the same
nImages = arrayfun(@(x) x.nImages_, imageData.imFolders_);
if ~all(nImages == nImages(1))
    error('Number of Images in each Image Folder needs to be the same! Check ImageData input!');
end

% QZ TODO - Do the fish file names in all channels need to be the same?

% logging input paths (bookkeeping)
inFilePaths = cell(1, numel(imageData.imFolders_));
for iImFolder = p.ImFolderIndex
    inFilePaths{1,iImFolder} = imageData.getImFolderPaths{iImFolder};
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
% Process 1 FishPreProcessingProcess wraps modules 1-2 from
% scriptFishAtlas4Jenny_QZ.m:
%   module 1: loading
%   module 2: prepAlign: cropping, padding (resize), flipping
% I rewrote the algorithm to the way how ImD handel paths and files. - QZ

%% module 1: loading
%load all channels for all fish
saveDirectory = outFilePaths{2,p.ImFolderIndex(1)};

tic;

% directory read the number of fish from the folder
newDir = dir(inFilePaths{1,1});% only got the 1st channel file names, why? - QZ
foldername = {newDir.name};
%remove hidden folders
foldername (ismember(foldername,[{'.'}, {'..'}])) =[];
% find the fish index from the folder automatically
fileList = cellfun(@(x) str2double(regexp(x, '\d+', 'match')), foldername)';
% for k = p.ImFolderIndex
%     imFileNamesF = imageData.getImageFileNames(k);
%     foldername{k,:} = imFileNamesF{1}'; % Rewrote so files name in ch1 and ch2 does not need to be the same. -QZ
% end

nFish = imageData.imFolders_(1).nImages_;
nChannel = numel(imageData.imFolders_);
for iFile = 1: nFish
    clear imagetmp
    for iChannel = 1: nChannel
        filename = foldername(iFile);
        channelPath = inFilePaths{1,iChannel};
        % image are not exactly same size that is why I need to load as
        % cell array fishImage{iFile,iChannel} =
        % tiffreadVolume(fullfile(channelPath,filename));
        imagetmp(:,:,iChannel) = tiffreadVolume(fullfile(channelPath,filename));
    end
    fishImage{iFile,1} = imagetmp;
end

% t(1) = toc;

%% module 2: prepAlign: cropping, padding (resize), flipping
% tic;
maxSZ = [1 1];
for iFile = 1:nFish
    % step2-1: cropping the image in all channels, modify it to crop only
    % at the center
    [croppedImage_hwc imageLabeled] = autoCropFish2D(fishImage{iFile,1}, p.cropping_borderPX);

    %find the maximum size across the fish images to resize them for
    %alignment
    sizeImage(iFile,:) = size(croppedImage_hwc);
    maxSZ(1) = max(maxSZ(1),sizeImage(iFile,1));
    maxSZ(2) = max(maxSZ(2),sizeImage(iFile,2));
    croppedFishImage{iFile,1} = croppedImage_hwc;
end

%check if all fish haspointDetectionFish a minimum padding, if not add more
%padding to all
diffSZ = maxSZ - sizeImage(:,1:2);
if any(diffSZ < p.padding_minTickness )
    maxSZ = maxSZ + p.padding_minTickness ;
end

% step 2-2: padding
for iFile = 1:nFish
    image_hwc = croppedFishImage{iFile};
    diffSZ = maxSZ - sizeImage(iFile, 1:2);
    PaddingImage_hwc = addBlackBorder2D(image_hwc, diffSZ);
    paddingFishImage{iFile,1} = PaddingImage_hwc;
    SZ_padding(iFile, : ) = size(PaddingImage_hwc);
end

%step 2-3: flipping left/right or top/bottom
for iFile = 1:nFish
    image_hwc = paddingFishImage{iFile};
    FlippingImage_hwc = flippingFish2D(image_hwc);
    flippingFishImage{iFile,1} = FlippingImage_hwc;
end

fishImage_hwc = flippingFishImage;

%save all results,
savePath = saveDirectory;

save(fullfile(savePath,'fishImages.mat'),'fishImage', 'croppedFishImage','flippingFishImage');
save(fullfile(savePath,'fishImage_4Reg.mat'),'fishImage_hwc');

% save tif files:
for iChannel = 1:nChannel
    savePath1 = outFilePaths{1,iChannel};
    for iFile = 1:nFish
        s = sprintf('fish%04d.tif',fileList(iFile));
        imagetmp = fishImage_hwc{iFile}(:,:,iChannel);
        imwrite(im2uint8(imagetmp), fullfile(savePath1, s));
    end
end

% save parameters
% save(fullfile(saveDirectory,'params.mat'), 'params');
% t(2) = toc;
% save(fullfile(savePath,'processingTime.mat'),'t')

toc

end

disp('Finished fish images pre-processing!')
