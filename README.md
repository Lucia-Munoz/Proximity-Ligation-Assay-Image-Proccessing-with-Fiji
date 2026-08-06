# Proximity-Ligation-Assay-Image-Proccessing-with-Fiji
This repository contains the Fiji Macros used for the Proximity LIgation Assay Image proccessing for the detection of mitochondrial supercomplexes, developed by Lucia Muñoz Blanco and Sara Natalia Jaroszewicz at Dr Jose Antonio Enríquez laboratory (Genoxphos) in Centro Nacional de Investigaciones Cardiovasculares (CNIC))

Shown below is the workflow for the PLA Image analysis as developed by Sara (saranatalia.jaroszewicz@cnic.es), each channel is shown in a different colour and the names over the arrows correspond to the macro used on each step. Please, note that other softwares are also used in this pipeline which code is not available right now. These codes are marked in pink. 

<img width="2685" height="1687" alt="Diagrama en blanco" src="https://github.com/user-attachments/assets/13b91315-b5c8-4452-88cd-f215b54b76ee" />

Inside this repository you can find a folder corresponding to each channel and the macros used. Inside each of the macros there is a title and an introduction which explains the usage, results and application of said macro

# The first thing: Names

This macros have specific names templates thay use to make sure the archives are correct and to undestand what represents each channel. So before anything, make sure to name your files the following way:



# First step Max Projection and Split Channels:

The raw confocal microscopy images are z-stacks containing different channels. Here we execute the macro MaxProjection_SplitChannels.ijm found inside the *Analysis* folder in this repository. This macro gets the maximun intensity from the z-stack and divides this image into its different channels. Each channel is saved in a seperated folder (C1, C2, C3...) inside an indicated folder. IMPORTANT: this macro works over the images that are already open, so make sure to have open in Fiji all th eimages you want to process

# Second step, the cytosol
It is important to first process the cytosol, in these experiments the NHS esther was used to dye all the proteins in the cells (mouse fibroblasts) and therefore the cell cytosol can be delimitated as there is an instensity difference between the cell and the background. It is important that the cytosol is the first channel proccessed as it will be used to delimite the individual cells. All macros here are available inside the *cystosol* folder.

We start with the RGB images that we obtained in the previous step, then in this case the cytosol is thresholded using Cell Profiler (code not available). Once we have the cytosol thresholded we delimit each of the individual cells, using the Isolate_Cells_RGB_Batch.ijm macro. This macro returns each individual cell in its ownn image. As these are RGB images with labels, to simplify posterior analysis, these are turn into 8 bit binary images using the macro Cytosol_8bit_macro.ijm. This b&w masks will be considered as the area of the cell.

# Third step, the mitochondria

As in this experiment we are quantifiying the amount of supercomplexes (PLA) inside the mitochondria, we must only quantify those which are inside mitochondrias, and to do that we first have to delimit this organelle. All the macros mentioned here can be found inside the *mitos* folder in the repository.

We start with the RGB images that we obtained from the first step, then se substrack the background using the macro SubstrackBackground_Mito.ijm. After this we threshold the mitos using the Fiji Plugin MitoAnalyzer with the following params: (FALTA)

Now we clean the mitos that are too small, and possibly unspecific signal, using the macro Clean_Particles_Mitos.ijm all the particles smaller than 0'1 nm2 are removed.

Then, using the cleaned mitos and the 8 bit masks that we obtained from processing the cytosol we can obtain the mitos per cell. By executing the macro Cytosol_Mask_To_Mitos_Per_Cell.ijm, the cytosol mask is used as a frame and all the mitos within its area are considered to belong to that specific cell.

# Fourth step, the PLA

Finally, we get to the PLA, all the macros stored inside the *PLA* folder. In this case the raw data obtained from the microscope are deconvolutioned and channels splitted using the programm Huyggens Proffesional (code not available). The PLA channel is selected and saved in ICS2 format. To these archives we execute the Max_Projection_Find_maxima.ijm in order to reduce the ambiguity produced by the fluorescent signal. 

Now using the mitos per cell obtained in the previous section we first have to rename both mitos per cell using the Rename_MitosThresholded.ijm macro and the find maxima images using the Rename_MaximaFiles.ijm macro. IMPORTANT: this is needed because both PLA and mitos are processed using funcitions such as Mitoanalyser and HUggyns which add specific names and terminations to the images, this may not be needed depending on how you processed your images. 

Finally we apply the macro Find_maxima_per_Cell.ijm after which we can apply the macro Count_PLA_Macro.ijm, which counts the PLA signals in each cells (shown in the column 'Count' in the table)

# Optional step, the nucleous
Although not strictly needed for this analysis you can also obtain the nucleous per cell. For this we start with the RGB images mentioned in the first step. Then we threshold the nucleous using the macro: NucleusSegment.ijm, please note that this nucleous can fail in same cases so, some manual quality control is needed. Once cleaned we can obtain the nucleous per cell by executing the Cytosol_Mask_To_Nucleous_Per_Cell.ijm macro.
