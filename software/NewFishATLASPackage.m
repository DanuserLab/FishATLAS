classdef NewFishATLASPackage < Package
    % The main class of the New FishATLAS Package
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
    
    methods
        function obj = NewFishATLASPackage(owner, varargin)
        	% Constructor of class FishATLASPackage
            if nargin == 0
                super_args = {};
            else
                % Check input
                ip =inputParser;
                ip.addRequired('owner',@(x) isa(x,'ImageData'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                
                super_args{1} = owner;
                super_args{2} = [outputDir  filesep 'FishATLASPackage'];
            end
                 
            % Call the superclass constructor
            obj = obj@Package(super_args{:});        
        end
    end
    
    methods (Static)
        
        function name = getName()
            name = 'Fish ATLAS';
        end

        function m = getDependencyMatrix(i,j)
            %    1 2 3 4 5  {processes}           
            m = [0 0 0 0 0 ;  %1 FishPreProcessingProcess
                 0 0 0 0 0 ;  %2 CreateReferenceImageProcess (optional)
                 1 2 0 0 0 ;  %3 FishRegistrationProcess
                 0 0 1 0 0 ;  %4 CancerDetectionProcess
                 0 0 0 1 0 ;];%5 AccumulationProcess
            if nargin<2, j=1:size(m,2); end
            if nargin<1, i=1:size(m,1); end
            m=m(i,j);
        end

        function varargout = GUI(varargin)
            % Start the package GUI
            varargout{1} = NewFishATLASPackageGUI(varargin{:});
        end

        function procConstr = getDefaultProcessConstructors(index)
            procContrs = {
                @FishPreProcessingProcess,...
                @CreateReferenceImageProcess,...
                @FishRegistrationProcess,...
                @CancerDetectionProcess,...
                @AccumulationProcess,...
                                        };
            
            if nargin==0, index=1:numel(procContrs); end
            procConstr=procContrs(index);
        end

        function classes = getProcessClassNames(index)
            classes = {
                'FishPreProcessingProcess',...
                'CreateReferenceImageProcess',...
                'FishRegistrationProcess',...
                'CancerDetectionProcess',...
                'AccumulationProcess',...
                                        };
            if nargin==0, index=1:numel(classes); end
            classes=classes(index);
        end

        % add getMovieClass here, so will not call getMovieClass ('MovieData') in Package.m
        function class = getMovieClass() 
            % Retrieve the movie type on which the package can be applied
            class = 'ImageData';
        end
    end
    
end