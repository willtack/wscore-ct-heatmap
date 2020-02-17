#!/bin/sh

#One argument - output directory
if [[ $# -lt 1 ]]; then
cat <<USAGE

  $0 input is subjects list, with subject ID and timepoint separated by a "/"

   Assumes antsCorticalThickness output in crossSectional/antsct/[subject ID]/[scan date]/

   outputs heatmap of z score for CorticalThickness normalized to MNI152 space in crossSectional/antsct/[subject ID]/[scan date]/normalizedToMNI152/ directories

USAGE

exit 1

fi

# Define the output folder in the run script WT
outputTPDir=$2


  if [[ ! -d $outputTP_Dir ]]; then
    echo " no antsCT output for ${i}, skipping"
  else
    subj=$(echo $i | cut -d '/' -f1)
    tp=$(echo $i | cut -d '/' -f2)
    BinDir=/data/grossman/pipedream2018/crossSectional/scripts
    cmd="qsub -S /bin/bash -cwd -j y -o ${outputTP_Dir}/${subj}_${tp}_indivHeatmap.stdout ${BinDir}/indivHeatmap.sh ${i} "
    echo $cmd
    echo
    $cmd
    sleep .6
    echo
  fi
