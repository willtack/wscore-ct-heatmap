#
# Writes the HTML report containing the scene image and a interactive volume viewer
#
# Author: Will Tackett 3/22/2021

from nilearn import plotting
import jinja2
import os
import glob
import argparse


def get_parser():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work_dir")
    parser.add_argument("--prefix")
    parser.add_argument("--bg_img")
    return parser


def create_html_viewer(work_dir, bg_img):
    wscore_img = glob.glob(work_dir+'/*wscore_img.nii.gz')[0]
    html_view = plotting.view_img(wscore_img, bg_img=bg_img)
    viewer_file_path = os.path.join(work_dir, 'viewer.html')
    html_view.save_as_html(viewer_file_path)

    return os.path.basename(viewer_file_path)


def generate_report(prefix, work_dir, bg_img):
    title = "w-score neurodegeneration heatmap"
    main_section = base_template.render(
        subject_id=prefix,
        volume_viewer=create_html_viewer(work_dir, bg_img)
    )

    # Produce and write the report to file
    with open(os.path.join(work_dir,  "index.html"), "w") as f:
        f.write(main_section)


if __name__ == "__main__":

    # Parse command line arguments
    arg_parser = get_parser()
    args = arg_parser.parse_args()

    # Configure Jinja and ready the templates
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(searchpath="/opt/html_templates")
    )

    # Assemble the templates we'll use
    base_template = env.get_template("report2.html")

    generate_report(args.prefix, args.work_dir, args.bg_img)
