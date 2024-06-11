`define COUNT 10
`define CYCLE 0.5 // 2 GHz

import uvm_pkg::*;

class my_monitor extends uvm_monitor;
  
  integer FILE;
  integer j;
  
  logic [63:0] A;
  logic [63:0] B;
  logic [63:0] Z;
  logic [63:0] C;
  
  `uvm_component_utils(my_monitor)
  function new(string name = "my_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual my_interface OUT_VIF;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db #(virtual my_interface)::get(this, "", "this_is_output", OUT_VIF))
    `uvm_fatal("my_monitor", "virtual interface must be set for OUTPUT VIF");
  endfunction
  
  extern task main_phase(uvm_phase phase);
  extern task OPEN_FILE;
  extern task CHECK_PATTERN;
  extern task SHOW_PATTERN;
    
endclass
    
    
    task my_monitor::main_phase(uvm_phase phase);
      OPEN_FILE;
      for(j = 0; j < `COUNT; j = j + 1) begin
        CHECK_PATTERN;
      end
      
      $display("\n");
      $display("**********************************************************************");
      $display("******************************* Pass ! *******************************");
      $display("**********************************************************************");
      $display("\n");
    
    endtask
    
    task my_monitor::OPEN_FILE;
      begin
        FILE = $fopen("PATTERN.dat", "r");
        if(!FILE) begin
          $display("Unable to Open File.");
          $finish;
        end
      end
    endtask

    
    task my_monitor::CHECK_PATTERN;
      integer i, CNT;
      begin
        CNT = $fscanf(FILE, "%x", A);
        CNT = $fscanf(FILE, "%x", B);
        CNT = $fscanf(FILE, "%x", C);
        
        @(posedge OUT_VIF.VALID) // with or without semicolon
        for(i = 0; i < 8; i = i + 1)
          @(negedge OUT_VIF.CLK) Z[8*i +: 8] = OUT_VIF.DATA;

        SHOW_PATTERN;

        if(Z !== C && !(Z[62:52] == 11'd2047 && Z[51:0] != 0 && C[62:52] == 11'd2047 && C[51:0] != 0)) begin // NaN
          $display("\n");
          $display("**********************************************************************");
          $display("****************************** Wrong ! *******************************");
          $display("**********************************************************************");
          $display("\n");
          #(`CYCLE * 2);
          $finish;
        end
        
      end
    endtask

    
    task my_monitor::SHOW_PATTERN;
      begin
        $display("\n");
        $display("%0d.", j+1);
        $display("**********************************************************************");
        $display("A = %x_%x_%x", A[63], A[62:52], A[51:0]);
        $display("B = %x_%x_%x", B[63], B[62:52], B[51:0]);
        $display("------------------- Your Result --------------------------------------");
        $display("Z = %b_%b_%b", Z[63], Z[62:52], Z[51:0]);
        $display("------------------- Correct Result -----------------------------------");
        $display("C = %b_%b_%b", C[63], C[62:52], C[51:0]);
        $display("**********************************************************************");
      end
    endtask 
