"""
Run script for calculating w-scores in Schaefer 200x17 atlas labels for a single patient.

Inputs
------
        label_index_file (str): path to csv indexing labels (e.g. V1 is 1)
        label_image_file (str): path to segmentation image in subject space
        ct_image_file (str): path to cortical thickness file in subject space
        t1_image_file (str): path to T1 image
        patient_age (float): age of patient in years
        prefix (str): string to use as file prefix
        output_dir (str): path to output directory
        TODO: patient_sex (str): sex of patient ('M' or 'F')


Contains the following functions:
    * get_parser - Creates an argument parser with appropriate input
    * get_vals - Generates a csv containing mean, median, etc. for cortical thickness outcomes.
    * render_image - Renders a w-score visualization in subject space
    * main - Main function of the script


"""

import pandas as pd
import numpy as np
import ants
import os
import glob
import argparse
import logging

# logging stuff
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('')


def get_parser():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--label_index_file",
        # help="path to csv indexing labels (e.g. V1 is 1)",
        required=True
    )
    parser.add_argument(
        "--label_image_file",
        # help="path to segmentation image in subject space",
        required=True
    )
    parser.add_argument(
        "--ct_image_file",
        # help="path to cortical thickness file in subject space",
        required=True
    )
    parser.add_argument(
        "--t1_image_file"
    )
    parser.add_argument(
        "--patient_age",
        type=float,
        # help="age of patient in years",
        required=True
    )
    parser.add_argument(
        "--prefix",
        # help="string to use as file prefix",
        required=True
    )
    parser.add_argument(
        "--output_dir"
    )

    return parser


def get_vals(label_index_file, label_image_file, ct_image_file):
    """
    Generate a csv containing mean, median, etc. for cortical thickness outcomes.

    Args:
        label_index_file (str): path to csv indexing labels (e.g. V1 is 1)
        label_image_file (str): path to segmentation image in subject space
        ct_image_file (str): path to outcome file (i.e. cortical thickness) in subject space

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
    outcome = ants.image_read(ct_image_file, 3)
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


def render_image(wscore_dataframe, label_img, working_dir, prefix, output_dir):
    """
    Render an image in subject space with the w-score in place of the corresponding label number at the voxel level

    Args:
        wscore_dataframe (DataFrame) - Pandas DataFrame containing the w-score for each label for the patient
        label_img (str): path to the label image file
        working_dir (str): directory to do calculations in
        prefix (str): string to use as file prefix
        output_dir (str): directory to save outputs to
    Returns

    """
    # loop through rows for ROI index (lbli) and wscore
    # use fslmaths to convert label index numbers to corresponding w-score for all voxels in ROI
    for index, row in wscore_dataframe.iterrows():
        wscore = row['w-score']
        lbli = int(row['label_number'])
        # create temporary image for each ROI with w-score as value
        tmp_output = os.path.join(working_dir, 'tmp{}.nii.gz'.format(lbli))
        cmd = "fslmaths '{0}' -thr {1} -uthr {2} -div {3} -mul {4} '{5}'".format(label_img, lbli - .5, lbli + .5, lbli, wscore,
                                                                                 tmp_output)
        print(cmd)
        os.system(cmd)

    # merge all temporary ROI images together
    image_list = glob.glob(os.path.join(working_dir, "tmp*.nii.gz"))
    images_str = ' -add '.join(
        '"{0}"'.format(img) for img in image_list)  # string paths together, with single quotes around file paths
    cmd2 = "fslmaths {} {}/{}_wscore_img.nii.gz".format(images_str, output_dir, prefix)
    print(cmd2)
    os.system(cmd2)

    # remove temporary files
    cmd3 = "rm '{}'/tmp*.nii.gz".format(working_dir)
    print(cmd3)
    os.system(cmd3)


def main():

    # Parse command line arguments
    arg_parser = get_parser()
    args = arg_parser.parse_args()
    # output_dir = '/home/will/Projects/healthy-t1-dataset/test_sub/118785/output'
    output_dir = args.output_dir
    logger.info("Set output directory to {}".format(output_dir))
    # Calculate ct metrics for patient and save to csv
    logger.info("Calculating cortical thickness metrics...")
    pt_data = get_vals(args.label_index_file, args.label_image_file, args.ct_image_file)
    pt_data = pt_data[pt_data.type == "mean"]  # just use the mean
    pt_data.to_csv(os.path.join(output_dir, args.prefix + "_schaefer.csv"), index=False)
    # pt_data = pd.read_csv(metrics_csv)
    # get index label numbers
    label_idxs = pd.read_csv(args.label_index_file)
    indices = list()
    for ind in range(0, len(label_idxs)):
        i = label_idxs.label_number[ind]
        indices.append(i)

    # w-score calculation | outputs a pd DataSeries
    logger.info("Calculating w-scores for each region of atlas...")
    pt_age = args.patient_age
    ws_coffs = pd.read_csv('/opt/labelset/ws_coeffs.csv')  # w-score coefficients for norm data
    wscores = (pt_data.value - ws_coffs.intercept - pt_age*ws_coffs.age_coefficient)/ws_coffs.residual_se

    # save to DataFrame
    logger.info("Saving w-score results to Dataframe and csv...")
    d = {'label_number': indices, 'w-score': list(wscores)}
    wscore_df = pd.DataFrame(data=d)
    # add actual ROI names to wscore spreadsheet
    wscore_df.insert(1, "label_full_name", pt_data['label_full_name'], True)
    wscore_df.to_csv(os.path.join(output_dir, args.prefix + "_wscores.csv"), index=False)

    # render an image
    logger.info("Rendering a w-score image...")
    working_dir = os.path.join(output_dir, 'work')
    os.makedirs(working_dir, exist_ok=True)
    render_image(wscore_df, args.label_image_file, working_dir, args.prefix, output_dir)

    # generate report
    logger.info("Generating html report...")
    os.system("python /opt/scripts/generate_report.py --work_dir {} --prefix {} --bg_img {}".format(output_dir, args.prefix, args.t1_image_file))
    logger.info("python /opt/scripts/generate_report.py --work_dir {} --prefix {} --bg_img {}".format(output_dir, args.prefix, args.t1_image_file))
    logger.info("Script complete.")

    # delete work folder
    os.system("rm -rf {}".format(working_dir))


if __name__ == "__main__":
    main()
