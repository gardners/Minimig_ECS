#!/bin/tcsh -f

cd src
cat ../vivado/${1}_top.tcl
foreach f (vhdl/*.vhd* verilog/*.v)
  echo '"[file normalize "$origin_dir/src/'${f}'"]"\'
end
cat ../vivado/${1}_middle.tcl
foreach f (vhdl/*.vhd*)
echo 'set file "'${f}'"'
echo 'set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]'
echo 'set_property -name "file_type" -value "VHDL" -objects $file_obj'
end
foreach f (verilog/*.v)
echo 'set file "'${f}'"'
echo 'set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file"]]'
echo 'set_property -name "file_type" -value "Verilog" -objects $file_obj'
end
cat ../vivado/${1}_bottom.tcl
