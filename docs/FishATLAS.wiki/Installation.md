# Installation

## Installing MATLAB

We recommend using MATLAB R2024b. Download MATLAB from [MathWorks](https://www.mathworks.com/products/matlab.html). A MATLAB license is required.

## Cloning the Git Repository

1. On Windows, install [Git for Windows](https://gitforwindows.org).
2. Install [GitHub Desktop](https://desktop.github.com).
3. In GitHub Desktop, select **File > Clone Repository**, then select the **URL** tab.
4. Enter `https://github.com/DanuserLab/FishATLAS.git` and choose a local folder, such as `Documents/MATLAB/FishATLAS`.
5. Click **Clone** to download the repository.

## Adding FishATLAS to the MATLAB Path

Open MATLAB and enter the following command in the Command Window, replacing the example path with the location of your cloned FishATLAS repository:

```matlab
addpath(genpath('path/to/FishATLAS'))
```

To keep FishATLAS on the MATLAB path for future sessions, run:

```matlab
savepath
```
