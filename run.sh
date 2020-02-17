FLYWHEEL_BASE=/flywheel/v0
CODE_BASE=${FLYWHEEL_BASE}/src
MANIFEST_FILE=${FLYWHEEL_BASE}/manifest.json
INPUT_DIR=${FLYWHEEL_BASE}/input
mkdir -p ${INPUT_DIR}
OUTPUT_DIR=${FLYWHEEL_BASE}/output
mkdir -p ${OUTPUT_DIR}
CONTAINER='[flywheel/presurgicalreport]'

function error_exit()
{
	echo "$@" 1>&2
	exit 1
}
function parse_config {
  CONFIG_FILE=$FLYWHEEL_BASE/config.json
  MANIFEST_FILE=$FLYWHEEL_BASE/manifest.json

  if [[ -f $CONFIG_FILE ]]; then
    echo "$(cat $CONFIG_FILE | jq -r '.config.'"$1")"
  else
    CONFIG_FILE=$MANIFEST_FILE
    echo "$(cat $MANIFEST_FILE | jq -r '.config.'"$1"'.default')"
  fi
}

# Define inputs
THICKNESS_IMAGE=$(find ${INPUT_DIR}/input_thickness_image -type f | grep .nii)
NORM_AVERAGE="${FLYWHEEL_BASE}/norm/s1_156controls_average.nii.gz"
NORM_STD="${FLYWHEEL_BASE}/norm/s1_156controls_stdev.nii.gz"

# # Z-scoring
# /usr/local/miniconda/bin/python3 ${CODE_BASE}/zscore.py \
#                                       --input_thickness_image ${THICKNESS_IMAGE} \
#                                       --normative_image ${NORMATIVE_IMAGE} \
#                                       --standard_deviation_image ${STD_IMAGE}

# Z-scoring
/bin/bash /flywheel/v0/src/_indivHeatmap.sh ${NORM_AVERAGE} \
																						${NORM_STD} \


# Rendering with workbench
