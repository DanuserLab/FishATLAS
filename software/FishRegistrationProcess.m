classdef  FishRegistrationProcess < ImLImageProcessingProcess & NonSingularProcess
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
            obj = obj@ImLImageProcessingProcess(super_args{:});
            obj.is3Dcompatible_ = false; % outputs are 2D
        end


    end

    methods (Static)
        function name = getName()
            name = 'Registration';
        end

        function h = GUI(varargin)
            h = @noSettingsProcessGUI % @FishRegistrationProcessGUI;
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


            funParams.vasChannel = 1; % was params.PreAlign.vasChannel = 1 in Hanieh's script, only used in Step 3: Registration

            funParams.useRefImage = 1; % use the reference image
            funParams.RefImagePath = []; % folder of reference image - QZ
            funParams.RefImageName = 'RefImageAll.tif'; % GUI should be able to select single tif file as RefImage. - QZ
            funParams.nonRigid.method = ''; %demon or deform
            funParams.rigid.RefImageID = 1; % the id of which image should be used for rigid registration
            funParams.rigid.tformType = 'affine';
            funParams.rigid.regmodel = 'monomodal';
            funParams.rigid.maxIter = 500;
            funParams.rigid.FilterMetric = 'corrCross';
            funParams.rigid.FilterThreshold = 0.7;
            funParams.nonRigid.GridRegularization = 2;
            funParams.nonRigid.NumPyramidLevels = 3;
            funParams.nonRigid.FilterMetric = 'corrCross';
            funParams.nonRigid.FilterThreshold = 0.82;
            funParams.nonRigid.maxIter = 800;
            funParams.nonRigid.AccumulatedFieldSmoothing = 3;
            funParams.RefImageFilter = 'laplacianFilter';  % check the sharpness of refimage: mean or median of groupwise images
            funParams.nonRigid.maxIterWhileLoop = 5; % maxIter for groupwise registration to be repeated after removing poor quality registered image


        end
    end
end
