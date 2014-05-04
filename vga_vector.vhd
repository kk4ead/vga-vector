library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity vga_vector is
  port (
    clk, rst     : in std_logic;

    x_end, y_end : in std_logic_vector(9 downto 0);
    x_spd, y_spd : in std_logic_vector(15 downto 0);
    beam         : in std_logic;
    go           : in std_logic;
    done         : out std_logic;

    vga_clk,
    vga_hs,
    vga_vs,
    vga_sync,
    vga_blank : out std_logic;
    vga_r,
    vga_g,
    vga_b     : out std_logic_vector(9 downto 0)
  );
end vga_vector;

architecture fsm of vga_vector is
  type state is (reset, idle, read, draw);
  signal pr_state, nx_state: state;
  signal rx_x, pr_x, nx_x,
         rx_y, pr_y, nx_y,
         delta_x, delta_y  : std_logic_vector(15 downto 0);
  signal rx_z, pr_z, nx_z,
         pr_done, nx_done  : std_logic;
         
  signal plusx, minusx, plusy, minusy: std_logic_vector(15 downto 0);
  signal ofx, ufx, ofy, ufy, addx, subx, addy, suby, donex, doney : std_logic;
begin

  -- Port maps
  vga_r <= pr_x(15 downto 6);
  vga_g <= pr_y(15 downto 6);
  vga_b <= (others => '0');
  vga_hs <= not pr_z;
  vga_vs <= not pr_z;
  vga_sync <= '0';
  vga_blank <= '1';
  vga_clk <= clk;
  -- End port maps

  -- Intermediate calculations
  plusx  <= pr_x + delta_x;
  minusx <= pr_x - delta_x;
  plusy  <= pr_y + delta_y;
  minusy <= pr_y - delta_y;

  ofx <= '1' when plusx  < pr_x else '0';
  ufx <= '1' when minusx > pr_x else '0';
  ofy <= '1' when plusy  < pr_y else '0';
  ufy <= '1' when minusy > pr_y else '0';

  addx <= '1' when (pr_x < rx_x) else '0';
  subx <= '1' when (pr_x > rx_x) else '0';
  addy <= '1' when (pr_y < rx_y) else '0';
  suby <= '1' when (pr_y > rx_y) else '0';

  donex <= '1' when (addx='0' and subx='0') or
                    (addx='1' and ofx='1') or
                    (subx='1' and ufx='1') or
                    (addx='1' and (plusx  >= rx_x)) or
                    (subx='1' and (minusx <= rx_x))
                    else '0';

  doney <= '1' when (addy='0' and suby='0') or
                    (addy='1' and ofy='1') or
                    (suby='1' and ufy='1') or
                    (addy='1' and (plusy  >= rx_y)) or
                    (suby='1' and (minusy <= rx_y))
                    else '0';
  -- End intermediate calculations

  process (clk)
  begin
    if (clk'event and clk='1') then
      pr_state <= nx_state;
      pr_x <= nx_x;
      pr_y <= nx_y;
      pr_z <= nx_z;
      
      if (pr_state=read) then
        rx_x(15 downto 6) <= x_end;
        rx_y(15 downto 6) <= y_end;
        rx_x(5 downto 0) <= "000000";
        rx_y(5 downto 0) <= "000000";
        rx_z <= beam;
        delta_x <= x_spd;
        delta_y <= y_spd;
      end if;
    end if;
  end process;

  nx_state <=
    reset when rst='1' else
    idle when pr_state=reset and rst='0' else
    read when pr_state=idle and go='1' else
    idle when pr_state=idle else
    draw when pr_state=read or (pr_state=draw and (donex='0' or doney='0')) else
    idle when pr_state=draw else
    reset;

  nx_x <=
    (others => '0') when pr_state=reset else
    rx_x   when pr_state=draw and donex='1' else
    plusx  when pr_state=draw and addx ='1' else
    minusx when pr_state=draw and subx ='1' else
    pr_x;

  nx_y <=
    (others => '0') when pr_state=reset else
    rx_y   when pr_state=draw and doney='1' else
    plusy  when pr_state=draw and addy ='1' else
    minusy when pr_state=draw and suby ='1' else
    pr_y;
    
  nx_z <=
    rx_z when pr_state=read or pr_state=draw else
    '0';
    
  done <=
    '1' when pr_state=idle or pr_state=read else
    '0';

end fsm;