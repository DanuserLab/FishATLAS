function  FlippingImage_hwc = flippingFish2D(image_hwc)

 vasChannel = 1; %channel of fish body

imageCurrent = image_hwc(:,:,vasChannel);
    imageLabeled = imsegkmeans(imageCurrent,2);
    SZ_image = size(imageLabeled);
    labelID = single(unique(imageLabeled));
    % imsegkmeans consider bg as 1 or 2 randomly so I need to do these lines to label fish as 1 and bg as 0
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
    [minfish ,Indfish ]= min([length(find(imageLabeled ==labelID(1))), length(find(imageLabeled == labelID(2)))]);
    imageLabeled (imageLabeled ==labelID(Indfish)) = 3; % for avoiding conflicts
    imageLabeled (imageLabeled ~=3) = 0;
    imageLabeled (imageLabeled ==3) = 1;

    %flip if the eye is right
    imRight = imageLabeled(:,round(SZ_image(2)/2):end);
    imLeft = imageLabeled(:,1:round(SZ_image(2)/2));
    flipscore = length(find(imRight)) > length(find(imLeft));

    if flipscore
        FlippingImage_hwc = flip(image_hwc,2);
    else
                FlippingImage_hwc = image_hwc;
    end
    
    % %flip if the dorsal is down not top
    % imBottom = imageLabeled(round(SZ_image(1)/2):end,:);
    % imTop = imageLabeled(1:round(SZ_image(1)/2),:);
    % flipscore = length(find(imRight)) > length(find(imLeft));
    % 
    % if flipscore
    %     FlippingImage_hwc = flip(FlippingImage_hwc,1);
    % else
    %             FlippingImage_hwc = FlippingImage_hwc;
    % end
