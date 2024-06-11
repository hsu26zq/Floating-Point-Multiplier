`define COUNT 10
`define CYCLE 0.5 // 2 GHz

`include "my_transaction.sv"

import uvm_pkg::*;

class my_driver extends uvm_driver;
  
  integer FILE;

  logic [63:0] A;
  logic [63:0] B;
  logic [63:0] C;
  
  virtual my_interface IN_VIF;
  
  my_transaction TR;
  
  `uvm_component_utils(my_driver)
  function new(string name = "my_driver", uvm_component parent = null);
    super.new(name, parent);
    `uvm_info("my_driver", "new is called", UVM_LOW);
  endfunction
  
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("my_driver", "build_phase is called", UVM_LOW);
    if(!uvm_config_db #(virtual my_interface)::get(this, "", "this_is_input", IN_VIF))
      `uvm_fatal("my_driver", "virtual interface must be set for INPUT VIF");
  endfunction
  
  
  extern virtual task main_phase(uvm_phase phase); // virtual???????
  extern task OPEN_FILE;
  extern task FEED_PATTERN;
endclass 

    task my_driver::main_phase(uvm_phase phase);
      integer i, j;
      phase.raise_objection(this);
      `uvm_info("my_driver", "main_phase is called", UVM_LOW);
      
      OPEN_FILE;
      A = 0;
      B = 0;
      
      @(negedge IN_VIF.CLK); // wait for reset
      @(negedge IN_VIF.CLK);

      for(j = 0; j < `COUNT; j = j + 1) begin
        FEED_PATTERN;
        
        for(i = 0; i < 64; i = i + 1) // wait for at least DUT(55) + CHECK_PATTERN(8) = 63 cycles
          @(posedge IN_VIF.CLK);
      end
    
      `uvm_info("my_driver", "main_phase is drived", UVM_LOW);
      phase.drop_objection(this);
    endtask
    
    task my_driver::OPEN_FILE;
      begin
        FILE = $fopen("../PATTERN.dat", "r");
        if(!FILE) begin
          $display("Unable to Open File.");
          $finish;
        end
      end
    endtask
    
    task my_driver::FEED_PATTERN;
      integer i, CNT;
      begin
        CNT = $fscanf(FILE, "%x", A);
        CNT = $fscanf(FILE, "%x", B);
        CNT = $fscanf(FILE, "%x", C);
        
        for(i = 0; i < 8; i = i + 1)
          @(negedge IN_VIF.CLK) begin
            IN_VIF.VALID = 1'b1;
            IN_VIF.DATA = A[8*i +: 8];
          end
        
        for(i = 0; i < 8; i = i + 1)
          @(negedge IN_VIF.CLK) begin
            IN_VIF.VALID = 1'b1;
            IN_VIF.DATA = B[8*i +: 8];
          end
        
        @(negedge IN_VIF.CLK) IN_VIF.VALID = 1'b0;
      end
    endtask
