//------------------------------------------------------//
//- Final Project									                    	//
//													                          	//
//- Floating Point Number Multiplier TestBench		    	//
//------------------------------------------------------//

`timescale 1ns/1ps

`include "../FP_MUL.v"
`include "my_env.sv"
`include "my_interface.sv"

`define CYCLE 0.5 // 2 GHz

module TEST;

  logic		   CLK;
  logic		   RESET;

  my_interface IN_IF(CLK, RESET);
  my_interface OUT_IF(CLK, RESET);
  
  FP_MUL FP_MUL(.CLK(CLK), .RESET(RESET), .ENABLE(IN_IF.VALID), .DATA_IN(IN_IF.DATA),
                .READY(OUT_IF.VALID), .DATA_OUT(OUT_IF.DATA));
  
  initial begin
    uvm_config_db #(virtual my_interface)::set(null, "uvm_test_top.DRIVER", "this_is_input", IN_IF);
   // uvm_config_db #(virtual my_interface)::set(null, "uvm_test_top.DRIVER", "this_is_output", OUT_IF);
    uvm_config_db #(virtual my_interface)::set(null, "uvm_test_top.MONITOR", "this_is_output", OUT_IF);
  end
  
  initial begin
    
    
    /*
    my_driver DRIVER;
    DRIVER = new("DRIVER", null);
    DRIVER.main_phase(null);
    $finish;
    */
    run_test("my_env");
  end
  
  initial begin
    CLK = 0;
  end
  
  always #(`CYCLE/2) CLK = ~CLK;
  
  initial begin
    RESET = 0;
    @(negedge CLK) RESET = 1'b1;
    @(negedge CLK) RESET = 1'b0;
  end
 
endmodule
