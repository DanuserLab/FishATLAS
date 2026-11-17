function [imageList blurredFlag sharpness]= discardBlurredImages(imageList, metric, thresh)
% discardBlurredImages removes blurred images from the imageList. The
% blurred images are identified by image gradient 
%INPUT 
% imageList     list of 2D images
% metric        metric to measure image gradient
% thresh        threshold to discard blurred images
%OutPUT
% imageList     updated list of images 
% blurredFlag   vector of [0 1] to identify blurred image
% sharpness     vector of variation of image gradient 
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


%define default value
if ~exist('metric', 'var')
    metric = 'sobel';
end

if ~exist('thresh', 'var')
    thresh = 0.005;
end

for iImage = 1: size(imageList,3)
    imagetmp = imageList(:,:,iImage);

    % identify blurred image
    [blurredFlag(iImage,1) sharpness(iImage,1)] = identifyBlurredImage(imagetmp,metric ,thresh);
end

%remove blurred images from the imageList
Ind = find(blurredFlag);
imageList(:,:,Ind) = [];
%how to apply for variaous channels? next challenge
% image2DLarge_ch2_good(:,:,Ind) = [];
% image2DLarge_ch3_good(:,:,Ind) = [];
