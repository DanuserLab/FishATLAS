function cancerDetectionWrap(imageDataOrProcess, varargin)
% cancerDetectionWrap wrapper function for CancerDetectionProcess
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
[imageData, thisProc] = getOwnerAndProcess(imageDataOrProcess, 'CancerDetectionProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in CancerDetectionProcess

% Parameters
% p

% Sanity Checks
nImFol = numel(imageData.imFolders_);
if max(p.ImFolderIndex) > nImFol || min(p.ImFolderIndex)<1 || ~isequal(round(p.ImFolderIndex), p.ImFolderIndex)
    error('Invalid imFolder numbers specified! Check ImFolderIndex input!!')
end

% precondition / error checking
% check if FishRegistrationProcess was run
if isempty(p.ProcessIndex)
    iFishRegProcessingProc = imageData.getProcessIndex('FishRegistrationProcess',1,true); % nDesired = 1 ; askUser = true
    if isempty(iFishRegProcessingProc)
        error('FishRegistrationProcess needs to be done before run this process.')
    end
elseif isa(imageData.processes_{p.ProcessIndex},'FishRegistrationProcess')
    iFishRegProcessingProc = p.ProcessIndex;
else
    error('The process specified by ProcessIndex is not a valid FishRegistrationProcess! Check input!')
end

% logging input paths (bookkeeping)
inFilePaths = cell(1, numel(imageData.imFolders_));
for i = p.ImFolderIndex
    inFilePaths{1,i} = imageData.processes_{iFishRegProcessingProc}.outFilePaths_{2,i}; % use .mat files as input
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
% See module 5: cancer detection and apply registration map on cancer image/dots in scriptFishAtlas4Jenny_QZ.m
% I kept the algorithm most unchanged, just change the way how ImD handles params and input/output paths.. - QZ
params.pointDetection = p;

tic;
%step 5-1: take the channel for cancer cells form all fish Image
load([inFilePaths{1,1} filesep 'fishImage.mat']); % load output fishImage_hwc from FishRegistrationProcess, which is the same output from step 1 and resaved in step 4. - QZ
cancerImage = cat(3,fishImage_hwc{:}); % original raw image after cropping, no scaling!
cancerImage = cancerImage(:,:,p.cancerChannel:numel(imageData.imFolders_):end);

% check if the image size is similar to the refimage , if not 1) do the
% point detection on the original raw image, 2) rescale points
% RefImage = tiffreadVolume(fullfile(params.Reg.RefImagePath,params.Reg.RefImageName));
RefImage = tiffreadVolume(fullfile(imageData.processes_{iFishRegProcessingProc}.funParams_.RefImagePath,imageData.processes_{iFishRegProcessingProc}.funParams_.RefImageName));
SZ_RefImg = size(RefImage);
SZ_fishImage = size(cancerImage);

params.pointDetection.Scale(1) = SZ_RefImg(2)/SZ_fishImage(2);
params.pointDetection.Scale(2) = SZ_RefImg(1)/SZ_fishImage(1);


% detect cancer regions using point patterns - single scale detection
% savePath = [saveDirectory filesep 'PointDetection'];
savePath = p.OutputDirectory; % QZ
% num2str(params.pointDetection.intensityPerctile) filesep
% 'dotsOnFishImage']; savePath = [saveDirectory filesep
% 'PointDetection_max'
% num2str(params.pointDetection.maxIntensityRateThresh*100) filesep
% 'dotsOnFishImage']; savePath = [saveDirectory filesep 'PointDetection_>'
% num2str(params.pointDetection.IntensityThresh) filesep
% 'dotsOnFishImage'];
% if ~isdir(savePath)  mkdir(savePath); end

% save point overlay with fish image 
    if params.pointDetection.plotFlag
   savePath2 = [savePath filesep 'PointDetection'];
mkdir(savePath2);
    end 
%step 5-2: detect single point for each hotspot

