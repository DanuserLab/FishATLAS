
function [similarity imageFlag ] = discardNonRegImages(imageRef, imageRegs,metric,threshold)
% function [similarity imageFlag params] = discardNonRegImages(imageRef,
% imageRegs,varargin) discardNonRegImages, check the similarity between two
% images and whether it is well-aligned with the reference image INPUT
% imageRef      reference image imageRegs     a stack of images for being
% checked for alignment (3D) varargin: metric threshold OUTPUT
%
%
% % ip = inputParser; % % % % Required arguments % % addRequired(ip,
% 'imageRef', @(x) isa(x, 'uint8') || isnumeric(x)); % % addRequired(ip,
% 'imageRegs', @(x) isa(x, 'uint8') || isnumeric(x)); % % % % Optional
% name-value pair arguments % addParameter(ip, 'metric', 'MutualInfo',
% @ischar);       % Default is 'MutualInfo' % addParameter(ip, 'threshold',
% 0.1, @isnumeric);     % Default is 0.1 %  % Parse inputs %     parse(ip,
% varargin{:}); % %     % Display the contents of p.Results % disp('Parsed
% Results:'); %     disp(ip.Results); % % ip.Results.metric = % metric =
% ip.Results.metric; % threshold = ip.Results.threshold; % % %find the
% parameters that used for this fucntion % params = ip.Results;
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

% set default
if ~exist('metric','var')
    metric = 'corrCross';
end
if ~exist('threshold','var')
    threshold = 0.1;
end

%default value for imageFlag is one then it will be updated if the
%similarity is lower than threshold
imageFlag= ones(size(imageRegs,3),1);
similarity = nan(size(imageRegs,3),1); 

% check the similarity between two images.
for iImage = 1: size(imageRegs,3)
    imagetmp = imageRegs(:,:,iImage);
    %skip blank image 
    if all(imagetmp(:) == 0)
        continue
    end 
    switch metric
        case 'MutualInfo'
            % imageRef = cast(imageRef,'single'); 
            % imagetmp = cast(imagetmp,'single'); 
            selfMI = MI_GG(imageRef,imageRef);
            similarity(iImage,1) = MI_GG(imageRef,imagetmp)/selfMI;
        case 'ssim'
            % selfMI = ssim(imageRef,imageRef);
            similarity(iImage,1) = ssim(imageRef,imagetmp);

        case 'pHash'
            hash1 = pHash(imageRef);
            hash2 = pHash(imagetmp);
            similarity(iImage, 1) = 1 - (hammingDistance(hash1, hash2) / numel(hash1)); % Normalize similarity (0 to 1)
       
        case 'corrCross'
            corrVal = normxcorr2(double(imagetmp), double(imageRef));
            similarity(iImage, 1) = max(corrVal(:));
        case 'MSE'
            similarity(iImage, 1) = -immse(imageRef, imagetmp);%imse is the error. 

        case 'featureExtract'
            % Detect features
            points1 = detectSURFFeatures(imageRef);
            points2 = detectSURFFeatures(imagetmp);scr

            % Extract features
            [features1, validPoints1] = extractFeatures(imageRef, points1);
            [features2, validPoints2] = extractFeatures(imagetmp, points2);

            % Match features
            indexPairs = matchFeatures(features1, features2);
    
            % % for visualization to test this method
            % matchedPoints1 = validPoints1(indexPairs(:,1));
            % matchedPoints2 = validPoints2(indexPairs(:,2));
            % figure; showMatchedFeatures(imageRef,imagetmp,matchedPoints1,matchedPoints2);
            % legend("matched points 1","matched points 2");

            % Number of matched features
            similarity(iImage, 1) = size(indexPairs, 1);

        otherwise
            error('Choose a metric to evaluate the similarity between two images')
    end
end

% check if the similarity is lower than threshold and update the imageRegs
imageFlag = single(similarity >= threshold);

