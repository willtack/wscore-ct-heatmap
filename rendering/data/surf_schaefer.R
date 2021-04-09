#!//usr/bin/Rscript
# Script that takes a file of numeric values for one of the Schaefer label sets and plots those values on the surface.
# Possible label sets include the 100, 200, 300, or 400-label set in either 7 or 17 networks from the Schaefer 2018 paper.
# Required command-line arguments:
# 1. File of new values: a string variable giving the path to a two-column text file,
#	delimited by spaces or tabs. The first column should give either the label names or
#	ID numbers used in the schaefer*.csv files or in QuANTs output. The second
#	column gives the numeric values to be plotted.
# 2. Label set name: schaefer100x7, schaefer100x17, etc.
# 3. Stem for output files: lh.[STEM].func.gii and rh.[STEM].func.gii.
# Jeff Phillips, 09/20/2019: edited so that a hemisphere is only saved to a metric file if it contains non-NA values.
# Chris Olm 02/02/2021: rewrote Jeff's Lausanne code for the Schaefer nasties
# Parse command-line arguments.
args<-commandArgs(trailingOnly=FALSE)
if (length(args)<8) {
	stop('Missing arguments!')
} else if (length(args)>8) {
	stop('Too many arguments!')
} else {
	# What directory does the current script reside in?
	# This will be used to find the appropriate look-up table (LUT).
	file.arg.name <- "--file="
	script.name <- sub(file.arg.name, "", args[grep(file.arg.name, args)])
	script.dir <- dirname(script.name)
	# The ROI values file.
	valuesFile<-args[6]
	# Target label set: schaefer{100,200,300,400}x{7,17}
	labset<-args[7]
	# Output stem.
	ostem<-args[8]
}

# Set the path to the look-up table to be used.
labdir<-paste(script.dir,labset,sep='/')
lutName<-paste(labdir,'/',labset,'_lut.csv',sep='')
lut<-read.csv(lutName,stringsAsFactors=FALSE)

# Name of the ROI file for each label.
wl<-grep('LH',lut$Label.Name)
wr<-grep('RH',lut$Label.Name)
if ( !"Label.Name2" %in% colnames(lut)) {
# lut$Label.Name2<-NA
# lut$Label.Name2[wl]<-gsub('LH_','',lut$Label.Name[wl])
# lut$Label.Name2[wr]<-gsub('RH_','',lut$Label.Name[wr])
lut$Label.Name2 <- lut$Label.Name
}

lut$ROI<-NA
if ( labset %in% c("schaefer100x7", "schaefer200x7", "schaefer300x7", "schaefer400x7") ) { nametag <- "7Networks_" } else { nametag <- "17Networks_" } 
# lut$ROI[wr]<-paste(labdir,'rh.',lut$Label.Name2[wr],'.func.gii',sep='')
# lut$ROI[wr]<-paste(labdir,'rh.',lut$Label.Name2[wr],'.func.gii',sep='')
lut$ROI[wl]<-paste(nametag, lut$Label.Name[wl],sep='')
lut$ROI[wr]<-paste(nametag, lut$Label.Name[wr],sep='')

# Read in the ROI values file and get the values to be plotted from the second column.
vals<-read.table(valuesFile,stringsAsFactors=FALSE)
if (is.numeric(vals$V1)) {
	lut$Value<-vals$V2[match(lut$Label.ID,vals$V1)]
} else {
	lut$Value<-vals$V2[match(lut$Label.Name,vals$V1)]
	lut$tmpValue <- vals$V2[match(lut$Label.Name2,vals$V1)]
        naname1 <- sum(is.na(lut$Value))
        naname2 <- sum(is.na(lut$tmpValue))
        if ( naname2 < naname1 ) { lut$Value <- lut$tmpValue } 
}
lut$Value[is.na(lut$Value)]<-NaN

# Construct commands that will merge the left and right ROI values into new metric files.

## Build the arithmetic expressions.
lut$SubExp<-paste(lut$Label.Name2,lut$Value,sep='*')

## Build the variable definitions.
# lut$VarDef<-paste('-var',lut$Label.Name2,lut$ROI)

lhgii <- paste(labdir, '/lh.', labset, '.func.gii', sep='')
rhgii <- paste(labdir, '/rh.', labset, '.func.gii', sep='')

lut$VarDef[wl]<-paste('-var', lut$Label.Name2[wl], lhgii, '-column',  lut$ROI[wl], sep=' ')
lut$VarDef[wr]<-paste('-var', lut$Label.Name2[wr], rhgii, '-column',  lut$ROI[wr], sep=' ')

## For each hemisphere, integrate into a call to wb_command -metric-math.
wlval<-which(grepl('LH', lut$Label.Name) & !is.nan(lut$Value))
if (length(wlval)>0) {      
	el<-paste(lut$SubExp[wlval],collapse='+')
	lvarlist<-paste(lut$VarDef[wlval],collapse=' ')
	loutf<-paste('lh',ostem,'func.gii',sep='.')
	lcmd<-paste('wb_command -metric-math',el,loutf,lvarlist)
	system(lcmd)
}

wrval<-which(grepl('RH_',lut$Label.Name) & !is.nan(lut$Value))
if (length(wrval)>0) {
	er<-paste(lut$SubExp[wrval],collapse='+')
	rvarlist<-paste(lut$VarDef[wrval],collapse=' ')
	routf<-paste('rh',ostem,'func.gii',sep='.')
	rcmd<-paste('wb_command -metric-math',er,routf,rvarlist)
	system(rcmd)
}

