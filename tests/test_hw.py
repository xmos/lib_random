# Copyright 2025-2026 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import re
import pytest
from pathlib import Path
from filelock import FileLock
import subprocess
import shutil
import sys

"""
This test runs the hardware tests - none at present. Placeholder.
"""

def test_ro(request):
    test_name = "test_ro"

    cwd = Path(request.fspath).parent
    binary = Path(f'{cwd}/{test_name}/bin/{test_name}.xe')
    outfile= Path(f'{cwd}/{test_name}/bin/out.bin')

    assert Path(binary).exists(), f"Cannot find {binary}"

    # Ensure we don't spin up two HW instances at the same time
    with FileLock("xrun.lock"):
        run_cmd = f'xrun --id 0 --io --args {binary} {outfile}'
        print("Running cmd: ", run_cmd)
        stdout = subprocess.check_output(run_cmd, shell = True)

    run_cmd = f'LD_LIBRARY_PATH=../submodules/SP800-90B_EntropyAssessment/cpp:$LD_LIBRARY_PATH  ../submodules/SP800-90B_EntropyAssessment/cpp/ea_iid {outfile}'
    test_output = subprocess.check_output(run_cmd, shell = True)
    print(test_output)

    assert(b'Warning' not in test_output)
    assert(b'Passed chi square tests' in test_output)
    assert(b'Passed length of longest repeated substring test' in test_output)
    assert(b'Passed IID permutation tests' in test_output)
    
