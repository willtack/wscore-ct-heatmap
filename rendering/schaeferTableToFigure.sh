#!/bin/bash

if [[ $# -lt 1 ]]; then
cat <<USAGE

	$0 -f < schaefer label name or number and new numbers file > -r < schaefer scale >  -other_flags

	Outputs R/L.surf.gii, .scene, and .png file, min and max value text files

   Required input

	-f: file		Space-delimited file with schaefer label name/number in first column and value to replace it with in second column.

	-r: Schaefer_Scale	Resolution of Schaefer scale to use (schaefer100x7, schaefer100x17, schaefer200x7, schaefer200x17, schaefer300x7, schaefer300x17, schaefer400x7, schaefer400x17)

    Options

	-i: surface		Which surface to use for display (inflated, orig, pial, white)
				Default is white

	-s: show scale		If "1" then displays a color scale bar in the .png file
				Default is off

	-b: binarize 		Make a binary rendering
				Default is 0, 1 to turn it on

	-n: invert your signs   Flip the signs of all entries in your value column. Can help with color scales.
				Default is 0, 1 to turn it on

	-l: low threshold	Lowest value to display on your rendering. Values below this will be null.
				Defaults to minimum value in your input file

	-h: high scaling	Highest value to display on your rendering. Values above this will have same intensity as this value.
				Defaults to maximum value in your input file

	-c: color		Use any color from wb_view presets
				"easy" options are 'red', 'blue' (blue-lightblue), or 'gray'
				Default is "red": ROY-BIG-BL
  				To get a list of all available palettes, use "-c help "

	-e: png height		Input height of desired PNG
				Default is 880

	-w: png width 		Input width of desired PNG
				Default is 910

	-u: underlay file	Formatted like the input file, but for a grayscale "underlay"

	-v: views to render	Show only lateral ("l") or only medial ("m") surfaces, or both ('ml' or 'lm')
				Default is both 'ml'/'lm'
				'l' to select lateral only
				'm' to select medial only

	-x: hemispheres 	Show only right ('r') or only left ('l') hemisphere, or both ('rl' or 'lr')
				Default is both 'rl'/'lr'
				'l' to select left only
				'r' to select right only

	-k: auto-display	Turn off(/on) automatic ImageMagick display of image upon completion ('0' to turn off, '1' is on)
				Default is on ('1')

	Notes: -adjust -l/-h  to manipulate your color scale
	       -all files are output in the same directory as the input file

	Output: .png file of the rendering, .scene file (which can be opened with wb_view for modification), gii files, and text files with the min and max values


USAGE

exit 1

fi

basedir=/opt/rendering
wbdir=/usr/share/workbench/bin_linux64

#Default variables
height=880
width=910
scene=1
color=ROY-BIG-BL
mode=MODE_USER_SCALE
inflate=white
values=0
hemis=rl
views=ml
min=""
max=""
zrro=0
underlayfile=""
template=${basedir}/data/lausanne_rendering.scene
lausannescale=""
bin="0"
invert="0"
disp=1

# While loop to read through the flags. The flags are checked with case statements.
# while :; do
while getopts "f:r:i:e:w:s:c:z:b:n:l:h:u:v:x:k:" OPT
  do
    case $OPT in
		f) # --file) #Takes the .nii file. Replaces template files with the outputted files in the template using a sed command.
			fileinput=$OPTARG
			;;

		r) # --lausanne_scale
			lausannescale=$OPTARG
			;;

		i) # |--inflated) #Replaces midthickness instances in the template with inflated using sed command.
			inflate=$OPTARG
			# shift 1
			;;

		e) # --png_height) # Takes the input after the flag and stores it as the height variable, which will be used later
	 		height=$OPTARG
			;;

		w) # --png_width) # Takes the input after the flag and stores it as the width variable, which will be used later
			width=$OPTARG
			;;

		s) # --scale) # The second scene has the scale included. The scene variable will be used later
		     	if [[ $OPTARG -gt 0 ]] ; then
		    	  scene=2
		  	fi
			;;

		b) # binarize your input
			bin=$OPTARG
			;;

		n) # invert your signs
			invert=$OPTARG
			;;

		l) # The minimum value to show in the figure
			min=$OPTARG
			;;

		h) # The maximum value to show in the figure
			max=$OPTARG
			;;

		c) # --color) # Edits the R/L palettes according to the user's input.
			color=$OPTARG
			;;

		u) # Underlay file
			underlayfile=$OPTARG
			;;
		v) # View lateral/medial
			views=$OPTARG
			;;
		x) # View right/left
			hemis=$OPTARG
			;;
		k) # automatically display results
			disp=$OPTARG
			;;

		*) # When there's no more options, breaks out of the loop
		  echo "Invalid option -$OPT $OPTARG. Run with no options selected to see usage information "
	          exit 1
                  ;;

	esac

