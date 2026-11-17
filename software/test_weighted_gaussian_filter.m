function filtered_image = test_weighted_gaussian_filter(point_coords, weights, image_size, sigma)
    % point_coords: Nx2 matrix of [x, y] point positions
    % weights: Nx1 vector of weights for each point
    % image_size: [height, width] of the output image
    % sigma: standard deviation of the Gaussian (scalar)
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

    % Output image initialized
    filtered_image = zeros(image_size);

    % Size of Gaussian kernel (truncate at 3*sigma)
    half_size = ceil(3 * sigma);
    [X, Y] = meshgrid(-half_size:half_size, -half_size:half_size);
    gaussian_kernel = exp(-(X.^2 + Y.^2) ./ (2 * sigma.^2));
    gaussian_kernel = gaussian_kernel / sum(gaussian_kernel(:));  % normalize

    % Loop over all points
    for i = 1:size(point_coords, 1)
        x = round(point_coords(i, 1));
        y = round(point_coords(i, 2));
        w = weights(i);

        % Define region in output image
        x_range = (x - half_size):(x + half_size);
        y_range = (y - half_size):(y + half_size);

        % Check bounds
        valid_x = x_range > 0 & x_range <= image_size(2);
        valid_y = y_range > 0 & y_range <= image_size(1);
        x_range = x_range(valid_x);
        y_range = y_range(valid_y);
        kernel_crop = gaussian_kernel(valid_y, valid_x);

        % Add weighted kernel to the image
        filtered_image(y_range, x_range) = filtered_image(y_range, x_range) + w * kernel_crop;
    end
end