# Create a library
alib work
# Compile the simulation file list
vcom -2002 a1_cpu.vhdl de2_115.vhdl 

# Initialize
asim -relax -O5 +access +r +m+A1_CPU A1_CPU RTL

clear -log
run 7000 ns			

# Quit the simulation
endsim
# End