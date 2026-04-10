function M = MI_GG(X,Y)
% function M = MI_GG(X,Y)
% Compute the mutual information of two images: X and Y, having
% integer values.
% 
% INPUT:
% X --> first image 
% Y --> second image (same size of X)
%
% OUTPUT:
% M --> mutual information of X and Y
%
% Written by GIANGREGORIO Generoso. 
% DATE: 04/05/2012
% E-MAIL: ggiangre@unisannio.it
%__________________________________________________________________________
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

X = double(X);
Y = double(Y);

X_norm = X - min(X(:)) +1; 
Y_norm = Y - min(Y(:)) +1;

matAB(:,1) = X_norm(:);
matAB(:,2) = Y_norm(:);
h = accumarray(matAB+1, 1); % joint histogram

hn = h./sum(h(:)); % normalized joint histogram
y_marg=sum(hn,1); 
x_marg=sum(hn,2);

Hy = - sum(y_marg.*log2(y_marg + (y_marg == 0))); % Entropy of Y
Hx = - sum(x_marg.*log2(x_marg + (x_marg == 0))); % Entropy of X

arg_xy2 = hn.*(log2(hn+(hn==0)));
h_xy = sum(-arg_xy2(:)); % joint entropy
M = Hx + Hy - h_xy; % mutual information

