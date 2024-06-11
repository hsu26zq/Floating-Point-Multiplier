`include "my_driver.sv"
`include "my_monitor.sv"

import uvm_pkg::*;

class my_env extends uvm_env;
  
  my_driver DRIVER;
  my_monitor MONITOR;
  
  `uvm_component_utils(my_env)
  function new(string name = "my_env", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    DRIVER = my_driver::type_id::create("DRIVER", this);
    MONITOR = my_monitor::type_id::create("MONITOR", this);
  endfunction
endclass
