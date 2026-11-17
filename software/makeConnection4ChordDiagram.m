function matrix = makeConnection4ChordDiagram(groups, weight, thresh)
% makeConnection4ChordDiagram generates the connection matrix for the chord
% diagram INPUT groups        all groups that are around the circle and
% needs to be connected
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
n = length(groups);
matrix = [];

for i = 1:n
    for j = 1:n
        if i ~= j
            if abs(weight(i,j)) >= thresh
                matrix = [matrix; groups(i), groups(j), abs(weight(i,j)),sign(weight(i,j)) ];
            end
        end
    end
end


end