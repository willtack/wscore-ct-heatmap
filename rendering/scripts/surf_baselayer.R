#!/usr/bin/Rscript
# Script that takes a file of numeric values for one of the Lausanne label sets and plots those values on the surface.
# Possible label sets include the 33-, 60-, 125-, and 250-label set from the Lausanne group (Hagmann, Cammoun, et al.).
# Required command-line arguments:
# 1. File of new values: a string variable giving the path to a two-column text file,
#	delimited by spaces or tabs. The first column should give either the label names or
#	ID numbers used in the Lausanne_Scale*.csv files or in QuANTs output. The second
#	column gives the numeric values to be plotted.
# 2. Stem for output files: [STEM]_binary
# Jeff Phillips, 09/20/2019: edited so that a hemisphere is only saved to a metric file if it contains non-NA values.
# Adapted for other nonsense for specific rendering script by Chris Olm

# Parse command-line arguments.
args<-commandArgs(trailingOnly=FALSE)
if (length(args)<7) {
	stop('Missing arguments!')
} else if (length(args)>7) {
	stop('Too many arguments!')
} else {
	# The ROI values file.
	valuesFile<-args[6]
	# Output stem.
	ostem<-args[7]
}

# Read in the ROI values file and get the values to be plotted from the second column.
vals<-read.table(valuesFile,stringsAsFactors=FALSE)

# get everything non-zero into 1 
vals$V2[ vals$V2 != 0 ] <- 1
# maxv <- max(vals$V2)

# write table
write.table(vals, paste(ostem,"_binary.txt",sep=""), quote=F, sep=" ", row.names=F, col.names=F)


