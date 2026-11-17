# FishATLAS

## Introduction

FishATLAS is a MATLAB package for mapping and comparing organ-specific patterns of cancer cell dissemination in zebrafish larvae. It uses the vasculature as an anatomical reference to combine imaging data from individual fish into population atlases and compare spatial patterns across cancer cell lines and experimental conditions.

The `gui-update` branch includes the updated package with a graphical user interface (GUI) and documentation for testing and feedback.

## Documentation

Documentation is included in the [`docs/`](docs/) folder on this branch. See [Installation](docs/FishATLAS.wiki/Installation.md) for MATLAB setup and [Getting Started](docs/FishATLAS.wiki/Getting-Started.md) for instructions on loading data and launching the GUI.

Descriptions of the package and its individual analysis steps are available in the [FishATLAS Package Description](docs/FishATLAS.wiki/FishATLAS-Package-Description.md).

## Running the Package with a Script

**Getting Started**

1. Download the code and example images. Set MATLAB’s path to include all the MATLAB functions provided by this package, using the “Set Path” button in MATLAB (Home > Environment > Set Path > Add with subfolders).
2. To run the package for provided examples, you need to run this script ‘NewFishATLASPackageTestScript_QZ.m’, before running the package, set the path of data to your current example files where you save earlier. You need to change the variable of ‘dataRoot’ in this script at the beginning of the script to run the package successfully.
3. Results are automatically saved in the example folders.
4. As demo, we provided two cell lines: CHLA9 and CHLA10.

## Software Feedback

Please submit feedback, bug reports, and feature requests through the [Issues](https://github.com/DanuserLab/FishATLAS/issues) tab of this repository.

## Danuser Lab Links

[Software Links](https://github.com/DanuserLab/)
