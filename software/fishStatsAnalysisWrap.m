function fishStatsAnalysisWrap(imageListOrProcess, varargin)
% fishStatsAnalysisWrap wrapper function for FishStatsAnalysisProcess
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
% Qiongjing (Jenny) Zou, Jul 2026
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
[imageList, thisProc] = getOwnerAndProcess(imageListOrProcess, 'FishStatsAnalysisProcess', true);
p = parseProcessParams(thisProc, paramsIn); % If parameters are explicitly given, they should be used
% rather than the one stored in FishStatsAnalysisProcess

% Parameters
% p

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
% check if AccumulationProcess was run
if isempty(p.ProcessIndex)
    iAccumulationProc = imageList.getProcessIndex('AccumulationProcess',1,true); % nDesired = 1 ; askUser = true
    if isempty(iAccumulationProc)
        error('AccumulationProcess needs to be done before run this process.')
    end
elseif isa(imageList.processes_{p.ProcessIndex},'AccumulationProcess')
    iAccumulationProc = p.ProcessIndex;
else
    error('The process specified by ProcessIndex is not a valid AccumulationProcess! Check input!')
end
accumulationProc = imageList.processes_{iAccumulationProc};

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
% allOutFilePaths = cell(1, numImDs);
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

    accumulationOutFilePaths = accumulationProc.outFilePaths_{1,iImD};

    % logging input paths (bookkeeping)
    inFilePaths = cell(1, numel(imageData.imFolders_));
    for iImFolder = p.ImFolderIndex
        inFilePaths{1,iImFolder} = accumulationOutFilePaths; % use .mat files as input
    end
    allInFilePaths{1,iImD} = inFilePaths;

    % % logging output paths. - It is a ImL process, no need to create ImDs level folders
    % imageOutputDirectory = fullfile(imageData.outputDirectory_, packageOutputName, processOutputName);
    % mkClrDir(imageOutputDirectory);
    % outFilePaths = cell(2, numel(imageData.imFolders_));
    % for iImFolder = p.ImFolderIndex
    %     outFilePaths{1,iImFolder} = [imageOutputDirectory filesep 'ch' num2str(iImFolder)]; % save image output per chan
    %     outFilePaths{2,iImFolder} = imageOutputDirectory; % save .mat files for all channels
    %     mkClrDir(outFilePaths{1,iImFolder}); % no need to do mkClrDir(outFilePaths{2,iImFolder}) here.
    % end
    % allOutFilePaths{1,iImD} = outFilePaths;
end

% logging output paths - adding ImL outputdir to allOutFilePaths
allOutFilePaths{1,1} = p.OutputDirectory;
mkClrDir(allOutFilePaths{1,1});

% logging input/output paths on the ImL level.
thisProc.setInFilePaths(allInFilePaths);
thisProc.setOutFilePaths(allOutFilePaths);


%% Algorithm
% Package process mapping:
% Process 6 FishStatsAnalysisProcess wraps module 7 from
% scriptFishAtlas4Jenny_QZ.m: module 7: Statistical Analysis
%% module 7: Statistical Analysis: analysis across condtions
% QZ this module requires manual clicking! and took 5min for 2 conditions.
% this module runs at the imageList level,
% this module contains
% 1) load the variables from all conditions(imageData) that are necessary as inputs for this module including reference image, point patterns,fishIDs
% 2) choose the sharpest reference image (QZ: from module 4, proc 3 FishRegistrationProcess) across all conditions and used it
% as fixed image for registration
% 3) registration across the reference image of conditions if necessary & update the point pattern coordinate for new reference image
% visualization of the point pattern and overlay of registred reference image
% 4)
%
% I kept the algorithm most unchanged, just change the way how ImL handles params and input/output paths.. - QZ


% First, take care all the parameters. - QZ
params.Reg = fishRegProcessingProc.funParams_; % Hanieh used the refImage from fishRegProcessingProc in this step
p.Reg = p; % QZ this includes all funParams, the unrelated, such as statType params, will not be used. Use separate p.Reg for this proc, rather than use the same as fishRegProcessingProc.
p.statType = p; % QZ this includes all funParams, the unrelated, such as Reg params, will not be used.


% Derive p.cellConditions condition names from each ImageData's first image folder path. 
% QZ. this is how Hanieh coded, may be not ideal for long condition folder name.
p.cellConditions = cell(1, numImDs);
p.conditionDirectories = cell(1, numImDs);
for iImD = imageDataIndex
    imageData = ImDs{1, iImD};
    imFolderPath = imageData.imFolders_(p.ImFolderIndex(1)).imFolderPath_;
    [conditionDir, ~] = fileparts(imFolderPath); % .../CHLA9/ch1 -> .../CHLA9
    [~, conditionName] = fileparts(conditionDir); % .../CHLA9 -> CHLA9

    p.cellConditions{1, iImD} = conditionName;
    p.conditionDirectories{1, iImD} = conditionDir; % extra param added - QZ
end

p.dataInfo.saveDirectory = p.OutputDirectory;
nMark = p.nMark; % QZ added param.


