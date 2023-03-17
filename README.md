# The Striatum Organizes 3D Behavior via Moment-to-Moment Action Selection

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7274803.svg)](https://doi.org/10.5281/zenodo.7274803)


## Authors
Jeffrey E. Markowitz<sup>1,2,5</sup>, Winthrop Gillis<sup>1</sup>, Celion Beron<sup>1,2</sup>, Shay Neufeld<sup>1,2</sup>, Keiramarie Robertson<sup>1,2</sup>, Neha Bhagat<sup>1</sup>, Ralph Peterson<sup>1</sup>, Emalee Peterson<sup>1</sup>, Minsuk Hyun<sup>1,2</sup>, Scott Linderman<sup>3,4</sup>, Bernardo L. Sabatini<sup>1,2</sup>, Sandeep R. Datta<sup>1,#</sup>

<br>

<sup>1</sup>Department of Neurobiology, Harvard Medical School, Boston, Massachusetts, United States<br>
<sup>2</sup>Howard Hughes Medical Institute, Chevy Chase, Maryland, United States<br>
<sup>3</sup>Grossman Center for the Statistics of Mind, Columbia University, New York, New York, United States<br>
<sup>4</sup>Departments of Statistics and Computer Science, Columbia University, New York, New York, United States<br>
<sup>5</sup>Present address: Wallace H. Coulter Department of Biomedical Engineering, Georgia Institute of Technology and Emory University. Atlanta, Georgia, United States<br>

#Corresponding Author 

<br><br>

# Overview

This contains code necessary to regenerate key figures and analysis from this paper. All code is in MATLAB and has been tested against versions up to 2022b. The directories are arranged as follows:

1. `fig_scripts` MATLAB scripts to directly generate figure panels. It is recommended to clear the MATLAB workspace prior to running each script.
2. `lib` contains custom MATLAB classes and functions for data processing.
3. `preprocessing` contains MATLAB scripts to regenerate long-running intermediate computations. It is not necessary to run these prior to running the figure-generation scripts. These are included for completeness.
4. `third_party` useful third-party functions.

<br><br>

# Installation

Installation instructions

1. Download the repository onto your local machine.
1. Add the path (including subdirectories) to your MATLAB path. Note that you'll need the Signal Processing, Bioinformatics, Image Processing, and Parallel Computing Toolboxes installed.

<br><br>

# Data

How to obtain data.

1. Download data from Zenodo here [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7274803.svg)](https://doi.org/10.5281/zenodo.7274803). You should see the following directory structure after unzipping the data. Note that it is recommended to decompress the data into a directory called `phanalysis_images` in `~/Desktop` – this is the default path for loading data in most scripts.

		.
		├── 1pimaging_dls
		│   └── phanalysis_object.mat
		├── decoding_results
		│   ├── decoding_results_1pimaging_cell_types.mat
		│   ├── decoding_results_1pimaging_moseq_hierarchy.mat
		│   ├── decoding_results_1pimaging_ncells.mat
		│   ├── decoding_results_1pimaging_ncells_zoom.mat
		│   ├── decoding_results_1pimaging_twocolor_cell_types.mat
		│   ├── decoding_results_1pimaging_twocolor_pseudopop.mat
		│   └── decoding_results_1pimaging_twocolor_withinanimal.mat
		├── dls_lesion_round1
		│   └── phanalysis_object.mat
		├── dls_lesion_round2
		│   └── phanalysis_object.mat
		├── photomephys
		│   ├── ephys_kernel.mat
		│   └── photomephys_analysis.mat
		├── photometry_a2a
		│   └── phanalysis_object.mat
		├── photometry_crosstalk
		│   ├── both
		│   │   └── hifiber_object.mat
		│   ├── greenonly
		│   │   └── hifiber_object.mat
		│   └── redonly
		│       └── hifiber_object.mat
		├── photometry_dls
		│   ├── lasso_distance.mat
		│   ├── modelr_randomizations.mat
		│   ├── modelr_randomizations_warped.mat
		│   └── phanalysis_object.mat
		└── photometry_nac
			└── phanalysis_object.mat
2. This contains everything you need to run the scripts in `fig_scripts`; this directory contains MATLAB scripts for generating panels from the manuscript.


<br><br>