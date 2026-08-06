// ===================================================================

// Simple Cristae Peak Distance Analyzer

// 1) Draw a line along the mitochondrion

// 2) Run this macro

// ===================================================================

 

if (selectionType() == -1) {

    exit("Please draw a line along the mitochondrion first.");

}

 

getPixelSize(unit, pw, ph);

 

// ---- GET INTENSITY PROFILE ALONG THE LINE ----

profile = getProfile();

n = profile.length;

 

if (n < 3) {

    exit("Line too short.");

}

 

// ---- FIND LOCAL MAXIMA (simple peaks) ----

peaks = newArray(0);

for (i = 1; i < n - 1; i++) {

    if (profile[i] > profile[i-1] && profile[i] >= profile[i+1]) {

        peaks = Array.concat(peaks, i);

    }

}

 

nPeaks = peaks.length;

if (nPeaks < 2) {

    exit("Fewer than 2 peaks detected.");

}

 

// ---- PEAKS TABLE (Results) ----

run("Clear Results");

for (i = 0; i < nPeaks; i++) {

    setResult("Peak #", i, i + 1);

    setResult("Position (px)", i, peaks[i]);

    setResult("Position (" + unit + ")", i, peaks[i] * pw);

    setResult("Intensity", i, profile[peaks[i]]);

    if (i > 0) {

        distPx = peaks[i] - peaks[i-1];

        setResult("Distance to previous (px)", i, distPx);

        setResult("Distance to previous (" + unit + ")", i, distPx * pw);

    }

}

updateResults();

 

// ---- SUMMARY STATISTICS ----

distances = newArray(nPeaks - 1);

for (i = 1; i < nPeaks; i++) {

    distances[i-1] = (peaks[i] - peaks[i-1]) * pw;

}

Array.getStatistics(distances, dMin, dMax, dMean, dStdDev);

 

// ---- SUMMARY TABLE (separate window, easy to copy to Excel) ----

summaryTable = "Cristae Summary";

if (!isOpen(summaryTable)) {

    Table.create(summaryTable);

}

selectWindow(summaryTable);

row = Table.size;

 

Table.set("Image", row, getTitle());

Table.set("N Peaks", row, nPeaks);

Table.set("N Intervals", row, distances.length);

Table.set("Mean Distance (" + unit + ")", row, dMean);

Table.set("StdDev (" + unit + ")", row, dStdDev);

Table.set("Min Distance (" + unit + ")", row, dMin);

Table.set("Max Distance (" + unit + ")", row, dMax);

Table.update;

 

// ---- PLOT PROFILE WITH PEAKS MARKED ----

Plot.create("Cristae Profile with Detected Peaks", "Distance along line (px)", "Intensity");

xVals = newArray(n);

for (i = 0; i < n; i++) xVals[i] = i;

Plot.add("line", xVals, profile);

peakY = newArray(nPeaks);

peakX = newArray(nPeaks);

for (i = 0; i < nPeaks; i++) {

    peakX[i] = peaks[i];

    peakY[i] = profile[peaks[i]];

}

Plot.setColor("red");

Plot.add("circle", peakX, peakY);

Plot.setColor("black");

Plot.show();

 

print("Done. See Results table, Cristae Summary table, and plot.");