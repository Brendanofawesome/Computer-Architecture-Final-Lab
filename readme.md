**This is the final lab (LAB 8) for CMPE 140 - Computer Architecture and Design at SJSU**

*To build, simply open the .xpr with Vivado

The purpose of this lab is to implement a full-pipeline MIPS processor with a built-in factorial accelerator. A full list of goals/milestones is:  
    <blockquote><details><summary>[x] five stage pipeline</summary><blockquote>
        [x] instruction fetch stage  
        [x] instruction decode stage  
        [x] instruction execute stage  
        [x] memory access stage  
        [x] register writeback stage</blockquote></details>  
    <details><summary>[x] processor core features</summary><blockquote>
        [x] instruction decoder  
        [x] ALU unit  
        [x] multiplier/divider (optional)  
        [x] registerfile  
        [x] memory controller  
        [x] PC datapath  </blockquote></details>  
    <details><summary>[x] hazard control unit</summary><blockquote>
        [x] Data read after write hazards from registers  
        [x] Data use after read hazards from memory  
        [x] Branching hazards  </blockquote></details>  
    <details><summary>[x] memory-mapped peripheral subsystem (word oriented)</summary><blockquote>
        [x] address decoder to control peripheral write and read  
        [x] 0x00000-0x000FC => data memory address range  
        [x] 0x80000-0x8000C => factorial accelerator address range  
        [x] 0x90000-0x9000C => GPIO address range  </blockquote></details>  
    <details><summary>[x] factorial accelerator</summary><blockquote>
        [x] accepts 4-bit inputs  
        [x] register based control unit  </blockquote></details>  
    <details><summary>[x] GPIO module (64 io pins?)</summary><blockquote>
        [x] register-based control unit  
        [x] 2x 32-bit input registers  
        [x] 2x 32-bit output registers </blockquote></details>  
    <details><summary>[x] tests (for everything)</summary><blockquote>
        [x] processor core  
        [x] entire memory space  
        [x] factorial accelerator  
            [x] compare speed to software factorial  
        [x] GPIO (connect a few to LEDs and switches)  </blockquote></details>
    </blockquote>

Authors:  
- Brendan Parvin  
- Nicholas Nguyen 
- Thinh Nguyen 
- Timothy Fan 
