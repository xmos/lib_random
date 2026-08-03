# Copyright 2025-2026 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.

from pathlib import Path
import subprocess
import sys

def test_xsim(request):
    bin_path = Path(__file__).parent / "test_pr" / "bin"
    run_cmd = "xsim " + "--args " +  str(bin_path) + f"/test_pr.xe"
    stdout = subprocess.check_output(run_cmd, cwd = bin_path, shell = True)
    print(stdout)
    assert(b'PASS\n' == stdout)
