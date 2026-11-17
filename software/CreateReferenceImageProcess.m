classdef  CreateReferenceImageProcess < ImageProcessingProcessImL & NonSingularProcess
    % Process Class for create reference image
    % createReferenceImageWrap.m is the wrapper function
    % CreateReferenceImageProcess is part of new FishATLAS Package
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

    methods (Access = public)
        function obj = CreateReferenceImageProcess(owner, varargin)
            
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
                super_args{2} = CreateReferenceImageProcess.getName;
                super_args{3} = @createReferenceImageWrap;
                if isempty(funParams)
                    funParams = CreateReferenceImageProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@ImageProcessingProcessImL(super_args{:});
            obj.is3Dcompatible_ = false; % outputs are 2D
        end


    end

    methods (Static)
        function name = getName()
            name = 'Reference Image Creation';
        end

        function h = GUI(varargin)
            h = @CreateReferenceImageProcessGUI;
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
            funParams.OutputDirectory = [outputDir  filesep 'CreateRefImage'];
            funParams.ProcessIndex = []; % can use this parameter to set which previous process's output to be used as input for this process


            % these 3 param will grab from the params in proc 1, actually just need vasChannel in this proc
            % funParams.PreAlign.vasChannel = 1; % Name: Registration Channel ID, Deafult: 1, Doc: detemine the channel ID that should be used for registration
            % funParams.PreAlign.cancerChannel = 2; % did not used in this module 3 - QZ; Name: Cancer Channel ID, Deafult: 2, Doc: detemine the channel ID for cancer channel
            % funParams.PreAlign.nChannel = 2; % same as numel(owner.imFolders_), we do not need this param - QZ

            % QZ - The Reg here is diff from the Step 3 FishRegistrationProcess? The params here do not link with params in proc 3 FishRegistrationProcess
            funParams.rigid.RefImageID = []; % edit box % Name:Rigid Transform Image ID, no default,  Doc: image ID that used for rigid registration, select by user or randomly if it is empty
            funParams.rigid.tformType = 'affine'; % popupmenu % Name:Rigid Transform Type, Option: {'translation', 'rigid', 'similarity', 'affine'}, Default: 'affine', Doc: This defines the geometric transformation applied during the rigid registration step
            funParams.rigid.regmodel = 'monomodal'; % popupmenu %Name: Rigid Modality, Option:{'monomodal', 'multimodal'} Default: 'monomodal', Doc: This specifies the image modality used during the rigid registration step optimization
            funParams.rigid.maxIter = 500; % edit box  %Name: Rigid Maximum Iteration, Default: 500, Doc: maximum iteration used for rigid registration step optimization
            funParams.rigid.FilterMetric = 'corrCross'; % popupmenu %Name: Rigid Filter Metric, Option: {'MutualInfo','ssim','pHash','corrCross','MSE','featureExtract'}, Default: 'corrCross', Doc: This specifies a metric to compare each image with the reference image after rigid registration for removing bad registration
            funParams.rigid.FilterThreshold = 0.7; % edit box  %Name : Rigid Filter Threshold, Default = 0.7, test script is 0.76. Doc: This threshold is used to remove the bad rigid registration image
            funParams.nonRigid.maxIter = 800; % edit box  % DID NOT USED in this proc still put on GUI - QZ; Name: Nonrigid Maximum Iteration, Default: 800, Doc: maximum iteration used for nonrigid registration step optimization
            funParams.nonRigid.GridRegularization = 2; % edit box  %Name: Nonrigid Grid Regularization, Default: 2, Doc: Weighing factor for grid displacement regularization for nonrigid step using "imregdeform" function in matlab, check doc "imregdeform"
            funParams.nonRigid.NumPyramidLevels = 3; % edit box  %Name: Nonrigid Pyramid Level, Default: 3, Doc: Number of multiresolution pyramid levels, specified as a positive integer.for nonrigid step using "imregdeform" function in matlab, check doc "imregdeform"
            funParams.nonRigid.FilterMetric = 'corrCross'; % popupmenu %Name: Nonrigid Filter Metric, Option: {'MutualInfo','ssim','pHash','corrCross','MSE','featureExtract'}, Default: 'corrCross', Doc: This specifies a metric to compare each image with the reference image after nonrigid registration for removing bad registration
            funParams.nonRigid.FilterThreshold = 0.7; % edit box  %Name : Nonrigid Filter Threshold, Default = 0.7, test script is 0.82.  Doc: This threshold is used to remove the bad nonrigid registration image

            funParams.RefImageFilter= 'laplacianFilter'; % hide on GUI - QZ

            funParams.nonRigid.maxIterWhileLoop = 5; % hide on GUI - QZ % QZ: Used but not defined, see line 42 in my script params.Reg.nonRigid.maxIterWhileLoop = 5;

        end

        % Below fcns are for popupmenus on GUI:
        function validTypes =  getValid_rigid_tformType()
            validTypes = {'translation', ...    
                          'rigid',... 
                          'similarity',...
                          'affine'};
        end

        function validTypes =  getValid_rigid_regmodel()
            validTypes = {'monomodal', ...    
                          'multimodal'};
        end

        function validTypes =  getValid_rigid_FilterMetric()
            validTypes = {'MutualInfo', ...    
                          'ssim',... 
                          'pHash',...
                          'corrCross',...
                          'MSE',...
                          'featureExtract'};
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
