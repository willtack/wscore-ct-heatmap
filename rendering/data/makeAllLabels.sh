#!/bin/bash


module load freesurfer/7.1.1
source /appl/freesurfer-7.1.1/SetUpFreeSurfer.sh 

module load afni_openmp/20.1

sinpath=/project/ftdc_pipeline/tools/CBIG/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/FreeSurfer5.3/fsaverage/label/
fspath=$SUBJECTS_DIR/fsaverage/surf/
soutpath=/project/ftdc_pipeline/tools/schaeferRender/data/

lutpath=/project/ftdc_pipeline/tools/CBIG/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI/

for i in 100 200 300 400 ; do
  for j in 7 17 ; do
    odir=${soutpath}/schaefer${i}x${j}/
    if [[ ! -d ${odir} ]] ; then 
      mkdir ${odir}
    fi
    for h in lh rh ; do
      mris_convert --annot ${sinpath}/${h}.Schaefer2018_${i}Parcels_${j}Networks_order.annot ${fspath}/${h}.white ${odir}/${h}.schaefer${i}x${j}.label.gii 
    done
 
    gifti_tool -mod_gim_meta AnatomicalStructurePrimary CortexLeft -infile ${odir}/lh.schaefer${i}x${j}.label.gii  -write_gifti ${odir}/lh.schaefer${i}x${j}.label.gii
    gifti_tool -mod_gim_meta AnatomicalStructurePrimary CortexRight -infile ${odir}/rh.schaefer${i}x${j}.label.gii  -write_gifti ${odir}/rh.schaefer${i}x${j}.label.gii
  
    echo "Label.ID,Label.Name,R,G,B,Flag" > ${odir}/schaefer${i}x${j}_lut.csv
    cat ${lutpath}/Schaefer2018_${i}Parcels_${j}Networks_order.txt | tr '\t' ',' | sed 's/17Networks_//' | sed 's/7Networks_//' >> ${odir}/schaefer${i}x${j}_lut.csv
  done
done 

# for i in 100 200 300 400 ; do
#  for j in 7 17 ; do
#    odir=${soutpath}/schaefer${i}x${j}/
#    
#  done
# done
