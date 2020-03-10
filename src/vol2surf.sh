#!/bin/bash
####---------Volume to Surface Mapping for Connectome Workbench Renders--------#######
####----Date Created: 5/22/17 Authors: Katherine Xu & Charles Jester
####----This script was designed to take a volume input nifti image and push the results to the surface in order to be represented in a workbench. This will be used in conjunction with randomise/other outputs for visualization.


if [[ $# -lt 1 ]]; then
cat <<USAGE

	$0 <input>

	input - the image .nii file for which R and L surf.gii will be made

	NOTE - files are outputted in same directory as input file

	Created Files: L and R surf.nii files
		(The L and R surface files are modified such that only the positive color values are displayed)


USAGE

exit 1

fi


#input is the file path of the input image with the suffix removed

fileinput=$1
fileraw=`readlink -e $fileinput`
input=${fileraw%.nii.gz}

# Location of the left and right Conte surfaces
leftsurft=/flywheel/v0/resources/32k_ConteAtlas_v2/Conte69.L.midthickness.32k_fs_LR.surf.gii
rightsurft=/flywheel/v0/resources/32k_ConteAtlas_v2/Conte69.R.midthickness.32k_fs_LR.surf.gii

#Changing Names

leftout=${input}_L.shape.gii

rightout=${input}_R.shape.gii



#wb_command lines
lcmd="wb_command -volume-to-surface-mapping $fileraw $leftsurft $leftout -trilinear"

rcmd="wb_command -volume-to-surface-mapping $fileraw $rightsurft $rightout -trilinear"


echo
echo $lcmd
echo
echo $rcmd

$lcmd
$rcmd


# This edits the palette of the L and R surface files such that they do not display negative colors (i.e. only reds/oranges on heat map scale)

wb_command -metric-palette ${leftout} MODE_AUTO_SCALE_PERCENTAGE -disp-neg FALSE
wb_command -metric-palette ${rightout} MODE_AUTO_SCALE_PERCENTAGE -disp-neg FALSE
