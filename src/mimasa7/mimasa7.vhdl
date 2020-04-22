library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;

entity container is
  port(
    CLK1 : in std_logic;
    LED : out std_logic_vector(7 downto 0) := (others => '0')
	);
end entity;


architecture RTL of container is

  signal clk : std_logic; 
  signal clk7m : std_logic;
  signal clk28m : std_logic;
  signal clk140 : std_logic;
  signal clk281 : std_logic;
  signal clk_fb : std_logic;
  signal pll_locked : std_logic;
  signal diskled_out : std_logic;	-- Use for SD access
  signal oddled_out : std_logic; -- Use for floppy access

  signal counter : unsigned(31 downto 0) := to_unsigned(0,32);
  
begin
 clk_main: mmcme2_base
  generic map
  (
    clkin1_period    => 10.0,           --   100      MHz
    clkfbout_mult_f  => 16.875,         --  1687.5    MHz *16.875 common multiply
    divclk_divide    => 2,              --   843.75   MHz /2 common divide
    clkout0_divide_f => 7.5,            --  112.5     MHz /7.5 divide
    clkout1_divide   => 120,            --    7.03125 MHz /120 divide
    clkout2_divide   => 30,             --   28.125   MHz /30 divide
    clkout3_divide   => 6,              --  140.625   MHz /6 divide
    clkout4_divide   => 3,              --  281.25    MHz /3 divide
    bandwidth        => "OPTIMIZED"
  )
  port map
  (
    pwrdwn   => '0',
    rst      => '0',
    clkin1   => CLK1,
    clkfbin  => clk_fb,
    clkfbout => clk_fb,
    clkout0  => clk,                  --  112.5     MHz
    clkout1  => clk7m,                --    7.03125 MHz
    clkout2  => clk28m,               --   28.125   MHz
    clkout3  => clk140,              --  140.625   MHz
    clkout4  => clk281,                 --  281.25    MHz
    locked   => pll_locked
  );


  process(clk7m) is
  begin
	  if rising_edge(clk7m) then
		  counter <= counter + 1;
		  led <= std_logic_vector(counter(23 downto 16));
	  end if;
  end process;
        
end rtl;
