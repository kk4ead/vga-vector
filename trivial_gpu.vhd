library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity trivial_gpu is
  port (
    clk, rst: in std_logic;

    avm_m1_read        : out std_logic;
    avm_m1_address     : out std_logic_vector(9 downto 0);
    avm_m1_readdata    : in  std_logic_vector(15 downto 0);
    avm_m1_waitrequest : in  std_logic;

    vga_clk,
    vga_hs,
    vga_vs,
    vga_sync,
    vga_blank: out std_logic;
    vga_r,
    vga_g,
    vga_b: out std_logic_vector(9 downto 0)
  );
end trivial_gpu;

--  15 ... ... ... 0| p = opcode: 0 for NOP, 1 for vector, 2 for jump
--  ----------------+ x = X coordinate of next point (address if jump)
--  ----ppxxxxxxxxxx| y = Y coordinate of next point
--  -----Byyyyyyyyyy| B = beam (1 = on, 0 = off)
--  XXXXXXXXXXXXXXXX| X = X-axis scan speed (10 bits integer, 6 fraction)
--  YYYYYYYYYYYYYYYY| Y = Y-axis scan speed (10 bits integer, 6 fraction)

architecture fsm of trivial_gpu is

  component vga_vector is
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
  end component;

  signal x_end, y_end, rx_x,  rx_y    : std_logic_vector(9 downto 0);
  signal x_spd, y_spd, rx_vx, rx_vy   : std_logic_vector(15 downto 0);
  signal beam, rx_beam, go, done      : std_logic;

  type state is (idle, read1, read2, read3, read4, write, jump);
  signal pr_state, nx_state: state;
  signal ready, do_read, do_jump, do_inc: std_logic;
  signal pc: std_logic_vector(9 downto 0);

begin

  generator: vga_vector port map (
    clk       => clk,
    rst       => rst,
    vga_clk   => vga_clk,
    vga_hs    => vga_hs,
    vga_vs    => vga_vs,
    vga_sync  => vga_sync,
    vga_blank => vga_blank,
    vga_r     => vga_r,
    vga_g     => vga_g,
    vga_b     => vga_b,
    x_end     => x_end,
    y_end     => y_end,
    x_spd     => x_spd,
    y_spd     => y_spd,
    beam      => beam,
    go        => go,
    done      => done
  );

  flipflop: process(clk)
  begin
    if (clk'event and clk = '1') then

      if (ready = '1') then
        case pr_state is
          when read1  => rx_x <= avm_m1_readdata(9 downto 0);
          when read2  => rx_y <= avm_m1_readdata(9 downto 0);
                         rx_beam <= avm_m1_readdata(10);
          when read3  => rx_vx <= avm_m1_readdata;
          when read4  => rx_vy <= avm_m1_readdata;
          when others => null;
        end case;

        if (do_inc = '1') then
          pc <= pc + 2;
        end if;
      end if;

      case pr_state is
        when jump   => pc    <= rx_x;
                       go    <= '0';
        when write  => x_end <= rx_x;
                       y_end <= rx_y;
                       x_spd <= rx_vx;
                       y_spd <= rx_vy;
                       beam  <= rx_beam;
                       go    <= '1';
        when others => go    <= '0';
      end case;

      pr_state <= nx_state;

    end if;
  end process;

  avm_m1_address <= pc;
  avm_m1_read    <= '1' when (pr_state = read1 or pr_state = read2
                        or pr_state = read3 or pr_state = read4) else '0';

  ready   <= '1' when avm_m1_waitrequest = '0'
                 else '0';
  do_read <= '1' when ready = '1' and avm_m1_readdata(11 downto 10) = "01"
                 else '0';
  do_jump <= '1' when ready = '1' and avm_m1_readdata(11 downto 10) = "10"
                 else '0';
  do_inc  <= '1' when ready = '1' and (pr_state = read1 or pr_state = read2
                 or pr_state = read3 or pr_state = read4)
                 else '0';

  nx_state <= read1 when pr_state = jump or (pr_state = write and done = '0')
         else read2 when pr_state = read1 and do_read = '1'
         else read3 when pr_state = read2 and ready   = '1'
         else read4 when (pr_state = read3 and ready   = '1')
                      or (pr_state = read4 and ready = '0')
         else write when (pr_state = idle or pr_state = read4) and done = '1'
         else idle  when (pr_state = idle or pr_state = read4)
         else jump  when pr_state = read1 and do_jump = '1'
         else pr_state;

end fsm;