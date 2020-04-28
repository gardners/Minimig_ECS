#!/bin/tcsh -f

cd src

if ( "x$1" == "x" ) then
	echo "ERROR: You must provide the target as argument."
	exit
endif
set target=$1
if ( x"$2" != "x" ) then
	set fpga=$2
else
	set fpga=xc7a100tfgg484-1
	if ( -e ${target}/fpga.model ) then
		set fpga=`cat ${target}/fpga.model`
	endif
endif

cat ../vivado/mega65r2_top.tcl | sed 's/mega65r2/'${target}'/g'  | sed 's/xc7a100tfgg484-1/'${fpga}'/g'
foreach f (vhdl/*.vhd vhdl/*.vhdl verilog/*.v ${target}/*.vhd ${target}/*.vhdl )
  echo '"[file normalize "$origin_dir/src/'${f}'"]"\'
end
cat ../vivado/mega65r2_middle.tcl | sed 's/mega65r2/'${target}'/g' | sed 's/xc7a100tfgg484-1/'${fpga}'/g'
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
cat ../vivado/mega65r2_bottom.tcl | sed 's/mega65r2/'${target}'/g' | sed 's/xc7a100tfgg484-1/'${fpga}'/g'
