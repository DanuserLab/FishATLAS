function [blurredFlag sharpness] = identifyBlurredImage(image2D,metric ,thresh)
% identifyBlurredImage identifies blurred image using the gradient filter
% for recognizing the sharpness of signal in x,y direction INPUT
%
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

%make the image from [0 1];
image2D = single(image2D);
image2D = (image2D - min(image2D(:)))/(max(image2D(:))- min(image2D(:)));

%calculate the sharpness of the image using gradient or laplacian filter
switch metric
    case 'sobel'
        [Gx, Gy] = imgradientxy(image2D,'sobel');
        gradient_magnitude = sqrt(Gx.^2 + Gy.^2);
        sharpness = var(gradient_magnitude (:));
    case 'prewitt'
        [Gx, Gy] = imgradientxy(image2D,'prewitt');
        gradient_magnitude = sqrt(Gx.^2 + Gy.^2);
        sharpness = var(gradient_magnitude (:));
    case 'laplacianFilter'
        laplacian_filter = fspecial('laplacian', 0.2); % Default Laplacian filter
        laplacian_img = imfilter(image2D, laplacian_filter, 'symmetric');
        % Compute the variance of the Laplacian
        sharpness = var(laplacian_img(:));
    otherwise
        error('metric is not well-defined!')

end

blurredFlag = sharpness < thresh;