tic
% step 7-1: reload the necessary features from each conditions (imageData)
for iImageData = imageDataIndex
    %load the parameters for each condition (or it should be the
    % ImageDataPath = params.dataInfo.savedirectory; % that is saved for
    % each imageData
    % ImageDataPath = [p.dataInfo.fileDirectory filesep p.cellConditions{iImageData} filesep 'Result_RefImage'];
    % load(fullfile(ImageDataPath,'params.mat'));

    % % load refimage for each population
    % RefImage{iImageData} = tiffreadVolume(params.Reg.RefImagePath); % QZ: Hanieh used params.Reg from module 4 (proc3)
    %load refimage for each population from its own registration output - QZ bug fixed for Hanieh.
    fishRegOutFilePaths = fishRegProcessingProc.outFilePaths_{1,iImageData};
    refImagePath = fullfile(fishRegOutFilePaths{3,p.ImFolderIndex(1)}, 'RefImage.tif');
    if exist(refImagePath, 'file') ~= 2
        error('FishRegistrationProcess output RefImage.tif was not found for ImageData %d: %s', iImageData, refImagePath);
    end
    RefImage{iImageData} = tiffreadVolume(refImagePath);

    %load accumulated points and corresponding features: area and fishID
    % AccumulatedPath = [ImageDataPath filesep 'Accumulation'];
    inFilePaths = allInFilePaths{1,iImageData};
    AccumulatedPath = inFilePaths{1,p.ImFolderIndex(1)};

    load(fullfile(AccumulatedPath,'pointPattern.mat'))
    pointPatternTotal{iImageData} = pointCoodIn;
    fishID{iImageData} = fishIDsIn;
    pointArea{iImageData} = weightPointsIn;
    clear pointCoodIn fishIDsIn weightPointsIn
end

% step 7-2: find the best reference image within imageData
for iImageData = imageDataIndex
    [~,  blurredFlag sharpness(iImageData)]= discardBlurredImages(RefImage{iImageData});
end
[~, p.RefImageID] = max(sharpness);

% step 7-3: register all refernece image of imageDatas with the best one
savePath = [p.dataInfo.saveDirectory filesep 'Registration'];
mkdir(savePath)

fixed = RefImage{p.RefImageID};
%intialize before for loop
tformRigidReg =[];
rigidImage = [];
nonRigidImage = [];
dispField_demon = [];
similarity_nonrigid = [];

dispField = cell(1, numel(imageDataIndex)); % QZ initialize it to avoid later save error.

for iImageData = imageDataIndex
    %skip the registeration for fixed image
    moving = RefImage{iImageData};

    %check if the RefImages are similar
    if iImageData == p.RefImageID ||  isequal(fixed, moving)
        RefImage_updated{iImageData} = RefImage{iImageData};
        pointPattern_updated{iImageData} = pointPatternTotal{iImageData};
        continue
    end

    %rigid registration
    [optimizer, metric] = imregconfig(p.Reg.Rigid.regmodel);
    optimizer.MaximumIterations = p.Reg.Rigid.maxIter;
    if strcmp(p.Reg.Rigid.regmodel , 'monomodal')
        optimizer.MaximumStepLength = optimizer.MaximumStepLength/ 5; % smaller Radius helped for optimization process (Felix /3.5)
    end
    tform = imregtform(moving,fixed,p.Reg.Rigid.tformType,optimizer,metric);
    [rigidImage{iImageData} ]= imwarp(moving,tform,'OutputView',imref2d(size(fixed))); % by using the imref2d(fixed) you imresize the image too
    tformRigidReg{iImageData} = tform;

    % do the nonrigid Registerations in both methods and see which one is
    % better - sometimes one is better than the other.
    %using demon's method
    [dispFieldD{iImageData},nonRigidImageD{iImageData}] = imregdemons(rigidImage{iImageData},fixed,...
        p.Reg.nonRigid.maxIter, 'PyramidLevels', p.Reg.nonRigid.NumPyramidLevels,...
        'AccumulatedFieldSmoothing',p.Reg.nonRigid.AccumulatedFieldSmoothing);

    %using deform method
    [dispFieldF{iImageData},nonRigidImageF{iImageData}] = imregdeform(rigidImage{iImageData},fixed, ...
        GridRegularization=p.Reg.nonRigid.GridRegularization,NumPyramidLevels = p.Reg.nonRigid.NumPyramidLevels);

    % now compare which one is similar to refimage
    [similarity(1) ] = discardNonRegImages(fixed, nonRigidImageD{iImageData},p.Reg.nonRigid.FilterMetric);
    [similarity(2) ] = discardNonRegImages(fixed, nonRigidImageF{iImageData},p.Reg.nonRigid.FilterMetric);

    if max(similarity) < p.Reg.nonRigid.FilterThreshold
        warning(['optimize the parameter for this condition = ' p.cellConditions{iImageData}]);
    end
    if similarity(1) >= similarity(2)
        nonRigidImage{iImageData} = nonRigidImageD{iImageData};
        dispField{iImageData} = dispFieldD{iImageData};
        p.Reg.nonRigid.method{iImageData} = 'demon';
    else
        nonRigidImage{iImageData} = nonRigidImageF{iImageData};
        dispField{iImageData} = dispFieldF{iImageData};
        p.Reg.nonRigid.method{iImageData} = 'deform';

    end

    %mapping the point patterns for each
    [rigidCoord{iImageData}, nonRigidCoord{iImageData}] = transformPointsWithField (pointPatternTotal{iImageData}, tformRigidReg{iImageData},dispField{iImageData});
    pointPattern_updated{iImageData} = nonRigidCoord{iImageData};
    RefImage_updated{iImageData} = nonRigidImage{iImageData};
    similarity_nonrigid{iImageData} = similarity;
end

save(fullfile(savePath, ['RegisteredRefImgs.mat']), 'tformRigidReg',...
    'rigidImage', 'nonRigidImage','dispField','similarity_nonrigid', ...
    'RefImage','RefImage_updated','pointPattern_updated', 'fishID', 'pointArea')

%visualize overlay of each reference image with the final reference image
for iImageData = imageDataIndex
    % refrence Image of each condition on final refimage
    C = imfuse(RefImage_updated{p.RefImageID},RefImage_updated{iImageData});
    figure('Visible','Off');
    imshow(C,[0 30])
    text(50,50, [p.cellConditions{p.RefImageID} '-' p.cellConditions{iImageData}],'Color','y');
    pause(1)
    saveas(gcf,fullfile(savePath,['OverlayRefImages_' p.cellConditions{iImageData} '.png']))
end

%visualize accumulator of each condition on final reference image
savePath = [p.dataInfo.saveDirectory filesep 'pointPattern'];
mkdir(savePath)
C = [0.9290    0.6940    0.1250]; % yellow

for iImageData = imageDataIndex
    pointPatterntmp = pointPattern_updated{iImageData};
    figure;
    imshow(RefImage_updated{p.RefImageID},[0 100]);
    hold on
    plot(pointPatterntmp(:,1), pointPatterntmp(:,2),'.','Color',C,'MarkerSize',  10)
    saveas(gcf, fullfile(savePath, ['pointsOnRefImg1UniversalYellow' p.cellConditions{iImageData} '.png']));

end

%visualize point pattern of single fish at the final reference image
if     p.Reg.VisPointRefImageFish
for iImageData = imageDataIndex
    savePath = [p.dataInfo.saveDirectory filesep char(p.cellConditions{iImageData}) ''];
    mkdir(savePath);
    FishList = unique(fishID{iImageData});
    % FishList = fileLists{iImageData}; % QZ fileLists is not defined, use the line above.
    X = pointPattern_updated{iImageData};
    for iFish = 1: length(FishList)
        s = sprintf('pointtOnFish%04d.png',FishList(iFish));
        fishPointInd = find(fishID{iImageData} == FishList(iFish)) ;
        figure('Visible','off')
        imshow(RefImage_updated{p.RefImageID},[0 80]);
        % imshow(255 - RefImage_updated{p.RefImageID},[180 255]);
        hold on
        if ~isempty(fishPointInd)
            plot(X(fishPointInd,1),X(fishPointInd,2),'.r',MarkerSize=16)
        end
        saveas(gcf,fullfile(savePath,s))
        close(gcf)
    end
end
end

% step 7-4: calculate the Neighest neighbor analysis
if p.statType.NN.Flag

savePath = [p.dataInfo.saveDirectory filesep 'NN' filesep 'Num_NN_R' num2str(p.statType.NN.Radius)];
mkdir(savePath);
% load or generate a mask of fish body for edge correction
% edgeCorrfishBodyImageDir ='/project/bioinformatics/Danuser_lab/zebrafish/analysis/Hanieh/fishAtlas/Ingrid/8bitData/testScript/ResultsGroup/NN/Num_NN_R40/EdgeCorrection';
% edgeCorrfishBodyImage = 'maskEdgeCorr.tif';

%generate a msk of fish body
if p.statType.usefishBodyImage
    fishBodyImage = tiffreadVolume(p.statType.fishBodyfilePath);
    imwrite(im2uint8(fishBodyImage),fullfile(p.OutputDirectory, 'fishBodyImage.tif')); % QZ save this fish body mask for following usage, even it was loaded by user.
else
    uiwait(msgbox(['Clicking on the reference image (' num2str(nMark) ' clicks) to make a fish body for edge correction']));
    figure;
    Image2D = RefImage_updated{p.RefImageID};
    imshow(255 - Image2D);
    hold on
%visualize the point patterns to make an image for fish body
    for iImageData = imageDataIndex % QZ bug fixed, changed 1: 6 to imageDataIndex
        P = pointPattern_updated{iImageData};
        plot(P(:,1),P(:,2),'.')

    end
    % run the clicing function to make a mask!
    % nMark = 50; % QZ only need to do once to create fishBodyImage.tif
    markerCoord = [];
    while size(markerCoord,1) ~= nMark
        [xClick, yClick] = ginput(nMark);
        markerCoord = [xClick yClick];
        nSelectedMarks = size(markerCoord,1);
        if nSelectedMarks ~= nMark
            uiwait(errordlg(['Selected ' num2str(nSelectedMarks) ' points, but ' num2str(nMark) ...
                ' points are required. Please re-click all points.'], 'Incorrect Number of Points'));
        end
    end
    markerCoord(end+1,:) = markerCoord(1,:);
    %make a binary image
    fishBodyImage = poly2mask(markerCoord(:,1), markerCoord(:,2), size(Image2D,1), size(Image2D,2));
    imwrite(im2uint8(fishBodyImage),fullfile(p.OutputDirectory, 'fishBodyImage.tif'));
end

sizeImage = size(fishBodyImage);
for iImageData = imageDataIndex
    pointPattern = pointPattern_updated{iImageData};
    figure('Visible', 'off');
    [NN_idx{iImageData} NN_dist{iImageData}  NN_img{iImageData},IMAGE{iImageData}] = computeNNMetric(pointPattern,pointPattern,...
        'Radius',p.statType.NN.Radius,'image_size',sizeImage,'figureFlag', 1);
    savename = ['NN_' p.cellConditions{iImageData} '.tif']
    imwrite(im2uint8(NN_img{iImageData}),fullfile(savePath,savename));
    % correct for the edge
    inside = countPixelsMultiCircle(fishBodyImage, pointPattern, p.statType.NN.Radius);
    % assign the score based on the number of nearest neighbor within given
    % radius
    score = cellfun(@length, NN_idx{iImageData}) - 1; % the first nn is itself
    score = round(score./inside.ratio);
    NN_score{iImageData} = score;
end
% save(fullfile(savePath ,['NNDistSigma' num2str(p.NN.Sigma) '.mat'] ),'NN_dist','NN_idx','NN_img','IMAGE','NN_score')
save(fullfile(savePath ,['NNDistSigmaDefault' '.mat'] ),'NN_dist','NN_idx','NN_img','IMAGE','NN_score')
end

% step 7-5: continue the NN analysis and quantify the class of each points
% beased on the local density/ number of NN
savePath2 = [savePath filesep 'NN_cluster'];
mkdir(savePath2);
for iImageData = imageDataIndex
    condType = p.cellConditions{iImageData}; % select a condition
    pointPattern = pointPattern_updated{iImageData}; % select the point patterns
    score = NN_score{iImageData}; % score based on the NN within defined radius for each point
    nfish = length (unique(fishID{iImageData})); % extract the fish IDs for condition
    %generate a colorful plot to visualize the NN classes
    figure ('Visible','off');
    plot(pointPattern(:,1),pointPattern(:,2),'.k')
    axis equal
    hold on
    for iThresh = 1: length(p.statType.NN.densityBin)
        if iThresh == 1
            ind = score <= p.statType.NN.densityBin(iThresh);
        else
            ind = score <= p.statType.NN.densityBin(iThresh) & score > p.statType.NN.densityBin(iThresh -1);
        end
        ind = find(ind > 0 );

        plot(pointPattern(ind,1),pointPattern(ind,2),'o')
        clusterDensity(iThresh,1) = length(ind);
    end
    dataType = string(p.statType.NN.densityBin);
    dataType = cellstr(dataType);
    dataType = [{'All'}, dataType];
    legend(dataType,'Location','southeast');
    set(gcf, 'Position', [100 100 900 350]);
    title(['Point Pattern ' condType]);
    set(gca, 'YDir', 'reverse');
    xlim([0 sizeImage(2)]);% QZ bug fixed, change ImageSize to sizeImage
    ylim([0 sizeImage(1)]);% QZ bug fixed, change ImageSize to sizeImage
    saveas(gcf, fullfile(savePath2,['NN_num' condType '.png']));
    clusterPop(:,iImageData) = clusterDensity;
end

% generate a heatmap for the cluster classes.
colNames = p.cellConditions;
rowNames = cellstr(string(p.statType.NN.densityBin));
% clusterPopTable = table(clusterPop(:,1), clusterPop(:,2),clusterPop(:,1), clusterPop(:,2),...
%     clusterPop(:,1), clusterPop(:,2), 'VariableNames', colNames,'RowNames', rowNames)
clusterPopTable = array2table(clusterPop, 'VariableNames', colNames,'RowNames', rowNames); % QZ Debug to make sure table works for any num of ImDs

save(fullfile(savePath2,'NN_numDensity.mat'),'clusterPop', 'clusterPopTable')
figure ('Visible','off');
xvalues = p.cellConditions;
yvalues = string(p.statType.NN.densityBin);
yvalues = cellstr(yvalues);
h = heatmap(xvalues,yvalues,clusterPop);
title('Cluster Population ')
saveas(gcf,fullfile(savePath2,'ClusterPop.png'))
clusterPop_norm = clusterPop ./ sum(clusterPop,1).*100;
figure;
xvalues = p.cellConditions;
yvalues = string(p.statType.NN.densityBin);
yvalues = cellstr(yvalues);
h = heatmap(xvalues,yvalues,clusterPop_norm);
title('Cluster Population in %')
saveas(gcf,fullfile(savePath2,'ClusterPopPercent.png'))


% step 7-6: measuing top rank region based on the similar sample of each
% condition
if p.statType.TopRankRegion.Flag
    % p.statType.TopRankRegion.densityBin = [1 10 50 100 150]; % QZ comment this out, so GUI value is not over written
    savePath = [p.dataInfo.saveDirectory filesep 'TopRanked_' num2str(p.statType.TopRankRegion.DownSampleNFish) ];
    mkdir(savePath);

    % load or generate a fish body fishBodyImage to correct the NN for
    % points at the border %generate a msk of fish body
    if isfile(fullfile(p.OutputDirectory, 'fishBodyImage.tif'))
        fishBodyImage = tiffreadVolume((fullfile(p.OutputDirectory, 'fishBodyImage.tif')));
    else
        uiwait(msgbox(['Clicking on the reference image (' num2str(nMark) ' clicks) to make a fish body for edge correction']));
        figure;
        Image2D = RefImage_updated{p.RefImageID};
        imshow(255 - Image2D);
        hold on
        %visualize the point patterns to make an image for fish body
        for iImageData = imageDataIndex
            P = pointPattern_updated{iImageData};
            plot(P(:,1),P(:,2),'.')

        end
        % run the clicing function to make a mask!
        % nMark = 50;
        markerCoord = [];
        while size(markerCoord,1) ~= nMark
            [xClick, yClick] = ginput(nMark);
            markerCoord = [xClick yClick];
            nSelectedMarks = size(markerCoord,1);
            if nSelectedMarks ~= nMark
                uiwait(errordlg(['Selected ' num2str(nSelectedMarks) ' points, but ' num2str(nMark) ...
                    ' points are required. Please re-click all points.'], 'Incorrect Number of Points'));
            end
        end
        markerCoord(end+1,:) = markerCoord(1,:);
        %make a binary image
        fishBodyImage = poly2mask(markerCoord(:,1), markerCoord(:,2), size(Image2D,1), size(Image2D,2));
        imwrite(im2uint8(fishBodyImage),fullfile(p.OutputDirectory, 'fishBodyImage.tif'));
    end

    sizeImage = size(fishBodyImage);
    for iRun = 1: p.statType.TopRankRegion.randSelection
        savePath2 = [savePath filesep 'Run' num2str(iRun)];
        mkdir(savePath2);
        for iImageData = imageDataIndex
            condType = p.cellConditions{iImageData};

            % choose random fish for downsampling
            fishID_cond = fishID{iImageData};
            fishID_vec = unique(fishID_cond);
            % randFishID = randperm(length(fishID_vec), p.statType.TopRankRegion.DownSampleNFish); 
            % QZ below 2 lines to Cap sample size for small test conditions.
            nDownSampleFish = min(length(fishID_vec), p.statType.TopRankRegion.DownSampleNFish);
            randFishID = randperm(length(fishID_vec), nDownSampleFish);

            randFishID = fishID_vec(randFishID);
            pointPattern = pointPattern_updated{iImageData};

            %create a new point pattern
            ind = find(ismember(fishID_cond,randFishID));
            pointPattern = pointPattern(ind,:);

            [NN_idx{iImageData} NN_dist{iImageData}  NN_img{iImageData},IMAGE{iImageData}] = computeNNMetric(pointPattern,pointPattern,...
                'Radius',p.statType.TopRankRegion.Radius,'image_size',sizeImage,'figureFlag', 1);


            % correct for the edge
            inside = countPixelsMultiCircle(fishBodyImage, pointPattern, p.statType.TopRankRegion.Radius);
            score = cellfun(@length, NN_idx{iImageData}) - 1;
            score = round(score./inside.ratio);
            NN_score{iImageData} = score;
            hFig = figure;
            plot(pointPattern(:,1),pointPattern(:,2),'.k')
            axis equal
            hold on
            for iThresh = 1: length(p.statType.TopRankRegion.densityBin)
                if iThresh == 1
                    ind = score <= p.statType.TopRankRegion.densityBin(iThresh);
                else
                    ind = score <= p.statType.TopRankRegion.densityBin(iThresh) & score > p.statType.TopRankRegion.densityBin(iThresh -1);
                end
                ind = find(ind > 0 );

                plot(pointPattern(ind,1),pointPattern(ind,2),'o')
                clusterDensity(iThresh,1) = length(ind);
            end
            dataType = string(p.statType.TopRankRegion.densityBin);
            dataType = cellstr(dataType);
            dataType = [{'All'}, dataType];
            legend(dataType,'Location','southeast');
            set(hFig, 'Position', [100 100 900 350]);
            title(['Point Pattern ' condType]);
            set(gca, 'YDir', 'reverse');
            xlim([0 sizeImage(2)]); % QZ bug fixed, change ImageSize to sizeImage
            ylim([0 sizeImage(1)]); % QZ bug fixed, change ImageSize to sizeImage
            saveas(hFig, fullfile(savePath2,['NN_num' condType '.png'])); % QZ bug fixed to change savePath3 to 2
            close(hFig)
            clusterPop(:,iImageData, iRun) = clusterDensity;
            randFishIDTotal{iImageData} = randFishID;
            randPointPatternTotal{iImageData} = pointPattern;

        end
        %saving all variables for topranked analysis in this random run
        save(fullfile(savePath2,'NN_numDensity.mat'),'clusterPop', 'randFishIDTotal','randPointPatternTotal','NN_score',...
            'NN_idx' ,'NN_dist' ,'NN_img' ,'IMAGE')
    end
    % saving the population density for all random downsampling selection
    save(fullfile(savePath,'NN_numDensity.mat'),'clusterPop')
end

% create the top ranked regions for vasculature image of reference image
% using the overlapped regions across nRun times of random downsampling
% selection:
%set a seperate save directory
savePath2 = [savePath filesep 'AllRuns' filesep 'EnrichedRegion_' num2str(p.statType.TopRankRegion.Radius)];
mkdir(savePath2);

%generate the top ranked image across each condition:
for iImageData = imageDataIndex

    % for a single class of population, we choose the overlapped regions
    % across the random selection
    for iThresh = 1:length(p.statType.TopRankRegion.densityBin)
        % initialize a image mask for all run for each threshold and each
        % condition:
        Imagemask_All = nan([size(RefImage_updated{p.RefImageID}), p.statType.TopRankRegion.randSelection]);

        for iRun = 1: p.statType.TopRankRegion.randSelection
            %set the path for each run
            RunPath = [savePath filesep 'Run' num2str(iRun)];
            %load NN_score & pointpattern coordinate for each random
            %selected downsample run
            load(fullfile(RunPath, 'NN_numDensity.mat'));
            pointPattern = pointPattern_updated{iImageData};
            randFishID = randFishIDTotal{iImageData};
            fishIDAllpoint = fishID{iImageData};
            Ind_randpoint = find(ismember(fishIDAllpoint, randFishID));
            %find the point pattern coordinate for the downsample dataset
            %(fish)
            pointPattern = pointPattern(Ind_randpoint,:);

            % select score for this round of random selection
            score = NN_score{iImageData};
            %find the pixel of the selected point pattern in the reference
            %image
            Ind_points = sub2ind(size(RefImage_updated{p.RefImageID}),round(pointPattern(:,2)), round(pointPattern(:,1)));

            % create an image of all points
            condType = p.cellConditions{iImageData};
            Imagemask = nan(size(RefImage_updated{p.RefImageID}));
            Imagemask(Ind_points) = score;

            if iThresh ==1
                minThresh = 0;
                maxThresh = p.statType.TopRankRegion.densityBin(iThresh);

                Imagemask (Imagemask > maxThresh) = nan;

            else
                minThresh = p.statType.TopRankRegion.densityBin(iThresh-1);
                maxThresh = p.statType.TopRankRegion.densityBin(iThresh);

                Imagemask (Imagemask > maxThresh) = nan;
                Imagemask (Imagemask <= minThresh) = nan;

            end

            Imagemask(~isnan (Imagemask )) = 1;
            Imagemask (isnan(Imagemask)) = 0;
            se = strel('disk', p.statType.TopRankRegion.Radius);           % structuring element of radius 40
            Imagemask = imdilate(Imagemask, se);

            % now I need to define a new Imagemask that incorporates all
            % nRun I did in 3D to save data
            Imagemask_All(:,:,iRun) = Imagemask;

        end
        % define the threshold for the overlapped regions
        threshold = p.statType.TopRankRegion.overlapCutoff .* p.statType.TopRankRegion.randSelection;
        % add all the imagemask_All in an image
        Imagemask = sum(Imagemask_All,3);
        %create a new mask Image based on what needed for random selection
        Imagemask (Imagemask <threshold) = 0;
        Imagemask (Imagemask > 0) = 1;

        hFig = figure('Visible', 'off');
        imshow(1 - Imagemask)
        saveas(hFig,fullfile(savePath2, [condType 'Threshmax_' num2str(maxThresh) '.png']));
        close(hFig)
        perim = bwperim(Imagemask);
        inside_border = Imagemask & imdilate(perim, ones(10));
        hFig = figure;
        imshow(1-inside_border);
        saveas(hFig,fullfile(savePath2, [ 'Border' condType 'Threshmax_' num2str(maxThresh) '.png']));


        imshow(Imagemask.* single(RefImage{p.RefImageID}))

        saveas(hFig,fullfile(savePath2, [condType 'RefImg_Threshmax_' num2str(maxThresh) '.png']));
        saveas(hFig,fullfile(savePath2, [condType 'RefImg_Threshmax_' num2str(maxThresh) '.eps']),'epsc');
        close(hFig)
        hFig = figure;
        imshow(255 - Imagemask.* single(RefImage{p.RefImageID}),[-0 255])
        saveas(hFig,fullfile(savePath2, [condType 'RefImg_Threshmax_' num2str(maxThresh) '.tif']));
        close(hFig)
        save(fullfile(savePath2, [condType 'ImagemaskAll_Threshmax_' num2str(maxThresh) '.mat' ]),'Imagemask_All','Imagemask')
    end
end


% step 7-7: Dispersion pvalue of randomness versus, isolated, versus
% clustered:
if p.statType.Dispersion.Flag
    savePath = [p.dataInfo.saveDirectory filesep 'Dispersion'];
    if ~isdir(savePath) mkdir(savePath); end

    % calculate the pvalue to recognize if the point is clustered or
    % isolated or similar to random distribution behavior --> metric is
    % using NN

    % load the fishBody for edge correction
    if isfile(fullfile(p.OutputDirectory, 'fishBodyImage.tif'))
        fishBodyImage = tiffreadVolume(fullfile(p.OutputDirectory, 'fishBodyImage.tif'));
    else
        uiwait(msgbox(['Clicking on the reference image (' num2str(nMark) ' clicks) to make a fish body for edge correction']));
        figure;
        Image2D = RefImage_updated{p.RefImageID};
        imshow(255 - Image2D);
        hold on
        %visualize the point patterns to make an image for fish body
        for iImageData = imageDataIndex
            P = pointPattern_updated{iImageData};
            plot(P(:,1),P(:,2),'.')

        end
        % run the clicing function to make a mask!
        % nMark = 50;
        markerCoord = [];
        while size(markerCoord,1) ~= nMark
            [xClick, yClick] = ginput(nMark);
            markerCoord = [xClick yClick];
            nSelectedMarks = size(markerCoord,1);
            if nSelectedMarks ~= nMark
                uiwait(errordlg(['Selected ' num2str(nSelectedMarks) ' points, but ' num2str(nMark) ...
                    ' points are required. Please re-click all points.'], 'Incorrect Number of Points'));
            end
        end
        markerCoord(end+1,:) = markerCoord(1,:);
        %make a binary image
        fishBodyImage = poly2mask(markerCoord(:,1), markerCoord(:,2), size(Image2D,1), size(Image2D,2));
        imwrite(im2uint8(fishBodyImage),fullfile(p.OutputDirectory, 'fishBodyImage.tif'));
    end

    sizeImage = size(fishBodyImage);


    for iImageData = imageDataIndex
        pointPattern = pointPattern_updated{iImageData};
        nPoint = size(pointPattern,1);

        %find all possible points (pixels) in masked image
        Ind = find(fishBodyImage);
        clear NN_idx_rnd null_counts
        for iRun = 1: p.statType.Dispersion.randNum
            rndInd = randperm(length(Ind), nPoint)';  % choose nPoint in the pixels of fishBody image
            rndPoint = Ind(rndInd);
            [rndRow rndCol] = ind2sub(size(fishBodyImage),rndPoint);

            % plot(rndCol,rndRow , '.g'); pause(0.5)  % for visualization

            % calculate the NN_num for the random point
            pointPatternRand = [rndCol , rndRow];
            [NN_idx_rnd] = computeNNMetric(pointPatternRand,pointPatternRand,'Radius',p.statType.Dispersion.Radius,'image_size',size(RefImage{p.RefImageID }));

            % correct for the edge for the random poistion
            inside = countPixelsMultiCircle(fishBodyImage, pointPatternRand, p.statType.Dispersion.Radius); % QZ bug fixed, before it was p.statType.Dispersion.randNum
            score_tmp = cellfun(@length, NN_idx_rnd) - 1; % define the score for each random point based on the NN in this radius
            score_tmp = round(score_tmp./inside.ratio);

            null_counts (:,iRun ) = score_tmp;
        end
        score_rnd{iImageData} = null_counts;

        %calculate the NN for the original point
        [NN_idx{iImageData}] = computeNNMetric(pointPattern,pointPattern,'Radius',p.statType.Dispersion.Radius,'image_size',size(RefImage{p.RefImageID }));

        % correct for points at the edge in original point
        inside = countPixelsMultiCircle(fishBodyImage, pointPattern, p.statType.NN.Radius);
        NN_score{iImageData} = cellfun(@length, NN_idx{iImageData}) - 1;
        NN_score{iImageData} = round(NN_score{iImageData}./inside.ratio);
        n_obs = NN_score{iImageData};

        % makes the nan in n_obs zero because it could be outlier 0/0 in
        % edge correction can cause NaN
        n_obs(find(isnan(n_obs))) = 0; % they have zero NN_num
        null_flat = null_counts(:);

        % Z-score - define the mean of the null_flat for the random points
        mu = mean(null_flat);
        sigma = std(null_flat);
        zscore = (n_obs - mu) / sigma;

        % p-values for each point
        pvals = nan(nPoint, 1); % for clustered points
        pvals_2 = nan(nPoint, 1); % for isolated points

        % define the pvalue based on the right or left side of the
        % distribution of NN from random points
        for i = 1:nPoint
            if n_obs(i) < mu; %isolated
                pvals_2(i) = sum(null_flat <= n_obs(i)) / numel(null_flat);
            else % clustered
                pvals(i) = sum(null_flat >= n_obs(i)) / numel(null_flat);
            end
        end

        figure ('Visible', 'off');
        plot(pointPattern(:,1),pointPattern (:,2),'.','MarkerSize',8)

        hold on
        ind = find(pvals <= 0.05);
        plot(pointPattern(ind,1),pointPattern (ind,2),'.','MarkerSize',12);

        ind = find(pvals_2 <= 0.05);
        plot(pointPattern(ind,1),pointPattern (ind,2),'.','MarkerSize',12);
        axis equal

        xlim([0 sizeImage(2)]) % QZ bug fixed, change SZ to sizeImage
        ylim([0 sizeImage(1)]) % QZ bug fixed, change SZ to sizeImage
        set(gca,'YDir','reverse')
        set(gcf,'Position',[50 50  1000 400 ])

        savename = [p.cellConditions{iImageData}  '.png'];
        saveas(gcf, fullfile(savePath, savename))
        savename = [p.cellConditions{iImageData}  '.eps'];
        saveas(gcf, fullfile(savePath , savename),'epsc')
        pvalTotal{iImageData,1} = pvals;
        pvalTotal{iImageData,2} = pvals_2;
        nObsTotal{iImageData} = n_obs;
        nullFlatTotal{iImageData} = null_flat;
    end

    save(fullfile(savePath, 'pvalue_Random.mat'), 'pvalTotal','nObsTotal','nullFlatTotal')

end

%step 7-8: manual regions and enrichment in this region
% create a manual region and do the random distribution and check whether
% the region is enriched or not for that condtion.
if p.statType.ManualRegion.Flag
savePath = [p.dataInfo.saveDirectory filesep 'ManualEnrichedRegion'];
if ~isdir(savePath) mkdir(savePath); end

% load/generate the fishBody image for edge correction
if isfile(fullfile(p.OutputDirectory, 'fishBodyImage.tif'))
    fishBodyImage = tiffreadVolume(fullfile(p.OutputDirectory, 'fishBodyImage.tif'));
else
    uiwait(msgbox(['Clicking on the reference image (' num2str(nMark) ' clicks) to make a fish body for edge correction']));
    figure;
    Image2D = RefImage_updated{p.RefImageID};
    imshow(255 - Image2D);
    hold on
    %visualize the point patterns to make an image for fish body
    for iImageData = imageDataIndex
        P = pointPattern_updated{iImageData};
        plot(P(:,1),P(:,2),'.')

    end
    % run the clicing function to make a mask!
    % nMark = 50;
    markerCoord = [];
    while size(markerCoord,1) ~= nMark
        [xClick, yClick] = ginput(nMark);
        markerCoord = [xClick yClick];
        nSelectedMarks = size(markerCoord,1);
        if nSelectedMarks ~= nMark
            uiwait(errordlg(['Selected ' num2str(nSelectedMarks) ' points, but ' num2str(nMark) ...
                ' points are required. Please re-click all points.'], 'Incorrect Number of Points'));
        end
    end
    markerCoord(end+1,:) = markerCoord(1,:);
    %make a binary image
    fishBodyImage = poly2mask(markerCoord(:,1), markerCoord(:,2), size(Image2D,1), size(Image2D,2));
    imwrite(im2uint8(fishBodyImage),fullfile(p.OutputDirectory, 'fishBodyImage.tif'));
end

sizeImage = size(fishBodyImage);

% load the masked image, if not, create a new one
Image2D = RefImage_updated{p.RefImageID}; % load the reference image to generate a mask on it % QZ bug fixed, move this outside of if loop.
if p.statType.ManualRegion.useRegionMask
    maskedImage = tiffreadVolume(p.statType.ManualRegion.fishBodyImagePath); % load from GUI
else
    uiwait(msgbox(['Click ', num2str(p.statType.ManualRegion.nMark), ...
    ' points around the manual region boundary for enrichment analysis.'])); % QZ I add this for clear instruction.
    [maskedImage ] = createMaskByHand(Image2D, p.statType.ManualRegion.nMark);
    imwrite(im2uint8(maskedImage),fullfile(savePath, 'Region.tif'))
end

%generate a outline of the masked image for visualization
B = bwperim(maskedImage);
B = imdilate(B, ones(8));
figure; C = imfuse(B, Image2D ); imshow(C)
imwrite(im2uint8(C),fullfile(savePath,['Border_' 'Region.tif']))

for iImageData = imageDataIndex
    pointPattern = pointPattern_updated{iImageData};
    % check if points are in the enriched region
    Ind_point = sub2ind(sizeImage, round(pointPattern(:,2)), round(pointPattern(:,1)));
    value_point = maskedImage(Ind_point);
    maskedPop(iImageData, 1) = length(find(value_point));
    figure;
    imshow(maskedImage)
    hold on
    %visualized all points
    plot(pointPattern(:,1),pointPattern(:,2),'.r')
    %visualize points within the region
    Ind = find(value_point);
    plot(pointPattern(Ind,1),pointPattern(Ind,2),'.b')
    fishIDPoint{iImageData} = fishID{iImageData}(Ind);
    saveas(gcf,fullfile(savePath, [p.cellConditions{iImageData} '.png' ]))
    nPoint = size(pointPattern,1);
    % now run the random distribution and check if the masked region are
    % enriched region using the number of points within the region.
    %find all possible points (pixels) in masked image
    Ind = find(fishBodyImage);
    % clear a

    for iTrial = 1: p.statType.ManualRegion.randNum
        % random distribute the points in the fish body mask
        rndInd = randperm(length(Ind), nPoint)';
        rndPoint = Ind(rndInd);
        [rndRow rndCol] = ind2sub(size(fishBodyImage),rndPoint);

        % plot(rndCol,rndRow , '.g') pause(0.5)
        pointPatternRand = [rndCol , rndRow];

        % calculate the nPoint within the manual maskedregions
        Ind_point = sub2ind(sizeImage, round(pointPatternRand(:,2)), round(pointPatternRand(:,1)));
        value_point = maskedImage(Ind_point);

        % make a histogram
        nPoint_rnd(iTrial, 1) = length(find(value_point));
    end
    nPoint_rnd_total{iImageData} = nPoint_rnd;
    % calculate the pvalue, using the right tail for distribution
    pvalue(iImageData,1) = length(find(nPoint_rnd >= maskedPop(iImageData, 1)))/p.statType.ManualRegion.randNum;

    % count the number of points per fish to estimate average and standard
    % deviation within this region
    fishID_InMask = fishIDPoint{iImageData}; % identify the fish that has points in this region
    fishIDVec = unique(fishID{iImageData}); %identify all fish IDs for the condition
    % calculate the number of points per fish within the mask
    for iFish = 1: length(fishIDVec)
        distEnrichedPoint(iFish) = length(find(fishID_InMask == fishIDVec(iFish)));
    end
end
save(fullfile(savePath, 'Population.mat'), 'maskedPop','pvalue','nPoint_rnd_total','fishIDPoint', 'distEnrichedPoint')
end

% step 7-9: making a box grid and report the number of events per region
if p.statType.BoxGrid.Flag

    savePath = [p.dataInfo.saveDirectory filesep 'BoxGrid'];
    if ~isdir(savePath) mkdir(savePath); end

% identify the position of the fish in the image to make a box grid around
% it by defining the corner of the box and make a mask
level = multithresh(RefImage_updated{p.RefImageID})
BinaryRefImage = single(RefImage_updated{p.RefImageID} >= level);


% divide fish body for each condition into a box grid partition
for iImageData = imageDataIndex
    [regions_Coordinates{iImageData}, regions_FishID{iImageData}, regions_ROICorners{iImageData} ...
        ,regions_PointArea{iImageData}] = computeRegionPointFeatures(pointPattern_updated{iImageData},...
        fishID{iImageData},pointArea{iImageData},BinaryRefImage,p.statType.BoxGrid.boxSize, p.statType.BoxGrid.useBoundingFish);
end

% visualize one fish with boxes to make sure it is right
figure;
imshow(RefImage_updated{p.RefImageID},[0 80])
hold on
ROI_corners = regions_ROICorners{p.RefImageID}
e = 10;
for iRegion = 1: length(ROI_corners)
    C = ROI_corners{iRegion};
    plot( [C(2) C(4) C(4) C(2) C(2)],[C(1) C(1) C(3) C(3) C(1)], 'y.-');
    text(C(2), C(1)-e, num2str(iRegion), 'Color', 'cyan' )
end
saveas(gcf, fullfile(savePath, 'regionBoxonFish.png'))

% count features within boxes for each condition
for iImageData = imageDataIndex
    %create a matrix of the numebr of points per region per fish --> used
    %for chord diagram
    [regionMatrixCount{iImageData}  Population{iImageData} PopulationNorm{iImageData} ] = countInRegions(regions_Coordinates{iImageData}, regions_FishID{iImageData}, 1); % QZ bug fixed, added figureFlag = 1
    hFig = gcf;
    savename = ['CountPointsPerFish' p.cellConditions{iImageData} '.png']
    % colorbar
    set(hFig,'Position',[50 50 1950 550])
    saveas(hFig,fullfile(savePath,savename))
    close(hFig)
end

save(fullfile(savePath, ['regionBasedResult_' num2str(p.statType.BoxGrid.boxSize ) '.mat'] ), 'regionMatrixCount', ...
    'PopulationNorm','Population', 'regions_Coordinates','regions_FishID','regions_ROICorners','regions_PointArea')


% step 7-10: find the dominant condition for each  region in pair
% comparison:
if p.statType.BoxGrid.DominantRegionFlag
%visualization
savePath2 = [savePath filesep 'Significant_rankSum'];
if ~isdir(savePath2) mkdir(savePath2); end

nFishTotal = cellfun(@(x) size(x,2), regionMatrixCount);
numFishSampling = min(nFishTotal); %downsampling is based on the lowest number of fish

% redefine the regionMatrixCount to have same number of fish
for iImageData = imageDataIndex
    R_tmp = regionMatrixCount{iImageData};
    ind = randperm(nFishTotal(iImageData),numFishSampling);
    ind = sort(ind)
    regionMatrixCountN{iImageData} = R_tmp(:,ind) ;
    FishID_downsampling{iImageData} = ind;
end

% find if the number of points of A or B conditions are distributed
% significantly or not within regions
for iImageData = imageDataIndex
    for iImageData2 = imageDataIndex
        % define a vector for each region and each fish
        RegionVector1 = regionMatrixCountN{iImageData};
        RegionVector2 = regionMatrixCountN{iImageData2};
        pval_rank = nan(size(RegionVector1,1),1);
        hyp= nan(size(RegionVector1,1),1);
        for iRegion = 1: size(RegionVector1,1)
            d1 = RegionVector1(iRegion,:);
            d2 = RegionVector2(iRegion,:);
            % converting the nan to zero! nan means there is no points in
            % that region.
            d1(isnan(d1)) = 0 ;
            d2(isnan(d2)) = 0 ;
            sum(d1);
            sum(d2);

            [  pval_rank(iRegion,1) hyp(iRegion,1)] = ranksum(d1,d2);

        end
        pval_rank_total{iImageData, iImageData2} = pval_rank;
        hyp_total{iImageData, iImageData2} = hyp;
    end
end

save(fullfile(savePath2, 'pval_ranksum.mat'),'pval_rank_total', 'hyp_total' , 'FishID_downsampling' , 'regionMatrixCountN' )

% visualizing the dominant regions for each pair
for ii = 1:(numel(imageDataIndex)-1)
    iImageData = imageDataIndex(ii);
    for jj = (ii+1):numel(imageDataIndex)
        iImageData2 = imageDataIndex(jj);
        figure;
        imshow(255 - RefImage_updated{p.RefImageID})
        hold on
        ROI_corners = regions_ROICorners{p.RefImageID};
        Ratio = Population{iImageData}./Population{iImageData2};
        RatioNorm = PopulationNorm{iImageData}./PopulationNorm{iImageData2};
        hyp = hyp_total{iImageData, iImageData2};
        RegionID_nonzero1 = find(~isnan(regionMatrixCount{iImageData}(:,1)));
        RegionID_nonzero2 = find(~isnan(regionMatrixCount{iImageData2}(:,1)));
        RegionID_nonzero = union (RegionID_nonzero1,RegionID_nonzero2);
        for iRegion = 1: length(RegionID_nonzero)
            C = ROI_corners{RegionID_nonzero(iRegion)};
            plot( [C(2) C(4) C(4) C(2) C(2)],[C(1) C(1) C(3) C(3) C(1)], 'k--')

            if hyp(RegionID_nonzero(iRegion)) ==0
                scatter(C(2)+10,C(1)+10, 150, 'k', 'filled')
                % text(C(2)+10,C(1)+10,[num2str(RegionID_nonzero(iRegion))],'Color','k','FontSize',14)
            elseif RatioNorm(RegionID_nonzero(iRegion)) > 1
                % text(C(2)+10,C(1)+10,[num2str(RegionID_nonzero(iRegion))],'Color','b','FontSize',14)
                scatter(C(2)+10,C(1)+10, 250, 'r', 'filled')

            else
                % text(C(2)+10,C(1)+10,[num2str(RegionID_nonzero(iRegion))],'Color','m','FontSize',14)
                scatter(C(2)+10,C(1)+10, 250, [0 0.5 0], 'filled')

            end

        end

        pause(1)
        saveas(gcf, fullfile(savePath2, ['CircleNPopulationRatio_' p.cellConditions{iImageData} '_' p.cellConditions{iImageData2} '.png']))
        pause(1)

    end
end


end

if p.statType.BoxGrid.CoOccurenceFlag
    savePath2 = [savePath filesep 'Coexistance'];
    if ~isdir(savePath2) mkdir(savePath2); end
    for iImageData = imageDataIndex
    [RegionMatrix{iImageData} pvalueMatrix{iImageData} RegionID_nonzeroTotal{iImageData}]= regionCorrelation(regions_Coordinates{iImageData}, regions_FishID{iImageData},p.statType.BoxGrid.typeCoExist);

    % %visualize RegionMatrix
    % figure;
    % heatmap(RegionMatrix{iImageData});
    % xlabel('RegionID')
    % ylabel('RegionID')
    % title('Correlation across region')

    % generate non NaN regionMatrix -- regions that have at least one point
    RegionMatrix_eff = RegionMatrix{iImageData};
    RegionMatrix_eff(isnan(RegionMatrix_eff)) = [];
    RegionMatrix_eff = reshape(RegionMatrix_eff, [length(RegionID_nonzeroTotal{iImageData}) length(RegionID_nonzeroTotal{iImageData}) ])
    pvalueMatrix_eff = pvalueMatrix{iImageData};
    pvalueMatrix_eff(isnan(pvalueMatrix_eff)) = [];
    pvalueMatrix_eff = reshape(pvalueMatrix_eff, [length(RegionID_nonzeroTotal{iImageData}) length(RegionID_nonzeroTotal{iImageData}) ])

    hFig = figure('Visible','off');
    h = heatmap(RegionMatrix_eff);
    h.XDisplayLabels = num2cell (RegionID_nonzeroTotal{iImageData});
    h.YDisplayLabels = num2cell (RegionID_nonzeroTotal{iImageData});
    xlabel('RegionID')
    ylabel('RegionID')
    title('Coexistance value across region')
    set(hFig,'Position',[50 50 1000 1000])
    savename = ['CoExist_' p.statType.BoxGrid.typeCoExist '_' p.cellConditions{iImageData} '.png']

    saveas(hFig,fullfile(savePath2,savename))
    close(hFig)

    % remove the diagonal elements for better visualization
    for i = 1:length(RegionMatrix_eff)
        RegionMatrix_eff(i,i) = nan;
        pvalueMatrix_eff(i,i) = nan;
    end

end
 
save(fullfile(savePath2, ['Coexist_' p.statType.BoxGrid.typeCoExist '.mat']),'RegionMatrix','RegionID_nonzeroTotal');
%

% find the threshold automatically using the random distribution for a
% given condition and given boxGrid
if ~isempty(p.statType.BoxGrid.CoexistThresh) || p.statType.BoxGrid.useAutoCoExistThresh
    %use the random distribution for each conditoon with a given box size

    % load/generate the fishBody image for random distribution across fish
    % body
if isfile(fullfile(p.OutputDirectory, 'fishBodyImage.tif'))
    fishBodyImage = tiffreadVolume(fullfile(p.OutputDirectory, 'fishBodyImage.tif'));
else
    uiwait(msgbox(['Clicking on the reference image (' num2str(nMark) ' clicks) to make a fish body for edge correction']));
    figure;
    Image2D = RefImage_updated{p.RefImageID};
    imshow(255 - Image2D);
    hold on
    %visualize the point patterns to make an image for fish body
    for iImageData = imageDataIndex
        P = pointPattern_updated{iImageData};
        plot(P(:,1),P(:,2),'.')

    end
    % run the clicing function to make a mask!
    % nMark = 50;
    markerCoord = [];
    while size(markerCoord,1) ~= nMark
        [xClick, yClick] = ginput(nMark);
        markerCoord = [xClick yClick];
        nSelectedMarks = size(markerCoord,1);
        if nSelectedMarks ~= nMark
            uiwait(errordlg(['Selected ' num2str(nSelectedMarks) ' points, but ' num2str(nMark) ...
                ' points are required. Please re-click all points.'], 'Incorrect Number of Points'));
        end
    end
    markerCoord(end+1,:) = markerCoord(1,:);
    %make a binary image
    fishBodyImage = poly2mask(markerCoord(:,1), markerCoord(:,2), size(Image2D,1), size(Image2D,2));
    imwrite(im2uint8(fishBodyImage),fullfile(p.OutputDirectory, 'fishBodyImage.tif'));
end

% generate random distribution for all conditions given a box grid
for iImageData = imageDataIndex
    condType = p.cellConditions{iImageData};  % choose a condition
    pointPattern = pointPattern_updated{iImageData}; % find the point pattern of the condition

    fishIDtmp = fishID{iImageData};    % fish ID of the condition
    nPoint = size(pointPattern,1);      % number of points for this condition

    R = RegionMatrix{iImageData};    % find the regionmatrix for the condition in given box grid
    A_org = triu(R,1);               % consider the upper diagonal value of the matrix
    maxCorr_org = max(A_org(:));     % find the maximum of the correlation value for the original point pattern

    %pointArea is not needed but just in case to run the function
    pointAreatmp = pointArea{iImageData};

    %find all possible points (pixels) in masked image
    Ind = find(fishBodyImage);
    clear NN_idx_rnd null_counts
    for iRun = 1: p.statType.BoxGrid.CoExistRandNum
        %create random distribution. using the same fish ID is still
        %correct
        rndInd = randperm(length(Ind), nPoint)';
        rndPoint = Ind(rndInd);
        [rndRow rndCol] = ind2sub(size(fishBodyImage),rndPoint);

        % plot(rndCol,rndRow , '.g') pause(0.5)

        pointPatternRand = [rndCol , rndRow];

        % calculate the kendell correlation
        [regions_Coordinatestmp{iRun}, regions_FishIDtmp{iRun}, regions_ROICornerstmp{iRun},regions_PointAreatmp{iRun}] = ...
            computeRegionPointFeatures(pointPatternRand,fishIDtmp,pointAreatmp,BinaryRefImage,p.statType.BoxGrid.boxSize,p.statType.BoxGrid.useBoundingFish)
        [RegionMatrixtmp{iRun} ]= regionCorrelation(regions_Coordinatestmp{iRun}, regions_FishIDtmp{iRun},p.statType.BoxGrid.typeCoExist);


        Corr =  RegionMatrixtmp{iRun};
        A = triu(Corr,1);
        maxCorr(iRun,1)= max(A(:));

        maxCorr(iRun,2)= max(abs(A(:)));
        % maxCorr(iRun,3)= min(A(:));
    end

save(fullfile(savePath2, ['Corr4RandomDist_' condType  '.mat']),'RegionMatrix'  ,'RegionMatrixtmp',...
    'RegionID_nonzeroTotal','regions_Coordinatestmp','regions_FishIDtmp',...
    'regions_ROICornerstmp','maxCorr')
figure('Visible','off');
plot(maxCorr(:,1:2),'.-')
hold on
plot([0 p.statType.BoxGrid.CoExistRandNum],[maxCorr_org maxCorr_org],'--k')

% text(5,0.05,['max org =' num2str(maxCorr_org)])
xlabel('Ran ID')
ylabel('Max Corr')
title(['Jaccard Indenx compared to random distribution', condType])
ylim([0 1])
ave = round(mean(maxCorr(:,1)),2);
STD = round(std(maxCorr(:,1)),2);
text(20, 0.2,[num2str(ave) '+' num2str(STD)])
% set(gcf,"Position",[50 50 700 500])
saveas(gcf,fullfile(savePath2,['maxCorr_' condType  '.png']))
saveas(gcf,fullfile(savePath2,['maxCorr_' condType  '.eps']),'epsc')
p.statType.BoxGrid.CoexistThresh(iImageData) = ave; % define the threshold for each condition based on this random distribution
end

end

% create a chord diagram based on the threshold
for iImageData = imageDataIndex
    groups = RegionID_nonzeroTotal{iImageData};
    RegionMatrix_eff = RegionMatrix{iImageData};
    RegionMatrix_eff(isnan(RegionMatrix_eff)) = [];
    RegionMatrix_eff = reshape(RegionMatrix_eff, [length(RegionID_nonzeroTotal{iImageData}) length(RegionID_nonzeroTotal{iImageData}) ])
    % pvalueMatrix_eff = pvalueMatrix{iImageData};
    % pvalueMatrix_eff(isnan(pvalueMatrix_eff)) = [];
    % pvalueMatrix_eff = reshape(pvalueMatrix_eff, [length(RegionID_nonzeroTotal{iImageData}) length(RegionID_nonzeroTotal{iImageData}) ])

    thresh = p.statType.BoxGrid.CoexistThresh(iImageData);
    connections = makeConnection4ChordDiagram(groups, RegionMatrix_eff, thresh);
    if isempty(connections)
        continue
    end
    connections(:,3) = connections(:,3)* 10;
    connectionsT = array2table(connections);
    chordPlot(groups,connectionsT)
    saveas(gcf, fullfile(savePath2, ['Chord' p.cellConditions{iImageData} 'thresh' num2str(thresh) '.eps']),'epsc')
    saveas(gcf, fullfile(savePath2, ['Chord' p.cellConditions{iImageData} 'thresh' num2str(thresh) '.png']))
    save(fullfile(savePath2, ['Chord' p.cellConditions{iImageData} 'thresh' num2str(thresh) '.mat']),'groups','connectionsT','thresh')

end

end

end


% step 7-10: select a box grid and make a chord digram:
% 1) select a box grid, 2) counting the events per box, 3) calculating the
% interdependency, 4) doing the random distribution and choosing the
% threshold if the threshold is not giving (if the select threshold automatically -- it should run the random distribution)
% 5) creating chord diagram based on the threshold of the
% random distribtution

toc

disp('Finished fish stats analysis!')