done

if [[ ! -f ${fileinput} ]] ;
  then
    echo "Error --file requires a filename"
    exit 1
  fi

# check lausanne_scale is legal
# if [[ "$lausannescale" != "lausanne33" ]] && [[ "$lausannescale" != "lausanne60" ]] && [[ "$lausannescale" != "lausanne125" ]] && [[ "$lausannescale" != "lausanne250" ]] ; then

 if [[ "$lausannescale" != "schaefer100x7" ]] && [[ "$lausannescale" != "schaefer200x7" ]] && [[ "$lausannescale" != "schaefer300x7" ]] && [[ "$lausannescale" != "schaefer400x7" ]] && [[ "$lausannescale" != "schaefer100x17" ]] && [[ "$lausannescale" != "schaefer200x17" ]] && [[ "$lausannescale" != "schaefer300x17" ]] && [[ "$lausannescale" != "schaefer400x17" ]] ; then
  echo "You have to input : "
  echo "     -r schaefer_scale set to schaefer100x7, schaefer100x17 or 200, 300, 400 "
  exit 1
fi

# check surface projection is legal
if [[ "$inflate" != "white" ]] && [[ "$inflate" != "pial" ]] && [[ "$inflate" != "inflated" ]] && [[ "$inflate" != "orig" ]] ; then
  echo "-i set surface to white, pial, inflated, or orig ; default white"
  exit 1
fi

# colors
if [[ "$color" == "red" ]] ;
  then
    color="ROY-BIG-BL"
  elif [[ "$color" == "blue" ]] ;
  then
    color="blue-lightblue"
  elif [[ "$color" == "grey" ]] ;
  then
    color="Gray_Interp_Positive"
  elif [[ "$color" == "help" ]] ;
  then echo "
      ROY-BIG-BL
      videen_style
      Gray_Interp_Positive
      Gray_Interp
      RBGYR20
      RBGYR20P
      Orange-Yellow
      red-yellow
      blue-lightblue
      FSL
      power_surf
      fsl_red
      fsl_green
      fsl_blue
      fsl_yellow
      JET256
      PSYCH
      PSYCH-NO-NONE
      ROY-BIG
      clear_brain
      fidl
      raich4_clrmid
      raich6_clrmid
      HSB8_clrmid
      POS_NEG "
      exit 1
fi

# get file i/o stuff set up
echo $fileinput
fileraw=`readlink -e $fileinput`
input=${fileraw%.txt}
fstem=$(echo $input | rev | cut -d '/' -f1 | rev )
fpath=$(echo $input | rev | cut -d '/' -f2- | rev )

# helper script directories
rendir="/opt/rendering/data"
otherrendir="/opt/rendering/scripts"

if [[ $bin == "1" ]] ; then
  # binarize
  echo " binarizing .... "
  ${otherrendir}/surf_baselayer.R $fileinput ${fstem}
  fstem=${fstem}_binary
  freplace=${fstem}.func.gii
  if [[ -f lh.${freplace} || -f rh.${freplace} ]] ; then
    rm lh.${freplace} -f rh.${freplace}
  fi
  ${rendir}/surf_schaefer.R ${fstem}.txt $lausannescale ${fstem}
  freplace=${fstem}.func.gii
  min=1
  max=1
