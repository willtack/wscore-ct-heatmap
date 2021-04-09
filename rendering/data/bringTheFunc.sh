#!/bin/bash
module load workbench/1.4.2
soutpath=/project/ftdc_pipeline/tools/schaeferRender/data/
for i in 100 200 300 400 ; do
  for j in 7 17 ; do
    odir=${soutpath}/schaefer${i}x${j}/
    for h in lh rh ; do 
      wb_command -gifti-all-labels-to-rois ${odir}/${h}.schaefer${i}x${j}.label.gii 1 ${odir}/${h}.schaefer${i}x${j}.func.gii 
    done
  done
done
