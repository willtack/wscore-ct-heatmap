#!/usr/local/miniconda/bin/python
import sys
import logging
import shutil
from zipfile import ZipFile
from pathlib import PosixPath
from fw_heudiconv.cli import export
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

def write_command():
    """Write out command script."""
    with flywheel.GearContext() as context:
        cmd = [
            '/usr/bin/bash',
            '/flywheel/v0/src/indivHeatmap.sh',
             context.get_input('CorticalThicknessImage'),
             subject_label
        ]

    logger.info(' '.join(cmd))
    with run_script.open('w') as f:
        f.write(' '.join(cmd))

    return run_script.exists()


def main():

    command_ok = write_command()
    if not command_ok:
        logger.warning("Critical error while trying to write fmriprep command.")
        return 1

    return 0


if __name__ == '__main__':
    sys.exit(main())
