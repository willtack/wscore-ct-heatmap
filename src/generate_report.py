#
# Writes the HTML report containing the scene image and a interactive volume viewer
#
# Author: Will Tackett 3/4/2020

from nilearn import plotting
import jinja2
import sys
import os
import glob

working_dir = os.getcwd()
output_dir = os.path.join(working_dir, "output")
inter_dir = os.path.join(output_dir, "intermediates")

sid = sys.argv[1]

def create_html_viewer():
    vol_path = os.path.join(output_dir, sid + "_ctxNormToMNI_indivHeatmap.nii.gz")
    os.system("bash -x /flywheel/v0/src/buildViewer.sh {}".format(vol_path))
    viewer_file = "volume_viewer.html"
    return viewer_file

def create_surface_viewer():
    surf_view = plotting.view_img_on_surf(os.path.join(output_dir, sid + "_ctxNormToMNI_indivHeatmap.nii.gz"),
                                           black_bg=True,
                                           surf_mesh='fsaverage5')
    surf_view.save_as_html(os.path.join(output_dir, 'surf_viewer.html'))
    with open(os.path.join(output_dir, 'surf_viewer.html'), 'r') as file:
         data = file.read()
    return data

def generate_report():
    png_list = glob.glob('/flywheel/v0/output/*.png')
    png_list.sort()
    thr = []
    for idx, file in enumerate(png_list):
        basename = os.path.basename(file)
        png_list[idx] = basename # change the list item to be the basename
        thr_item = basename.split("_")[-1].split(".")[0] # parse the threshold value from the filename
        if len(thr_item) > 1:
            thr_item = thr_item[0] + '.' + thr_item[1:]
        else:
            thr_item = thr_item[0] + '.' + '0'
        thr.append(thr_item)
    title = "Neurodegeneration Heat Map"
    main_section = base_template.render(
            subject_id = sid,
            png_list = png_list,
            thr = thr,
            surf_viewer = create_surface_viewer(),
            volume_viewer = create_html_viewer()
    )

    # Produce and write the report to file
    with open(os.path.join(output_dir, "sub-" + sid + "_report.html"), "w") as f:
        f.write(main_section)

if __name__ == "__main__":

    # Configure Jinja and ready the templates
    env = jinja2.Environment(
        loader=jinja2.FileSystemLoader(searchpath="templates")
    )

    # Assemble the templates we'll use
    base_template = env.get_template("report.html")

    generate_report()
