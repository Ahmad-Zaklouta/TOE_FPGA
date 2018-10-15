#! /usr/bin/env python3
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2018, Lars Asplund lars.anders.asplund@gmail.com

import os
from vunit import VUnit

os.environ["VUNIT_VHDL_STANDARD"] = "2008"

root = os.path.dirname(__file__)

ui = VUnit.from_argv()
ui.add_com()
lib = ui.add_library("lib")
lib.add_source_files("*.vhdl")
lib.add_source_files("../src/*.vhdl")
#lib.set_compile_option("ghdl.flags", ["--std=93c"])
#lib.set_sim_option("ghdl.elab_flags", ["--std=93c"])
lib.set_sim_option("ghdl.sim_flags", ["--stop-time=1ms"])
ui.main()
