# PrimeAndCompositeTautology

## Overview
The goal of this project is to generate a CNF that is difficult for SAT solvers to solve. Specifically, the aim is to demonstrate that there exists an exponential lower bound on the number of proof steps in the Set Propagation Redundancy (SPR) proof system .


## Features
- Language: Yosys + ABC are used to generate a CNF from Verilog code.

- Proposition: The CNF represents the proposition that "there are no numbers that are both prime and composite" among n-bit natural numbers. This proposition is logically true and demonstrates that no solution exists.

- Prime Check: [Pratt's theorem](https://www.cmi.ac.in/~ramprasad/lecturenotes/comp_numb_theory/lecture17.pdf) (for primality proofs) is used to check whether a natural number is prime.
## Challenges
- Impact of Optimization: Due to optimizations performed by Yosys, the generated CNF is often simplified, which allows the CDCL SAT solver to solve the problem relatively quickly.

- Generation Time: Generating the CNF can take an extremely long time. For example, it takes several minutes for 4-bit numbers, several hours for 5-bit numbers, and for 6-bit numbers, the process does not finish even after a full day, leading to the termination of the task.

This repository publishes an attempt to generate difficult CNFs, and it also highlights the existing challenges and areas for improvement. Feedback from interested users is welcome.
