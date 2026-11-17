function [maskedImage ] = createMaskByHand(Image2D, nMark)

if ~exist('nMark', 'var')
    nMark = 10; 
end 

classImage = class(Image2D);
if strcmp(classImage ,'uint8')
     Image2D= im2uint8(Image2D); 
end

[markerCoord, markedImage] = genLandmarkImage(Image2D, nMark);
%connect the first point to the last one
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
markerCoord(end+1,:) = markerCoord(1,:);
    
mask = poly2mask(markerCoord(:,1), markerCoord(:,2), size(Image2D,1), size(Image2D,2));

if ndims(Image2D) == 2
    maskedImage = zeros(size(Image2D));
    maskedImage(mask) = 1;
else
    maskedImage = Image2D;
    maskedImage(repmat(mask, [1 1 3])) = 0; % works for RGB
end
