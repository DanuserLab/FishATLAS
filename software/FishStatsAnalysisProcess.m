classdef  FishStatsAnalysisProcess < ImageProcessingProcessImL & NonSingularProcess
    % Process Class for FishATLAS statistics analysis
    % fishStatsAnalysisWrap.m is the wrapper function
    % FishStatsAnalysisProcess is part of new FishATLAS Package
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

    methods (Access = public)
        function obj = FishStatsAnalysisProcess(owner, varargin)

            if nargin == 0
                super_args = {};
            else
                % Input check
                ip = inputParser;
                ip.CaseSensitive = false;
                ip.KeepUnmatched = true;
                ip.addRequired('owner',@(x) isa(x,'ImageList'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.addOptional('funParams',[],@isstruct);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                funParams = ip.Results.funParams;

				% Define arguments for superclass constructor
                super_args{1} = owner;
                super_args{2} = FishStatsAnalysisProcess.getName;
                super_args{3} = @fishStatsAnalysisWrap;
                if isempty(funParams)
                    funParams = FishStatsAnalysisProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@ImageProcessingProcessImL(super_args{:});
            obj.is3Dcompatible_ = false; % outputs are 2D
        end


    end

    methods (Static)
        function name = getName()
            name = 'Statistical Analysis';
        end

        function h = GUI(varargin)
            h = @FishStatsAnalysisProcessGUI;
        end

        function funParams = getDefaultParams(owner, varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'ImageList'));
            ip.addOptional('outputDir', owner.outputDirectory_, @ischar);
            ip.parse(owner, varargin{:})
            outputDir = ip.Results.outputDir;

            % Set default parameters
            images = owner.getImages(1);
            sampleImD = images{1};
            funParams.ImageDataIndex = 1:owner.getSize();
            funParams.ImFolderIndex = 1:numel(sampleImD.imFolders_);
            funParams.OutputDirectory = [outputDir  filesep 'StatsAnalysis'];
            funParams.ProcessIndex = []; % can use this parameter to set which previous process's output to be used as input for this process


            % QZ: Hanieh want to use diff reg params rather than use from FishRegistrationProcess. I did so.
            % Default p.Reg are almost the same as FishRegistrationProcess, except:
            % nonRigid.FilterThreshold is 0.82 and nonRigid.FilterMetric is 'corrCross' in FishRegistrationProcess
            % In FishRegistrationProcess, the params are p.Reg.rigid.xxx but in this proc is p.Reg.Rigid.xxx
            funParams.Rigid.tformType = 'affine'; % popupmenu % Name: Rigid Transform Type, Option: {'translation', 'rigid', 'similarity', 'affine'}, Default: 'affine', Doc: This defines the geometric transformation applied during the rigid registration step
            funParams.Rigid.regmodel = 'monomodal';% popupmenu %Name: Rigid Modality, Option:{'monomodal', 'multimodal'} Default: 'monomodal', Doc: This specifies the image modality used during the rigid registration step optimization
            funParams.Rigid.maxIter = 500; % edit box %Name: Rigid Maximum Iteration, Default: 500, Doc: maximum iteration used for rigid registration step optimization
            funParams.nonRigid.maxIter = 800; % edit box %Name: Nonrigid Maximum Iteration, Default: 800, Doc: maximum iteration used for nonrigid registration step optimization
            funParams.nonRigid.GridRegularization = 2;% edit box  %Name: Nonrigid Grid Regularization, Default: 2, Doc: Weighing factor for grid displacement regularization for nonrigid step using "imregdeform" function in matlab, check doc "imregdeform"
            funParams.nonRigid.NumPyramidLevels = 3; % edit box %Name: Nonrigid Pyramid Level, Default: 3, Doc: Number of multiresolution pyramid levels, specified as a positive integer.for nonrigid step using "imregdeform" function in matlab, check doc "imregdeform"
            funParams.nonRigid.AccumulatedFieldSmoothing = 3;% edit box  %Name : Nonrigid Accumulated Field Smoothing, Default = 3, Doc: check doc "imregdemons"
            funParams.nonRigid.FilterMetric = 'corrCross'; % Hanieh used 'MutualInfo' in script; % popupmenu %Name: Nonrigid Filter Metric, Option: {'MutualInfo','ssim','pHash','corrCross','MSE','featureExtract'}, Default: 'corrCross', Doc: This specifies a metric to compare each image with the reference image after nonrigid registration for removing bad registration
            funParams.nonRigid.FilterThreshold  = 0.7; % Hanieh used 0.4 in script;% edit box  %Name : Nonrigid Filter Threshold, Default = 0.7, Doc: This threshold is used to remove the bad nonrigid registration image
            funParams.VisPointRefImageFish = 1; % check box % can be marked in GUI, Name: Visualization of Points in the Final Reference Image

            funParams.usefishBodyImage = 0; % check box with callback % name: Use Fish Body Mask - QZ added this param for GUI. % see also proc 6.
            funParams.fishBodyfilePath = '';  % This is a whole path of a binary Image fishBodyImage (mask) tif file from the GUI. which diff from the folder Hanieh originally set. - QZ
            % funParams.fishBodyfilename = 'fishBodyImage.tif';

            % in the GUI the user should be able to choose more than one method for statType, name: Statistical Analysis Types. I
            % suggest to have a list that the user can select more than one then all
            % flags for those method including "NN", "TopRankedRegion", "Dispersion",
            % ... will be automatically 1

            funParams.NN.Flag = 1; % hide, must be 1. % Doc, flag for doing the nearest neighbor analysis
            funParams.NN.Radius = 40; % edit box % Name: Radius for NN Analysis, Value: 40 (in pixel), Doc: radius to calculate the number of nearest neighbor around each point (in pixel), can be chosen based on the validation in registration step
            funParams.NN.Metric = 'NN_num'; % hide QZ DID NOT USED in this proc. %  Name: metric type for NN analysis, Options = 'Dist', 'invDist', 'NN_num', Doc: a metric to give score/value to each point based on the neighbors, either distance or inverse distance or number of NN within a radius
            funParams.NN.NN_number = 2; % hide QZ DID NOT USED in this proc. % Name: NN number Doc: number of nearest neighbor for using knnsearch (self count), N = 1 means self-count
            funParams.NN.densityBin = [1 10 50 100 150]; % edit box %Name: Population Class, Default (=[1 10 50 100 150]), Doc: maximum population for identifying the class of a single point based on the number of its NN  within a given radius

            funParams.TopRankRegion.Flag = 1;  % hide, must be 1. % Doc, flag for creating top ranked regions based on stat analysis
            funParams.TopRankRegion.Metric = 'NN_num'; % hide QZ DID NOT USED in this proc. %  Name: metric type for NN analysis, Options = 'Dist', 'invDist', 'NN_num', Doc: a metric to give score/value to each point based on the neighbors, either distance or inverse distance or number of NN within a radius
            funParams.TopRankRegion.Radius = 40; % edit box % Name: Radius for Top Ranked Region Analysis, Unit: Pixel; Value: 40 (in pixel), Doc: radius to calculate the number of nearest neighbor around each point (in pixel), can be chosen based on the validation in registration step
            funParams.TopRankRegion.randSelection = 20; % edit box %Name: Random Number, Doc: number of sets to select the DownSampleNFish number for each condition to choose for calculating topranked.
            funParams.TopRankRegion.DownSampleNFish = 85; % edit box %Name: Downsample Fish Number, Doc: number of fish that can be selected for calculting the same analysis and compare conditions. It is useful when the number of fish are not the same across the conditions
            funParams.TopRankRegion.densityBin = [1 10 50 100 150]; % edit box %Name: Population class, Default (=[1 10 50 100 150]), Doc: maximum population for identifying the class of a single point based on the number of its NN  within a given radius
            funParams.TopRankRegion.overlapCutoff= 0.75; % edit box % Name: Overlap Threshold, Doc:threshold for selecting the pixels/regions that happens during the downsampling selection at least 75% of total selected set of DownSampleNFish

            funParams.Dispersion.Flag = 1; % hide, must be 1. % Doc, flag for calculating the dispersion of points: clustered or isolated compared to random distribution
            funParams.Dispersion.randNum = 400; % edit box % Name: Random Number , Doc: number of set to shuffle the original points in the fish body image for generating a random distribution for this analysis
            funParams.Dispersion.Radius = 40; % edit box % Name: Radius for Dispersion Analysis, Unit: Pixel; Value: 40 (in pixel), Doc: radius to calculate the number of nearest neighbor around each point (in pixel) for both random and original data to determine which one is isolated or clustered

            funParams.ManualRegion.Flag = 1; % check box with callback % name: Generating Manual Regions % Doc, flag for generating manual regions and calculte whether that region is enriched or not compared to a random distributed pattern
            funParams.ManualRegion.nMark = 40; % edit box % Name: Number of Clicks; Doc, number of click to generate a mask on an image
            funParams.ManualRegion.useRegionMask = 0; % check box with callback % name: Use Manual Region Mask - QZ added this param for GUI. % see also proc 6.
            % funParams.ManualRegion.Name = 'Region.tif'; % Name: filename of annotated region, Doc: filename of the masked image that mask a region
            funParams.ManualRegion.fishBodyImagePath = ''; % Name: Manual Region Mask Path, Default = '', Doc: optional tif mask path loaded from GUI % This is a whole path of a binary manual region image (mask) tif file from the GUI. which is save as Hanieh originally set. - QZ
            funParams.ManualRegion.randNum = 1000; % edit box % Name: Random Number , Doc number of sets to generate random distribution for calculating pemutation pvalue whether this region is enriched

            funParams.BoxGrid.Flag = 1; % check box with callback % Name: Calculate the Box Grid % Doc: a flag to calculate the box grid
            funParams.BoxGrid.boxSize = [100 100];  % edit box % Name: Box Size, Default = [100 100], Doc: box size of a box grid
            funParams.BoxGrid.useBoundingFish = 1;  % check box % Name: Use Fish Image, Doc: a flag to generate the box grid around the fish body not just all over in the image--> box grid is independent of the imagesize
            funParams.BoxGrid.DominantRegionFlag = 1; % check box %  Name: Calculate Dominant Regions , Doc: flag to calculate the dominant region across the conditions in pairwise comparison using ranked test
            funParams.BoxGrid.typeCoExist  = 'Jaccard'; % hide, b/c no other values - QZ % Name Coexist Type, Doc: a metric to calculate the cooccurence events in each regional pair
            funParams.BoxGrid.CoexistThresh = []; % edit box %Name: Coexist Thresh, Default = [], Doc:it is a vector of values between 0 to 1 for each condition to threshold coexistance values for genereating chord diagram, it is better to automatically generated for each condition and each box grid.
            funParams.BoxGrid.useAutoCoExistThresh = 1; % check box % Name: Run Autothreshold, Default = 1,  Doc: using random distribution for setting a threshold for chord diagram
            funParams.BoxGrid.CoExistRandNum = 400; % edit box % Name: Co-existence Random Number, Doc: number of random shuffles for automatic co-existence threshold
            funParams.BoxGrid.CoOccurenceFlag = 1; % hide , QZ added for this missing param.

            funParams.nMark = 50; % hide, QZ added, number of clicks to make a mask of the whole fish

        end

        % Below fcns are for popupmenus on GUI:
        function validTypes =  getValid_Rigid_tformType()
            validTypes = {'translation', ...    
                          'rigid',... 
                          'similarity',...
                          'affine'};
        end

        function validTypes =  getValid_Rigid_regmodel()
            validTypes = {'monomodal', ...    
                          'multimodal'};
        end

        function validTypes =  getValid_nonRigid_FilterMetric()
            validTypes = {'MutualInfo', ...    
                          'ssim',... 
                          'pHash',...
                          'corrCross',...
                          'MSE',...
                          'featureExtract'};
        end

    end
end
