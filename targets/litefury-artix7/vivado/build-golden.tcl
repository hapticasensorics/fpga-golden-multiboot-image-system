proc usage {} {
  puts stderr {usage: vivado -mode batch -source build-golden.tcl -tclargs
    [-part PART] [-top TOP] [-out OUTDIR] [-xdc XDC] [-run-synth] [-run-impl]}
  exit 2
}

proc json_escape {value} {
  return [string map {\\ \\\\ \" \\\" \n \\n \r \\r \t \\t} $value]
}

set part "xc7a100tfgg484-2L"
set top "litefury_artix7_goldengate_top"
set outdir "build/litefury-goldengate"
set xdc ""
set run_synth 0
set run_impl 0

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
    -xdc {
      incr i
      set xdc [lindex $argv $i]
    }
    -run-synth {
      set run_synth 1
    }
    -run-impl {
      set run_synth 1
      set run_impl 1
    }
    default {
      usage
    }
  }
}

set script_dir [file dirname [file normalize [info script]]]
set target_dir [file normalize [file join $script_dir ..]]
set repo_root [file normalize [file join $target_dir .. ..]]
if {$xdc eq ""} {
  set xdc [file join $target_dir constraints litefury-goldengate-shell.xdc]
}

file mkdir $outdir
file mkdir [file join $outdir reports]
file mkdir [file join $outdir artifacts]

create_project -force litefury_goldengate $outdir -part $part

set rtl_files [list \
  [file join $repo_root rtl golden_multiboot_controller.sv] \
  [file join $repo_root rtl app_recovery_contract.sv] \
  [file join $repo_root rtl health_telemetry_regs.sv] \
  [file join $target_dir rtl litefury_artix7_icap_multiboot.sv] \
  [file join $target_dir rtl litefury_artix7_goldengate_top.sv] \
]

foreach rtl $rtl_files {
  if {![file exists $rtl]} {
    error "missing RTL file: $rtl"
  }
  read_verilog -sv $rtl
}

if {[file exists $xdc]} {
  read_xdc $xdc
} else {
  error "missing XDC file: $xdc"
}

set_property top $top [current_fileset]
update_compile_order -fileset sources_1

set synth_dcp ""
set bitstream ""
if {$run_synth} {
  synth_design -top $top -part $part
  report_utilization -file [file join $outdir reports synth_utilization.rpt]
  report_timing_summary -file [file join $outdir reports synth_timing_summary.rpt]
  set synth_dcp [file join $outdir artifacts ${top}.synth.dcp]
  write_checkpoint -force $synth_dcp
}

if {$run_impl} {
  opt_design
  place_design
  phys_opt_design
  route_design
  report_utilization -file [file join $outdir reports route_utilization.rpt]
  report_timing_summary -file [file join $outdir reports route_timing_summary.rpt]
  set routed_dcp [file join $outdir artifacts ${top}.routed.dcp]
  set bitstream [file join $outdir artifacts ${top}.bit]
  write_checkpoint -force $routed_dcp
  write_bitstream -force $bitstream
}

set manifest_path [file join $outdir artifacts litefury-golden-build.manifest.json]
set fh [open $manifest_path w]
puts $fh "{"
puts $fh "  \"schema\": \"goldengate.litefury.build_manifest.v1\","
puts $fh "  \"target\": \"litefury-artix7\","
puts $fh "  \"part\": \"[json_escape $part]\","
puts $fh "  \"top\": \"[json_escape $top]\","
puts $fh "  \"xdc\": \"[json_escape $xdc]\","
puts $fh "  \"run_synth\": $run_synth,"
puts $fh "  \"run_impl\": $run_impl,"
puts $fh "  \"synth_dcp\": \"[json_escape $synth_dcp]\","
puts $fh "  \"bitstream\": \"[json_escape $bitstream]\""
puts $fh "}"
close $fh

puts "GoldenGate LiteFury build manifest: $manifest_path"
puts "part=$part"
puts "top=$top"
puts "run_synth=$run_synth"
puts "run_impl=$run_impl"
