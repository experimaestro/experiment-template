"""Checks that the experimental plan of each specification is valid"""

import subprocess
import sys
from pathlib import Path

import pytest

EXPERIMENTS = Path(__file__).parent.parent / "experiments"
SPECIFICATIONS = sorted(
    path for path in EXPERIMENTS.glob("*/*.yaml") if path.name != "common.yaml"
)


@pytest.mark.parametrize(
    "specification",
    SPECIFICATIONS,
    ids=[str(path.relative_to(EXPERIMENTS)) for path in SPECIFICATIONS],
)
def test_dry_run(specification: Path, tmp_path: Path):
    subprocess.run(
        [
            sys.executable,
            "-m",
            "experimaestro",
            "run",
            "--run-mode",
            "dry_run",
            "--workdir",
            str(tmp_path),
            str(specification),
        ],
        check=True,
    )
