function [pointpattern  InsideFlag binaryImage] = remove_outside_points(pointpattern, binaryImage)
%remove the points outside the fish body using multithreshold method
%INPUT 
% pointpattern    Nx2 matrix including coord of points
% fishImage,      fish image for creating a mask of fish body
% NThreshLevel    number of level for multi thresholing
%OUTPUT
% pointpattern    Nx2 matrix including coord of points inside the mask  
% InsideFlag      flag for points inside the mask 
% binaryImage     mask image of fish body
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

%check if the binaryImage is binary 
binaryFlag = length(unique(binaryImage)) == 2; 
if ~binaryFlag
    warning('Input image is not binary'); 
    binaryImage = makeBinaryFishBody(binaryImage); 
end 

%initialize the InsideFlag
InsideFlag = zeros(size(pointpattern,1),1);

% remove the points outside the mask
image_size = size(binaryImage);
%check if the points inside the imageSize
if max(pointpattern(:,2)) < image_size(1) || max(pointpattern(:,1)) < image_size(2)
    %find the index of point within the masked image
    ind_point = sub2ind(image_size,round(pointpattern(:,2)),round(pointpattern(:,1)));
    %find only points that have image value of 1; 
    ind_in = find(binaryImage(ind_point) == 1);
    %redefine the pointpatten and keep those inside the mask
    pointpattern = pointpattern(ind_in,:);
    InsideFlag(ind_in,:) = 1; 
else
    warning('Points are outside the input fish image, provide another fish image')
    InsideFlag = ones(size(pointpattern,1),1);
end 



