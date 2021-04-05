#
# Script for generating csvs of summary statistics for each label of each subject's ct map
# Adapted from getVals.R
#

import pandas as pd
import numpy as np
import ants
import os
import glob


def get_vals(label_index_file, label_image_file, outcome_image_file):
    """
    Generate a csv containing mean, median, etc. for cortical thickness outcomes.

    Args:
        label_index_file (str): path to csv indexing labels (e.g. V1 is 1)
        label_image_file (str): path to segmentation image in subject space
        outcome_image_file (str): path to cortical thickness file in subject space

    Returns:
        A pandas DataFrame containing the appropriate data

    """

    labs_df = pd.read_csv(label_index_file)  # read in label index file
    header_list = list(labs_df)  # get names of columns already in dataframe
    summvar = ['mean', 'std', 'min', '25%', '50%', '75%',
               'max']  # order is CRUCIAL and dependent on order of pandas df.describe()
    labs_df = labs_df.reindex(columns=header_list + summvar + ['volume'])  # add summvar columns with NaNs
    nround = 6  # digits to round to

    # load images with ANTs 
    label_mask = ants.image_read(label_image_file, 3)
    outcome = ants.image_read(outcome_image_file, 3)
    hdr = ants.image_header_info(label_image_file)
    voxvol = np.prod(hdr['spacing'])  # volume of a voxel (e.g. 1mm^3)

    for i in range(len(labs_df)):
        labind = labs_df['label_number'][i]  # get label index, e.g. V1 is 1, etc.
        # flatten label image to 1D array (order=Fortran), create array
        w = np.where(label_mask.numpy().flatten(order='F') == labind)[0]
        if len(w) > 0:
            x = outcome.numpy().flatten(order='F')[w]  # get cortical thickness vals for voxels in current label
            # write summary variables into label dataframe
            desc = pd.DataFrame(x).describe()
            desc_list = desc[0].to_list()[1:]  # omit 'count' field
            labs_df.loc[i, summvar] = desc_list
            labs_df["volume"][i] = voxvol * len(w)
        else:
            # pad with 0s
            labs_df.loca[i, summvar] = [0] * len(summvar)
            labs_df["volume"][i] = 0

    #         print("{} {} ".format(labs_df["label_number"][i], labs_df["volume"][i]))

    # Round summary metrics
    for v in summvar:
        labs_df.loc[:, v] = round(labs_df.loc[:, v], nround)

    # un-pivot dataframe so each statistic (value_vars) has its own row, keeping id_vars the same
    labs_df_melt = pd.melt(labs_df, id_vars=['label_number', 'label_abbrev_name',
                                             'label_full_name', 'hemisphere'], value_vars=summvar + ['volume'], var_name='type')

    return labs_df_melt


# local_dir = '/media/will/My Passport/Ubuntu/cortical_thickness_maps/ct'
local_dir = '/home/will/Projects/healthy-t1-dataset/test_sub'
label_idx_file = '/home/will/Projects/healthy-t1-dataset/labels/Schaefer2018_200Parcels_17Networks_order.csv'

# Loop through subject directories
for subject in os.listdir(local_dir):
    print("PROCESSING: " + subject)
    subdir = os.path.join(local_dir, subject)
    label_img_file = glob.glob(subdir + '/*Schaefer2018*')[0]  # glob returns a list
    outcome_file = glob.glob(subdir + '/*CorticalThickness.nii.gz')[0]
    dataframe = get_vals(label_idx_file, label_img_file, outcome_file)
    dataframe.to_csv(os.path.join(subdir, "sub-" + subject + "_" + "schaefer.csv"), index=False)
