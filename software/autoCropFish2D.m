function [croppedImage_hwc imageLabeled] = autoCropFish2D(Image_hwc, borderPX, vasChannel)
%autoCropFish2D automatically crops the fish image to keep the fish at the
%center of FOV. It applied to all channels.
%INPUT
% Image_hwc     a matrix of fish image in different channels (image2d (HeightWidth) * nChannel)
% borderPX      offset of border (D = 50)
% vasChannel    channel ID for registration (vasculature channel)
% OUTPUT
% croppedImage_hwc   a matrix of cropped image in all channels
% 
% created by Hanieh Mazloom-Farsibaf , Danuse lab 2025
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

% give default value to borderPX
if ~exist('borderPX','var')
    borderPX = 100;
end
if ~exist('vasChannel','var')
    vasChannel = 1;
end

% check if the image is normalized to [0 1], if not do it!
Image2D = single(Image_hwc(:,:,vasChannel)); 
Image2D = (Image2D - min(Image2D(:)))/(max(Image2D(:))- min(Image2D(:)));
 
% first increase the contrast using the following correction (gamma?)
imageAdaptive = adapthisteq(Image2D);

% use easy threshold to detect the object
imageLabeled = medfilt2(imageAdaptive); % smooth the image for not picking local maximum from bg. 
thresh = multithresh(imageLabeled);
% imageLabeled = imageAdaptive;
imageLabeled (imageLabeled <thresh) = 0; 
imageLabeled (imageLabeled >= thresh) = 1; 

se = strel('disk',10);

imageLabeled = imclose(imageLabeled,se);
imageLabeled = imfill(imageLabeled); 

% filter out the single pixel from the main object imageLabeled =
% % medfilt2(imageLabeled); keep the biggest components
% nMaxNumPx = 1000; 
conn = 4; 
% imageLabeled = bwareaopen(imageLabeled,MaxNumPx,conn);% large area to remove nonspecific object
% maybe I should keep the biggest component with lowest connectivity 
CC = bwconncomp(imageLabeled, conn); 
CClength = cellfun(@length, CC.PixelIdxList);
[  MaxCC MaxCCInd] = max(CClength);
imageLabeled = zeros(size(imageLabeled)); 
imageLabeled(CC.PixelIdxList{MaxCCInd}) = 1; 
imageLabeled = single(imageLabeled);

%before removing the single component, it is better to enlarge the
%segemntation, avoid cutting the tail
r = 30;
SE = strel("line",r,0);
imageLabeled = imdilate(imageLabeled,SE);

% find the max and min for the fish in image2D
[row col] = find(imageLabeled == 1); %fish s labeled 1 in line 22

% crop the image based on the min, max
croppedImage_hwc = Image_hwc(max(min(row)-borderPX,1):min(max(row)+borderPX,size(Image2D,1)), ...
    max(min(col)-borderPX,1):min(max(col)+borderPX,size(Image2D,2)),:);

