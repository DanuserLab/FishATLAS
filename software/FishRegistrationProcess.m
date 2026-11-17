classdef  FishRegistrationProcess < ImageProcessingProcessImL & NonSingularProcess
    % Process Class for fish registration
    % fishRegistrationWrap.m is the wrapper function
    % FishRegistrationProcess is part of new FishATLAS Package
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
        function obj = FishRegistrationProcess(owner, varargin)

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
                super_args{2} = FishRegistrationProcess.getName;
                super_args{3} = @fishRegistrationWrap;
                if isempty(funParams)
                    funParams = FishRegistrationProcess.getDefaultParams(owner,outputDir);
                end
                super_args{4} = funParams;
            end
            obj = obj@ImageProcessingProcessImL(super_args{:});
            obj.is3Dcompatible_ = false; % outputs are 2D
        end


    end

    methods (Static)
        function name = getName()
            name = 'Registration';
        end

        function h = GUI(varargin)
            h = @FishRegistrationProcessGUI;
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
            funParams.OutputDirectory = [outputDir  filesep 'Registration'];
            funParams.ProcessIndex = []; % can use this parameter to set which previous process's output to be used as input for this process


            % funParams.vasChannel = 1; % QZ grab from the params in proc 1; was params.PreAlign.vasChannel = 1 in Hanieh's script, only used in Step 3: Registration
            % funParams.cancerChannel = 2; % QZ grab from the params in proc 1; 

            funParams.useRefImage = 1; % check box with callback % name: Use the Reference Image
            funParams.RefImagePath = []; % This is a whole path of a refImage tif file from the GUI. which diff from folder of reference image Hanieh originally set. - QZ
            % funParams.RefImageName = 'RefImageAll.tif'; % GUI should be able to select single tif file as RefImage. - QZ

            funParams.rigid.RefImageID = 1; % edit box % Name:Rigid Transform Image ID, % the id of which image should be used for rigid registration
            funParams.rigid.tformType = 'affine'; % popupmenu % Name:Rigid Transform Type, Option: {'translation', 'rigid', 'similarity', 'affine'}, Default: 'affine', Doc: This defines the geometric transformation applied during the rigid registration step
            funParams.rigid.regmodel = 'monomodal'; % popupmenu %Name: Rigid Modality, Option:{'monomodal', 'multimodal'} Default: 'monomodal', Doc: This specifies the image modality used during the rigid registration step optimization
            funParams.rigid.maxIter = 500; % edit box  %Name: Rigid Maximum Iteration, Default: 500, Doc: maximum iteration used for rigid registration step optimization
            funParams.rigid.FilterMetric = 'corrCross'; % popupmenu %Name: Rigid Filter Metric, Option: {'MutualInfo','ssim','pHash','corrCross','MSE','featureExtract'}, Default: 'corrCross', Doc: This specifies a metric to compare each image with the reference image after rigid registration for removing bad registration
            funParams.rigid.FilterThreshold = 0.7; % edit box  %Name : Rigid Filter Threshold, Default = 0.7. Doc: This threshold is used to remove the bad rigid registration image
            
            funParams.nonRigid.maxIter = 800; % edit box  % Name: Nonrigid Maximum Iteration, Default: 800, Doc: maximum iteration used for nonrigid registration step optimization           
            funParams.nonRigid.GridRegularization = 2; % edit box  %Name: Nonrigid Grid Regularization, Default: 2, Doc: Weighing factor for grid displacement regularization for nonrigid step using "imregdeform" function in matlab, check doc "imregdeform"
            funParams.nonRigid.NumPyramidLevels = 3; % edit box  %Name: Nonrigid Pyramid Level, Default: 3, Doc: Number of multiresolution pyramid levels, specified as a positive integer.for nonrigid step using "imregdeform" function in matlab, check doc "imregdeform"
            funParams.nonRigid.FilterMetric = 'corrCross'; % popupmenu %Name: Nonrigid Filter Metric, Option: {'MutualInfo','ssim','pHash','corrCross','MSE','featureExtract'}, Default: 'corrCross', Doc: This specifies a metric to compare each image with the reference image after nonrigid registration for removing bad registration
            funParams.nonRigid.FilterThreshold = 0.7; % edit box  %Name : Nonrigid Filter Threshold, Default = 0.7, test script is 0.82.  Doc: This threshold is used to remove the bad nonrigid registration image
            funParams.nonRigid.AccumulatedFieldSmoothing = 3; % edit box  %Name : Nonrigid Accumulated Field Smoothing, Default = 3, Doc: check doc "imregdemons"

            funParams.RefImageFilter = 'laplacianFilter'; % hide on GUI - QZ

            funParams.nonRigid.maxIterWhileLoop = 5; % hide on GUI - QZ % QZ: Used but not defined, see line 42 in my script params.Reg.nonRigid.maxIterWhileLoop = 5;
            funParams.nonRigid.method = ''; % hide, Doc: this will be saved during the process, as 'demon' or 'deform'

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
