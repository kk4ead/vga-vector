library IEEE;
use IEEE.std_logic_1164.all;

entity de2_sram_controller is
  
  port (
    signal avs_s1_clk,
	   avs_s1_chipselect,
           avs_s1_write,
           avs_s1_read : in std_logic;
    signal avs_s1_address : in std_logic_vector(17 downto 0);
    signal avs_s1_readdata : out std_logic_vector(15 downto 0);
    signal avs_s1_writedata : in std_logic_vector(15 downto 0);
    signal avs_s1_byteenable : in std_logic_vector(1 downto 0);

    signal SRAM_DQ : inout std_logic_vector(15 downto 0);
    signal SRAM_ADDR : out std_logic_vector(17 downto 0);
    signal SRAM_UB_N,
           SRAM_LB_N,
           SRAM_WE_N,
           SRAM_CE_N,
           SRAM_OE_N : out std_logic
  );
    
end de2_sram_controller;

architecture datapath of de2_sram_controller is

begin

  SRAM_DQ <= avs_s1_writedata when avs_s1_write = '1' else
             (others => 'Z');
  avs_s1_readdata <= SRAM_DQ;
  SRAM_ADDR <= avs_s1_address;
  SRAM_UB_N <= not avs_s1_byteenable(1);
  SRAM_LB_N <= not avs_s1_byteenable(0);
  SRAM_WE_N <= not avs_s1_write;
  SRAM_CE_N <= not avs_s1_chipselect;
  SRAM_OE_N <= not avs_s1_read;
  
end datapath;
