// MaxProjection_AllOpenImages.ijm
//
// For every currently open image in ImageJ/Fiji, this macro:
//   1. Runs a Z Projection (Max Intensity) over all slices
//   2. Saves the resulting projection as a TIFF into a folder you choose
//
// Usage:
//   1. Open all the images/stacks you want to process.
//   2. Run this macro (Plugins > Macros > Run..., or paste into the Macro editor and click Run).
//   3. Choose the output folder when prompted.

// Ask the user for the folder where projections should be saved
outputDir = getDirectory("Choose a folder to save the Max Intensity Projections");

n = nImages;
if (n == 0) {
    showMessage("No images open", "Please open one or more images/stacks before running this macro.");
    exit();
}

// Capture the titles of all currently open images BEFORE doing anything else.
// (We do this up front because window indices shift as we open/close projections.)
titles = newArray(n);
for (i = 0; i < n; i++) {
    selectImage(i + 1); // selectImage is 1-based
    titles[i] = getTitle();
}

setBatchMode(true); // speeds things up and avoids window flicker

for (i = 0; i < titles.length; i++) {
    title = titles[i];
    selectWindow(title);

    // Prefer the window title as the base name: for multi-series files
    // (e.g. .lif, .czi with multiple series), Bio-Formats appends a series
    // suffix to the window title (e.g. "file.lif - SeriesName"), which
    // getInfo("image.filename") does NOT include (it only returns the
    // underlying container file name). Only fall back to getInfo if the
    // title is somehow empty.
    baseName = title;
    if (baseName == "") {
        fname = getInfo("image.filename");
        if (fname != "" && fname != "null") {
            baseName = fname;
        }
    }

    // Only strip a trailing extension if a recognized image extension sits
    // right at the END of the name. This avoids chopping off meaningful
    // text for names like "file.lif - SeriesName", where the "." is in the
    // middle rather than marking a true file extension.
    knownExtensions = newArray(".ome.tif", ".ome.tiff", ".tif", ".tiff", ".lif",
                                ".czi", ".nd2", ".lsm", ".oib", ".oif", ".jpg",
                                ".jpeg", ".png", ".bmp", ".gif");
    for (e = 0; e < knownExtensions.length; e++) {
        ext = knownExtensions[e];
        extLen = lengthOf(ext);
        nameLen = lengthOf(baseName);
        if (nameLen > extLen) {
            candidate = substring(baseName, nameLen - extLen, nameLen);
            if (toLowerCase(candidate) == ext) {
                baseName = substring(baseName, 0, nameLen - extLen);
                e = knownExtensions.length; // break out of loop
            }
        }
    }

    // Sanitize characters that are invalid/problematic in file names
    // (e.g. leftover path separators or colons from series names)
    baseName = replace(baseName, "[\\\\/:]", "-");

    saveName = "MAX_" + baseName + ".tif";

    // Use getDimensions instead of nSlices, since nSlices returns the TOTAL
    // number of images in the stack (channels x z-slices x frames) for
    // hyperstacks, whereas Z Project's start/stop expects just the Z-slice
    // index range (1 to zDepth). Using nSlices directly causes an
    // "out of range" error on multi-channel/multi-frame hyperstacks.
    getDimensions(imgWidth, imgHeight, channels, zDepth, frames);

    // Note: newTitle is wrapped in square brackets below. ImageJ's run()
    // dialog strings are parsed as space-delimited key=value pairs, so any
    // title containing a space would otherwise get truncated at the first
    // space. Brackets tell ImageJ to treat the whole thing as one value.
    newTitle = "MAX_" + baseName;

    if (zDepth > 1) {
        // Perform Max Intensity Z Projection over all Z slices
        // (Z Project automatically applies this across all channels/frames too)
        run("Z Project...", "start=1 stop=" + zDepth + " projection=[Max Intensity]");
        rename(newTitle); // ensure the resulting window has the full, correct name
    } else {
        // Only a single Z slice - just duplicate it so there is still
        // a "projection" image to save, matching the same output naming.
        run("Duplicate...", "title=[" + newTitle + "] duplicate");
    }

    // Whatever image is now active is the projection (or duplicate) we want to save
    projTitle = getTitle();
    selectWindow(projTitle);

    // Save the projection
    saveAs("Tiff", outputDir + saveName);

    // Close the projection/duplicate window (keep original images open)
    close();
}

setBatchMode(false);

showMessage("Done", "Max Intensity Projections saved to:\n" + outputDir);

close("*");
