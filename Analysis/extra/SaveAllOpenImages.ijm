
// Saves all open images in TIFF format.
// Uncomment last line to close the saved images.
// Save this file in the plugins folder, or subfolder,
// to create a "Save all Images" command.

  if (nImages==0)
     exit("No images are open");
  dir = getDirectory("Choose a Directory");
  for (n=1; n<=nImages; n++) {
     selectImage(n);
     title = getTitle;
     saveAs("tiff", dir+title.replace("/","_"));
  } 
  close("*");

