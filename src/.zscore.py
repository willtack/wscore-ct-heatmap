#
# Take a cortical thickness map as input and perform some simple image math to
# normalize the values (i.e. do a z-standardization)
#
# Will Tackett 2/5/2020

import nipype.interfaces.fsl as fsl

arg_parser = argparse.ArgumentParser(
        description="Take a cortical thickness map as input and perform some  \
        simple image math to normalize the values (i.e. do a z-standardization)")
parser.add_argument(
    "--input_thickness_image",
    help="path to a cortical thickness image to be standardized",
    required=True
)
parser.add_argument(
    "--normative_image",
    help="path to normative thickness image",
    required=True
)
parser.add_argument(
    "--standard_deviation_image",
    help="path to normative thickness image",
    required=True
)


def convert_to_zscore(input_img, norm_img, std_img):
    # First, calculate a standard deviation
    # std_run = fsl.ImageMaths.StdImage(in_file=input_img)
    # std_run.run()

    # Next, convert to z-score
    diff_stat = fsl.ImageMaths(op_string=' %s -sub %s' % (input_img, norm_img))
    diff_run = diff_stat.run()
    difference_img = diff_run.outputs.out_file
    zscore_img = fsl.ImageMaths(op_string=' %s -div %s' % (difference_img, std_img))
    return zscore_img


if __name__ == "__main__":

    args = arg_parser.parse_args()
    input_img = args.input_thickness_image
    norm_img = args.normative_image
    std_img = args.standard_deviation_image

    zscore_img = convert_to_zscore(input_img, norm_img, std_img)
