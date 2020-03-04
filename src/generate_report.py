#
# Writes the HTML report containing the scene image and a interactive volume viewer
#
# Author: Will Tackett 3/4/2020

import nilearn
import jinja2

working_dir = os.get_cwd()
output_dir = os.path.join(working_dir, "output")

def create_html_viewer():
        mni_path = os.path.join(working_dir, "resources", "mni152.nii.gz")
        html_view = nilearn.plotting.view_img(img, threshold=0, bg_img=mni_path,
                                              title="")
        html_view.save_as_html(os.path.join(output_dir, "volume_viewer.html"))
        viewer_file = "./output/volume_viewer.html"
        return viewer_file

def generate_report():

    title = "Neurodegeneration Heat Map"
    main_section = base_template.render(
            subject_id = sid,
            png_file = png_file,
            html_viewer = create_html_viewer()
    )

    # Produce and write the report to file
    with open(os.path.join(outputdir, "sub-" + sid + "_report.html"), "w") as f:
        f.write(base_template.render(
            title=title,
            sections=main_section
        ))

if __name__ == "__main__":

    # Configure Jinja and ready the templates
    env = Environment(
        loader=FileSystemLoader(searchpath="templates")
    )

    # Assemble the templates we'll use
    base_template = env.get_template("report.html")
