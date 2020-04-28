library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;

entity container is
  port(
    CLK1 : in std_logic;
--    P13 : inout std_logic_vector(39 downto 0) := (others => 'Z');
--    P12z : out std_logic_vector(1 downto 0) := (others => 'Z');
    LED : out std_logic_vector(7 downto 0) := (others => '0');

    reset : in std_logic;
    
    hdmi_tx_p : out STD_LOGIC_VECTOR(2 downto 0);
    hdmi_tx_n : out STD_LOGIC_VECTOR(2 downto 0);
    hdmi_tx_clk_p : out STD_LOGIC;
    hdmi_tx_clk_n : out STD_LOGIC
    
    );
end entity;


architecture RTL of container is

  signal clk : std_logic; 
  signal clk7m : std_logic;
  signal clk28m : std_logic;
  signal clk140 : std_logic;
  signal clk140_n : std_logic;
  signal clk281 : std_logic;
  signal clk_fb : std_logic;
  signal pll_locked : std_logic;
  signal diskled_out : std_logic;	-- Use for SD access
  signal oddled_out : std_logic; -- Use for floppy access

  signal counter : unsigned(31 downto 0) := to_unsigned(0,32);

  signal uart_trigger : std_logic := '0';
  signal uart_tx_byte : unsigned(7 downto 0) := x"00";
  signal uart_tx_ready : std_logic;

  signal red_s : std_logic_vector(0 downto 0) := (others => '0');
  signal green_s : std_logic_vector(0 downto 0) := (others => '0');
  signal blue_s : std_logic_vector(0 downto 0) := (others => '0');
  signal clock_s : std_logic_vector(0 downto 0) := (others => '0');

  signal vga_red : unsigned(7 downto 0) := x"00";
  signal vga_green : unsigned(7 downto 0) := x"00";
  signal vga_blue : unsigned(7 downto 0) := x"00";
  signal vga_hsync : std_logic := '0';
  signal vga_vsync : std_logic := '0';
  signal in_frame : std_logic := '0';
  
begin

  
  dvi0: entity work.dvid_test
    port map ( clk_in  => CLK1,
               data_p => hdmi_tx_p,
               data_n => hdmi_tx_n,
               clk_p => hdmi_tx_clk_p,
               clk_n => hdmi_tx_clk_n,
               reset => reset
       );
         
  
        
end rtl;