elif [[ $invert == "1" ]] ; then
 # invert
  echo " ... inverting .... "
    ${otherrendir}/surf_invert.R $fileinput ${fstem}
    # bring the func
    fstem=${fstem}_inverted
    freplace=${fstem}.func.gii
    if [[ -f lh.${freplace} || -f rh.${freplace} ]] ; then
      rm lh.${freplace} -f rh.${freplace}
    fi
    ${rendir}/surf_schaefer.R ${fstem}.txt $lausannescale ${fstem}
    ${otherrendir}/surf_min_max.R ${fstem}.txt ${fstem}
else
  echo " not binaizing or inverting"
   # make func files
    freplace=${fstem}.func.gii
    if [[ -f lh.${freplace} || -f rh.${freplace} ]] ; then
      rm lh.${freplace} -f rh.${freplace}
    fi
    rcmd="${rendir}/surf_schaefer.R $fileinput $lausannescale ${fstem}"
    echo $rcmd
    $rcmd
    # get min and max of included values
    ${otherrendir}/surf_min_max.R $fileinput ${fstem}
fi


# underlay names
if [[ $underlayfile != "" ]] ; then
  ufileraw=`readlink -e $underlayfile`
  uinput=${ufileraw%.txt}
  ustem=$(echo $uinput | rev | cut -d '/' -f1 | rev )
  upath=$(echo $uinput | rev | cut -d '/' -f2- | rev )
  # binarize underlay image
  ${otherrendir}/surf_baselayer.R $underlayfile ${ustem}
  # get the underlay func
  ${rendir}/surf_schaefer.R ${ustem}_binary.txt $lausannescale ${ustem}_binary
  ureplace=${ustem}_binary.func.gii
fi

# get min and max values if none input, otherwise set them
if [[ $min == "" ]] ; then
  min=`cat ${fstem}_min`
else
  min=$min
fi
if [[ $max == "" ]] ; then
  max=`cat ${fstem}_max`
else
  max=$max
fi

# replace top layers with your new files
rdummyfile="\/opt\/rendering\/data\/rh.lausanne33.func.gii"
ldummyfile="\/opt\/rendering\/data\/lh.lausanne33.func.gii"
sed "s/${rdummyfile}/rh.${freplace}/g" < $template > ${fstem}.scene
sed -i "s/${ldummyfile}/lh.${freplace}/g" ${fstem}.scene

# if specified, change surface to other "inflation" level
if [[ "${inflate}" != "white" ]] ;  then
  inflatefull=${inflate}.surf.gii
  echo $inflatefull
  sed -i "s/white.surf.gii/${inflatefull}/g" ${fstem}.scene
  sed -i "s/pial.surf.gii/${inflatefull}/g" ${fstem}.scene
  sed -i "s/orig.surf.gii/${inflatefull}/g" ${fstem}.scene
fi

if (( $(echo "$min >= 0" | bc -l) && $(echo "$max > 0" | bc -l) )) ; then
  neg=FALSE
  pos=TRUE
  ${wbdir}/wb_command -metric-palette lh.${freplace} ${mode} -palette-name ${color} -disp-neg ${neg} -disp-pos ${pos} -pos-user ${min} ${max}
  ${wbdir}/wb_command -metric-palette rh.${freplace} ${mode} -palette-name ${color} -disp-neg ${neg} -disp-pos ${pos} -pos-user ${min} ${max}
elif (( $(echo "$min < 0" | bc -l) && $(echo "$max > 0" | bc -l) )) ; then
  neg=TRUE
  pos=TRUE
  ${wbdir}/wb_command -metric-palette lh.${freplace} ${mode} -palette-name ${color} -disp-neg ${neg} -disp-pos ${pos} -pos-user ${zrro} ${max} -neg-user ${zrro} ${min}
  ${wbdir}/wb_command -metric-palette rh.${freplace} ${mode} -palette-name ${color} -disp-neg ${neg} -disp-pos ${pos} -pos-user ${zrro} ${max} -neg-user ${zrro} ${min}
