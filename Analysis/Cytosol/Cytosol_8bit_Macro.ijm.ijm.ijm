run("8-bit");

setAutoThreshold("Default dark no-reset");

//run("Threshold...");

setAutoThreshold("Default no-reset");

setAutoThreshold("Default dark no-reset");

setThreshold(1, 255, "raw");

//setThreshold(1, 255);

setOption("BlackBackground", true);

run("Convert to Mask");
