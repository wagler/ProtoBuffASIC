# ProtoBuffASIC

Serializes a C++ object instance of a Protobuf generated C++ class.

## How to run simulation testbenches
This will require you have Synopsys VCS, so use a CAEN machine. You may need to run "module load vcs" first.
Tests can be run by going into the Makefile and setting the testbench file to one of the testbenches in the testbench/ directory.
The default testbench is the top level module testbench. The 'tests' directory has testcase supporting files such as real C++ object dumps and their associated message object tables, which we have created.

## How to synthesize the SystemVerilog models
This will require you have Synopsys DC, so use a CAEN machine. 
Go into the synth folder and run "dc_shell-t -f <module_name>.tcl".
This will generate the .vg netlist and a .rep report file.

