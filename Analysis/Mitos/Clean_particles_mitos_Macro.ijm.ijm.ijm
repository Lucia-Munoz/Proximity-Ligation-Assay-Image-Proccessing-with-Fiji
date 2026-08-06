un("Analyze Particles...", "size=0-0.1 clear add composite");

roiManager("Combine");

setBackgroundColor(0, 0, 0);

run("Clear", "slice");

roiManager("Show All without labels");

roiManager("Show None");

run("Remove Overlay");