%initialize some variables before for loop
intensityPoints = cell(size(cancerImage,3),1) ;
allPointsCoord = cell(size(cancerImage,3),1) ;
highIntensityPointsCoord = cell(size(cancerImage,3),1) ;

for iFile = 1: size(cancerImage,3)
    imagetmp = cancerImage(:,:,iFile);
    [pstruct, mask, imgLM, imgLoG] = pointSourceDetection(cancerImage(:,:,iFile), params.pointDetection.Sigma, 'Alpha', params.pointDetection.Alpha);
    if isempty (pstruct)
        continue
    end
    X = pstruct.x';
    Y = pstruct.y';

    ptCloudCoor = round([X ,Y ]);
    % IntensityThresh =
    % prctile(pstruct.A,params.pointDetection.intensityPerctile);
    IntensityThresh = max(pstruct.A)*params.pointDetection.maxIntensityRateThresh;
    % IntensityThresh = params.pointDetection.IntensityThresh;
    Ind_good = find(pstruct.A >= IntensityThresh);
    ptCloudCoor = [X(Ind_good), Y(Ind_good)] ;
    if params.pointDetection.plotFlag
        figure('Visible','off');
        imshow(cancerImage(:,:,iFile),[0 round(max(imagetmp(:))/10)])
        hold on
        plot(X,Y,'.r','MarkerSize',25)
        plot(ptCloudCoor(:,1),ptCloudCoor(:,2),'.g','MarkerSize',20)
        hold off
        s = sprintf('fish%04dDots.tif',iFile);
        saveas(gcf,fullfile(savePath2,s))
        imshow(cancerImage(:,:,iFile),[0 round(max(imagetmp(:))/10)])
        s = sprintf('fish%04d.tif',iFile);
        saveas(gcf,fullfile(savePath2,s))
        close("all")
    end
    %resize coordinate to match the reference image (alternative is to
    %imresize cancer image before point source but it cause extra fake
    %poitns)
    X = params.pointDetection.Scale(1).*X;
    Y = params.pointDetection.Scale(1).*Y;
    ptCloudCoorScale = ptCloudCoor.*params.pointDetection.Scale;

    % save in a cell array
    intensityPoints{iFile,1} = pstruct.A';
    allPointsCoord{iFile,1} = [X,Y];
    highIntensityPointsCoord{iFile,1} = ptCloudCoorScale;
    highIntensityPointsCoord_noScale{iFile,1} = ptCloudCoor;

end
%save all dots
save(fullfile(savePath,'dotDetection.mat'),'intensityPoints', 'allPointsCoord','highIntensityPointsCoord','highIntensityPointsCoord_noScale');


%step 5-3: measure weight for each point based on area of binary image if
%user asked to calculate weight, I will calculate it. Default = 1
if params.pointDetection.weightFlag 
    binaryNThresh = params.pointDetection.weightNThresh;
    weightPoints = cell(size(cancerImage,3),1) ;
    binaryImageFish = nan(size(cancerImage));
    binaryAreaDots = nan(size(cancerImage));

    for iFile = 1: size(cancerImage,3)
        image2D = cancerImage(:,:,iFile);
        pointsCoord = highIntensityPointsCoord_noScale{iFile};
        [weight_points binaryImage binaryImage4Dots] = measureWeightPointFish(image2D,pointsCoord,binaryNThresh);
        weightPoints{iFile,1} = weight_points;
        binaryImageFish(:,:,iFile) = binaryImage;
        binaryAreaDots(:,:,iFile) = binaryImage4Dots;
    end
end
%save all dots
save(fullfile(savePath,'dotDetection_weight.mat'),'weightPoints', 'binaryImageFish','binaryAreaDots');

