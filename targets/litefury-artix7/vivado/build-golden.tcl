proc usage {} {
  puts stderr {usage: vivado -mode batch -source build-golden.tcl -tclargs -part PART -top TOP -out OUTDIR}
  exit 2
}

set part ""
set top ""
set outdir "build/litefury-goldengate"

for {set i 0} {$i < [llength $argv]} {incr i} {
  set arg [lindex $argv $i]
  switch -- $arg {
    -part {
      incr i
      set part [lindex $argv $i]
    }
    -top {
      incr i
      set top [lindex $argv $i]
    }
    -out {
      incr i
      set outdir [lindex $argv $i]
    }
    default {
      usage
    }
  }
}

if {$part eq "" || $top eq ""} {
  usage
}

set script_dir [file dirname [file normalize [info script]]]
set target_dir [file normalize [file join $script_dir ..]]
set repo_root [file normalize [file join $target_dir .. ..]]

file mkdir $outdir
create_project -force litefury_goldengate $outdir -part $part

read_verilog -sv [file join $repo_root rtl golden_multiboot_controller.sv]
read_verilog -sv [file join $repo_root rtl app_recovery_contract.sv]
read_verilog -sv [file join $repo_root rtl health_telemetry_regs.sv]
read_verilog -sv [file join $target_dir rtl litefury_artix7_icap_multiboot.sv]

set_property top $top [current_fileset]

puts "GoldenGate LiteFury build scaffold created."
puts "Next target work: add LiteFury constraints, XDMA shell, SPI flash interface, and top wrapper."

