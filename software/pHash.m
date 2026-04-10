function hash = pHash(img)
    
    % Resize to 32x32
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
    img = imresize(img, [32 32]);
    
    % Apply 2D Discrete Cosine Transform (DCT)
    dctImg = dct2(double(img));
    
    % Extract the top-left 8x8 DCT coefficients
    dctLowFreq = dctImg(1:8, 1:8);
    
    % Compute the mean of the DCT coefficients (excluding DC)
    dctMean = mean(dctLowFreq(:));
    
    % Generate binary hash (1 if greater than mean, else 0)
    hash = dctLowFreq > dctMean;
    
    % Convert binary matrix to a vector
    hash = hash(:)';
end