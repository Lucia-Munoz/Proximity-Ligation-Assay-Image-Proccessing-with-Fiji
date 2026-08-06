# Proximity-Ligation-Assay-Image-Proccessing-with-Fiji
This repository contains the Fiji Macros used for the Proximity LIgation Assay Image proccessing for the detection of mitochondrial supercomplexes, developed by Lucia Muñoz Blanco and Sara Natalia Jaroszewicz at Dr Jose Antonio Enríquez laboratory (Genoxphos) in Centro Nacional de Investigaciones Cardiovasculares (CNIC))

Shown below is the workflow for the PLA Image analysis as developed by Sara (saranatalia.jaroszewicz@cnic.es), each channel is shown in a different colour and the names over the arrows correspond to the macro used on each step. Please, note that other softwares are also used in this pipeline which code is not available right now. These codes are marked in pink. 

<img width="2685" height="1687" alt="Diagrama en blanco" src="https://github.com/user-attachments/assets/13b91315-b5c8-4452-88cd-f215b54b76ee" />

Inside this repository you can find a folder corresponding to each channel and the macros used. Inside each of the macros there is a title and an introduction which explains the usage, results and application of said macro

# First step Max Projection and Split Channels:

The raw confocal microscopy images are z-stacks containing different channels. Here we execute the macro MaxProjection_SplitChannels.ijm found inside the *Analysis* folder in this repository. This macro gets the maximun intensity from the z-stack and divides this image into its different channels. Each channel is saved in a seperated folder (C1, C2, C3...) inside an indicated folder. IMPORTANT: this macro works over the images that are already open, so make sure to have open in Fiji all th eimages you want to process

# Second step, the cytosol
It is important to first process the cytosol, in these experiments the NHS esther was used to dye all the proteins in the cells (mouse fibroblasts) and therefore the cell cytosol can be delimitated as there is an instensity difference between the cell and the background. It is important that the cytosol is the first channel proccessed as it will be used to delimite the individual cells. All macros here are available inside the *cystosol* folder.

We start with the RGB images that we obtained in the previous step, then in this case the cytosol is thresholded using Cell Profiler (code not available). Once we have the cytosol thresholded we delimit each of the individual cells, using the Isolate_Cells_RGB_Batch.ijm macro. This macro returns each individual cell in its ownn image. As these are RGB images with labels, to simplify posterior analysis, these are turn into 8 bit binary images using the macro 
