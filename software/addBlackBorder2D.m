function image2DLarge = addBlackBorder2D(image2D, borderSZ, padType, direction)

% addBlackBorder - adds a black border of specified Lx and Ly to a 2D image
% with zero value
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
if ~exist('padType','var')
    padType = 'replicate';
end
if ~exist('direction','var')
    direction = 'both';
end


% make it right/left to have similar image size for all fish - not happy
% with this version
if ~any(mod(borderSZ,2)) % both are even integer
    direction = 'both';
    borderSZ = borderSZ/2; 
    image2DLarge = padarray(image2D,borderSZ, padType, direction);
elseif any(mod(borderSZ,2))
    borderSZ_L = ceil(borderSZ/2); 
    borderSZ_R = borderSZ - borderSZ_L;
    image2DLargetmp = padarray(image2D,borderSZ_L, padType, 'post');
    image2DLarge = padarray(image2DLargetmp,borderSZ_R, padType, 'pre');

end
%
% % find the image size imageSize = size(image2D);
%
% % the border might be odd so I need to add properly for having the same %
% image size for all fish Lx_left = round(borderSZ(1)/2); Lx_right =
% borderSZ(1) - Lx_left; Ly_top = round(borderSZ(2)/2); Ly_bottom =
% borderSZ(2) - Ly_top;
%
% % initialize a slightly larger black image % image2DLarge =
% median(image2D(:))+zeros(imageSize(1)+2*width, imageSize(2)+2*width); %
% image2DLarge = median(image2D(:)) + zeros(imageSize(1) + Lx_left +
% Lx_right, imageSize(2) + Ly_top + Ly_bottom); image2DLarge =
% median(image2D(:)) + zeros(imageSize(1) + Lx_left + Lx_right,
% imageSize(2) + Ly_top + Ly_bottom);

% % set image3D to be the center of the black image
% image2DLarge(Lx_left+1:end-Lx_right, Ly_top + 1:end - Ly_bottom) =
% image2D;
%