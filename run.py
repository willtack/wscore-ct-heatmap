import sys; print(sys.path)

import sys
import os
import logging
import shutil
from pathlib import PosixPath
import flywheel

# logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('heatmap-gear')
logger.info("=======: HeatMap :=======")


with flywheel.GearContext() as context:
    # Setup basic logging
    context.init_logging()
    config = context.config
    analysis_id = context.destination['id']
    gear_output_dir = PosixPath(context.output_dir)
    run_script = gear_output_dir / "heatmap_run.sh"
    output_root = gear_output_dir / analysis_id
    working_dir = PosixPath(str(output_root.resolve()) + "_work")
    # Get relevant container objects
    fw = flywheel.Client(context.get_input('api_key')['key'])
    analysis_container = fw.get(analysis_id)
    project_container = fw.get(analysis_container.parents['project'])
    session_container = fw.get(analysis_container.parent['id'])
    subject_container = fw.get(session_container.parents['subject'])
    subject_label = subject_container.label

    # Inputs and configs
    ct_image = PosixPath(context.get_input_path('CorticalThicknessImage'))
    ct_image_path = ct_image.as_posix()
    zthresholds = config.get('zthresholds')
    maxz = config.get('maxz')

    thr_list = zthresholds.split(' ')
    print(thr_list)
    if len(thr_list) > 3:
        thr_list=thr_list[0:2] # just pick three if user supplied more than three
    elif 1 <= len(thr_list) < 3:
        thr_list.append(str(thr_list[-1]+1)) # append the last item plus one
    elif len(thr_list) != 3:
        print("Using default thresholds.")
        thr_list = ['1','2','3']
    zthresholds = ' '.join(thr_list)

def write_command():
    """Write out command script."""
    with flywheel.GearContext() as context:
        cmd = [
            '/bin/bash -x',
            '/flywheel/v0/src/indivHeatmap.sh',
             ct_image_path,
             subject_label, "'",
             zthresholds, "'",
             str(maxz)
        ]

    logger.info(' '.join(cmd))
    with run_script.open('w') as f:
        f.write(' '.join(cmd))

    return run_script.exists()

def cleanup():
    results_dir =  os.path.join(gear_output_dir,'results')
    html_dir =  os.path.join(gear_output_dir, subject_label + '_report')
    os.mkdir(html_dir)
    os.chdir(gear_output_dir)
    os.system("cp *.html *.nii.gz *.png {}".format(results_dir))
    os.system("mv results {}".format(subject_label + '_results'))
    os.system("cp *_report.html *.png {}".format(html_dir))
    os.system("rm *.html")
    os.system("zip -r {0}/{1}_results.zip {2}".format(gear_output_dir,subject_label, subject_label + '_results' ))
    os.system("zip -r {0}/{1}_report.zip {2}".format(gear_output_dir,subject_label, subject_label + '_report'))
    os.system("rm -rf heatmap_run.sh results *_results *_report")


def main():
    command_ok = write_command()
    if not command_ok:
        logger.warning("Critical error while trying to write run command.")
        return 1
    os.system("chmod +x {0}".format(run_script))
    os.system(run_script)
    os.system("python src/generate_report.py {0}".format(subject_label))
    cleanup()
    return 0


if __name__ == '__main__':
    sys.exit(main())