elif (( $(echo "$min > 0" | bc -l) && $(echo "$max < 0" | bc -l) )) ; then
  neg=TRUE
  pos=TRUE
  ${wbdir}/wb_command -metric-palette lh.${freplace} ${mode} -palette-name ${color} -disp-neg ${neg} -disp-pos ${pos} -pos-user ${zrro} ${max} -neg-user ${zrro} ${max}
  ${wbdir}/wb_command -metric-palette rh.${freplace} ${mode} -palette-name ${color} -disp-neg ${neg} -disp-pos ${pos} -pos-user ${zrro} ${max} -neg-user ${zrro} ${max}
elif (( $(echo "$min < 0" | bc -l) && $(echo "$max <= 0" | bc -l) )) ; then
  neg=TRUE
  pos=FALSE
  ${wbdir}/wb_command -metric-palette lh.${freplace} ${mode} -palette-name ${color} -disp-neg ${neg} -disp-pos ${pos} -pos-user ${zrro} ${max} -neg-user ${zrro} ${min}
  ${wbdir}/wb_command -metric-palette rh.${freplace} ${mode} -palette-name ${color} -disp-neg ${neg} -disp-pos ${pos} -pos-user ${zrro} ${max} -neg-user ${zrro} ${min}
elif (( $(echo "$min == 0" | bc -l) && $(echo "$max == 0" | bc -l) )) ; then
  neg=TRUE
  pos=TRUE
  ${wbdir}/wb_command -metric-palette lh.${freplace} ${mode} -palette-name ${color} -disp-neg ${neg} -disp-pos ${pos} -pos-user ${zrro} ${max} -neg-user ${zrro} ${min}
  ${wbdir}/wb_command -metric-palette rh.${freplace} ${mode} -palette-name ${color} -disp-neg ${neg} -disp-pos ${pos} -pos-user ${zrro} ${max} -neg-user ${zrro} ${min}
  echo "you have all zeros"
else
  echo " you broke my logic with your min and max values ...exiting"
  exit 1
fi

# if underlay then change those
if [[ -f "lh.${ureplace}" ]] ; then
  scene=$(( $scene + 2 ))
  rudummyfile="\/opt\/rendering\/data\/rh.v2lausanne33.func.gii"
  ludummyfile="\/opt\/rendering\/data\/lh.v2lausanne33.func.gii"
  sed -i "s/${ludummyfile}/lh.${ureplace}/g" ${fstem}.scene
  sed -i "s/${rudummyfile}/rh.${ureplace}/g" ${fstem}.scene
  ${wbdir}/wb_command -metric-palette lh.${ureplace} ${mode} -palette-name Gray_Interp -disp-neg TRUE -disp-pos TRUE -pos-user 0 0 -neg-user 0 0
  ${wbdir}/wb_command -metric-palette rh.${ureplace} ${mode} -palette-name Gray_Interp -disp-neg TRUE -disp-pos TRUE -pos-user 0 0 -neg-user 0 0
fi

# mess with hemispheres
if [[ $hemis == "l" ]] ; then
  sed -i "s/m_rightEnabled\">true/m_rightEnabled\">false/g" ${fstem}.scene
  height=$(( $height / 2 ))
elif [[ $hemis == "r" ]] ; then
  sed -i "s/m_leftEnabled\">true/m_leftEnabled\">false/g" ${fstem}.scene
  height=$(( $height / 2 ))
fi

# mess with hemispheres
if [[ $views == "l" ]] ; then
  sed -i "s/m_medialEnabled\">true/m_medialEnabled\">false/g" ${fstem}.scene
  if [[ $hemis == "l" ]] || [[ $hemis == "r" ]] ; then
     width=$(( $width / 2 ))
  else
     height=$(( $height / 2 ))
  fi
elif [[ $views == "m" ]] ; then
  sed -i "s/m_lateralEnabled\">true/m_lateralEnabled\">false/g" ${fstem}.scene
  if [[ $hemis == "l" ]] || [[ $hemis == "r" ]] ; then
     width=$(( $width / 2 ))
  else
     height=$(( $height / 2 ))
  fi
fi

# finally
${wbdir}/wb_command -show-scene ${fstem}.scene $scene ${fstem}_${min}.png $width $height

echo
echo "$fileinput with $lausannescale scaled from $min $max "
echo
# show er no
if [[ $disp != "0" ]] ; then
  display ${fstem}.png &
fi
