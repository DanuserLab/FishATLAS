function binaryImage = makeBinaryFishBody(fishImage, NthreshLevel)
% makeBinaryFishBody generate a binary image of fish body from a fish image
%it is typically a reference image 
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


if ~exist('NThreshLevel','var')
    NThreshLevel = 6;
end 

% define the thresh level --> better to keep all signal within the fish
thresh = multithresh(fishImage,NThreshLevel);
binaryImage =single( fishImage > thresh(1));

% filling the holes
binaryImage = imfill(binaryImage);
se_disk = round(max(size(binaryImage))/30); 
se = strel('disk', se_disk);
binaryImage = imclose(binaryImage,se);

% remove multi components
conn = 4; 
CC = bwconncomp(binaryImage, conn); 
CClength = cellfun(@length, CC.PixelIdxList);
[  MaxCC MaxCCInd] = max(CClength);
binaryImage = zeros(size(binaryImage)); 
binaryImage(CC.PixelIdxList{MaxCCInd}) = 1; 
binaryImage = single(binaryImage);

%expand and refine the image for being inclusive around the fish body (good for fish fin)
se_rec = round(size(binaryImage)/7); 

se = strel('rectangle',se_rec);
binaryImage = imdilate(binaryImage, se);
binaryImage = single(activecontour(binaryImage, binaryImage, 50, 'edge'));
