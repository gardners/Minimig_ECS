library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;

entity container is
  port(
    CLK1 : in std_logic;
    P13 : inout std_logic_vector(39 downto 0) := (others => 'Z');
    LED : out std_logic_vector(7 downto 0) := (others => '0');

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
    clkout5_divide   => 6,              --  140.625   MHz /6 divide
    clkout5_phase    => 180.0,            --  INVERTED
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
    clkout5  => clk140_n,
    locked   => pll_locked
  );

  tx0: entity work.UART_TX_CTRL
  port map ( SEND => uart_trigger,
             BIT_TMR_MAX => to_unsigned(7031250/115200,16),
             DATA => uart_tx_byte,
             CLK => clk7m,
             READY => uart_tx_ready,
             UART_TX => P13(0)
             );

 dvid0: entity work.dvid
   port map (
     clk_pixel_en => true,
     clk_pixel => clk28m,
     clk => clk140,
     clk_n => not clk140,
     red_p => std_logic_vector(vga_red),
     green_p => std_logic_vector(vga_green),
     blue_p => std_logic_vector(vga_blue),
     blank => not in_frame,
     hsync => vga_hsync,
     vsync => vga_vsync,

     EnhancedMode => false,
     IsProgressive => true,
     IsPAL => true,
     Is30KHz => true,
     Limited_Range => false,
     Widescreen => false,

     HDMI_audio_L => (others => '0'),
     HDMI_audio_R => (others => '0'),
     HDMI_LeftEnable => false,
     HDMI_RightEnable => false,

     red_s => red_s,
     green_s => green_s,
     blue_s => blue_s,
     clock_s => clock_s     
   
     );

 -- Produce LVDS differential signals from single-ended signals
 OBUFDS_blue  : OBUFDS port map ( O  => hdmi_tx_p(0), OB => hdmi_tx_n(0), I  => std_ulogic(blue_s(0)) );
 OBUFDS_green   : OBUFDS port map ( O  => hdmi_tx_p(1), OB => hdmi_tx_n(1), I  => std_ulogic(green_s(0)) );
 OBUFDS_red : OBUFDS port map ( O  => hdmi_tx_p(2), OB => hdmi_tx_n(2), I  => std_ulogic(red_s(0)) );
 OBUFDS_clock : OBUFDS port map ( O  => hdmi_tx_clk_p, OB => hdmi_tx_clk_n, I  => std_ulogic(clock_s(0)) );
 
  process(clk7m) is
  begin
    
	  if rising_edge(clk7m) then
		  counter <= counter + 1;
		  led <= std_logic_vector(counter(23 downto 16));
                  if counter(18 downto 0) = to_unsigned(0,19) then
                    uart_trigger <= '1';
                    uart_tx_byte(3 downto 0) <= counter(22 downto 19);
                    uart_tx_byte(7 downto 4) <= x"4";
                    if counter(24 downto 19) = "000000" then
                      uart_tx_byte <= x"0d";
                    elsif counter(24 downto 19) = "000001" then
                      uart_tx_byte <= x"0a";
                    end if;
                  else
                    uart_trigger <= '0';
                  end if;
	  end if;
  end process;
        
end rtl;
