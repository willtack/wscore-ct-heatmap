#!/bin/bash
#
# Run papaya-builder to create a custom viewer


resourcesDir="/flywheel/v0/resources"
baseImage="${resourcesDir}"/mni152.nii.gz
overlayImage="${resourcesDir}"/heatmap.nii.gz
cp "$1" ${overlayImage}

bash -x ${resourcesDir}/Papaya/papaya-builder.sh \
        -images ${baseImage} ${overlayImage} \
        -parameterfile ${resourcesDir}/params.json \
        -singlefile \
        -nodicom \
        -local

cp ${resourcesDir}/Papaya/build/index.html /flywheel/v0/output/volume_viewer.html
