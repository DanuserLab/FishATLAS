# FishATLAS Package Description

FishATLAS is a MATLAB package for studying where cancer cells disseminate and establish colonies in zebrafish larvae. It maps organ-specific colonization preferences, known as organotropism, and supports comparisons across cancer cell lines, tumor stages, and experimental perturbations.

The package uses fluorescently labeled vasculature to align individual fish to a common anatomical reference. Cancer colonies are detected in each fish and represented as binary masks describing their spatial extent and as points marking their locations. Transforming colony coordinates into the reference frame allows localized and rare detections to contribute to population maps, while retaining each point's fish identity.

These accumulated maps reveal recurrent colonization patterns that may be difficult to recognize in individual animals. Statistical analyses quantify local colony density, identify preferred anatomical regions, test enrichment against random distributions, and compare regional colonization between conditions. Coexistence analysis examines whether different regions are colonized within the same fish, helping characterize coordinated spatial patterns of dissemination.

The package operates on an ImageList containing ImageData datasets. Keep the channel order consistent across datasets and specify the registration and cancer channels in Pre-processing.

1. [Pre-processing](Pre-processing-Process-Description) crops, pads, and orients the fish images.
2. [Reference Image Creation](Reference-Image-Creation-Process-Description) optionally builds a shared reference from preprocessed images across datasets.
3. [Registration](Registration-Process-Description) aligns fish to an existing reference or creates a reference through groupwise registration within each dataset.
4. [Cancer Detection](Cancer-Detection-Process-Description) detects colonies, estimates their area weights, and maps their locations into the reference image.
5. [Accumulation](Accumulation-Process-Description) combines registered colony points within each dataset and removes points outside the fish body.
6. [Statistical Analysis](Statistical-Analysis-Process-Description) brings the datasets into a common coordinate system and compares local density, enriched regions, dispersion, and regional coexistence.

To use a shared reference, run Reference Image Creation and select its output in Registration. If a suitable reference already exists, select that image directly. To register each dataset as a group, skip Reference Image Creation and uncheck Use the Reference Image in Registration.