%save binary image in a seprate folder 
% savePath = [saveDirectory filesep 'BinaryDetection']; 
savePath = [p.OutputDirectory filesep 'BinaryDetection']; % QZ put it in CancerDetection folder, instead of one folder up.
if ~isdir(savePath)  mkdir(savePath); end
binaryImageFish = im2uint8(binaryImageFish); 
save(fullfile(savePath,'binaryImage.mat'),'binaryImageFish','binaryAreaDots');

% transfer points based on displacement fields from registration
% savePath = [saveDirectory filesep 'TransferCancer'];
savePath = [p.OutputDirectory filesep 'TransferCancer']; % QZ put it in CancerDetection folder, instead of one folder up.
mkdir(savePath);
savePath2 = [savePath filesep 'TransferDots'];
mkdir(savePath2);

% step5-4: apply the registration fields
rigidPoints = cell(size(cancerImage,3),1);
nonRigidPoints = cell(size(cancerImage,3),1);

for iFile = 1: size(cancerImage,3)

    % assign coordinate
    Coord = highIntensityPointsCoord{iFile};
    if isempty(Coord)
        continue
    end

    %transformation map for rigid and non-rigid registration if
    %registration is good
    load([inFilePaths{1,1} filesep 'registeredFishnonRigid.mat']); % load another output from FishRegistrationProcess - QZ
    if imageFlag_nonRigid(iFile) == 0 % QZ imageFlag_nonRigid is in registeredFishnonRigid.mat
        continue
    end

    load([inFilePaths{1,1} filesep 'registeredFishRigid.mat']); % load another output from FishRegistrationProcess - QZ
    tform = tformTotal{iFile}; % QZ tformTotal is in registeredFishRigid.mat
    DF = dispField(:,:,:,iFile); % QZ dispField is also in registeredFishnonRigid.mat

    [transformed_Coord, nonRigidTransformed_Coordtmp] = transformPointsWithField (Coord, tform,DF)
    nonRigidPoints{iFile,1} = nonRigidTransformed_Coordtmp;
    rigidPoints{iFile,1} = transformed_Coord;

    if params.pointDetection.plotFlag
        plot(Coord(:,1),Coord(:,2),'.')
        hold on
        plot(transformed_Coord(:,1),transformed_Coord(:,2),'.')

        plot(nonRigidTransformed_Coordtmp(:,1),nonRigidTransformed_Coordtmp(:,2),'o');
        legend('original','rigid', 'nonrigid')
        xlim([0 size(DF,2)])
        ylim([0 size(DF,1)])
        set(gcf, 'Position',[50 50 1300 500])
        set(gca,'XAxisLocation','top','YAxisLocation','left','ydir','reverse');

        s = sprintf('fish%04dDots_Reg.png',iFile); %
        saveas(gcf,fullfile(savePath2,s))
        % s = sprintf('fish%04d.mat',iFile); %
        % save(fullfile(saveDirectory,s),'nonRigidTransformed_Coordtmp','transformed_Coordtmp','Coordtmp')
        close(gcf)
    end

    % transfer binaryImage if they are created
    if params.pointDetection.weightFlag
        binaryRigidReg(:,:,iFile) = imwarp(binaryImageFish(:,:,iFile),tform,'OutputView',imref2d(size(RefImage)));
        binarynonRigidReg(:,:,iFile) = imwarp(binaryRigidReg(:,:,iFile), DF,'interp', 'nearest'); % avoid grayscale image
    end
end

% savePath = [saveDirectory filesep 'PointDetection_max10%']
%save all dots
save(fullfile(savePath,'allPoints.mat'),'rigidPoints', 'nonRigidPoints',...
    'highIntensityPointsCoord', 'weightPoints','allPointsCoord','intensityPoints');

save(fullfile(savePath,'binaryImage.mat'),'binaryImageFish', 'binaryRigidReg', 'binarynonRigidReg');

% % save parameters
% save(fullfile(saveDirectory,'params.mat'), 'params');
% t = toc;
% save(fullfile(savePath,'processingTime.mat'),'t')

toc

disp('Finished cancer detection!')

