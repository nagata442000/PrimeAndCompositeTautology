make_cnf:
	yosys -p "read_verilog prime_and_composite.v ; synth -flatten ; techmap ; write_blif prime_and_composite.blif"
	abc -c 'read_blif prime_and_composite.blif ; strash ; dch ; write_cnf prime_and_composite.cnf'
	
clean:
	rm abc.history prime_and_composite.blif prime_and_composite.cnf
