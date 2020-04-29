library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

library unisim;
use unisim.vcomponents.all;

entity clocking is
   port (
      -- Clock in ports
      clk_in           : in     std_logic;
      -- Clock out ports
      CLK_DVI          : out    std_logic;
      CLK_DVIn         : out    std_logic;
      CLK_VGA          : out    std_logic;
      reset : in std_logic
   );
end entity;


architecture RTL of clocking is

  signal clk_fb : std_logic := '0';
  
begin

  mmcm_adv_inst : MMCM_ADV
  generic map
   (BANDWIDTH            => "OPTIMIZED",
    CLKOUT4_CASCADE      => FALSE,
    CLOCK_HOLD           => FALSE,
    COMPENSATION         => "ZHOLD",
    STARTUP_WAIT         => FALSE,

    -- Create 812.5MHz clock from 8.125x100MHz/1
    DIVCLK_DIVIDE        => 1,
    CLKFBOUT_MULT_F      => 8.125, -- get 25/125 instead of 27/135mhz
    CLKFBOUT_PHASE       => 0.000,
    CLKFBOUT_USE_FINE_PS => FALSE,

    -- CLKOUT0 = CLK_OUT1 = clock325 = 812.5MHz/2.5
    CLKOUT0_DIVIDE_F     => 2.50,
    CLKOUT0_PHASE        => 0.000,
    CLKOUT0_DUTY_CYCLE   => 0.500,
    CLKOUT0_USE_FINE_PS  => FALSE,

    -- CLKOUT1 = CLK_OUT2 = clock135 ~= 812.5MHz/6
    CLKOUT1_DIVIDE       => 6,
    CLKOUT1_PHASE        => 0.000,
    CLKOUT1_DUTY_CYCLE   => 0.500,
    CLKOUT1_USE_FINE_PS  => FALSE,

    -- CLKOUT2 = CLK_OUT3 = clock27 ~= 812.5MHz/30
    CLKOUT2_DIVIDE       => 30,
    CLKOUT2_PHASE        => 0.000,
    CLKOUT2_DUTY_CYCLE   => 0.500,
    CLKOUT2_USE_FINE_PS  => FALSE,
    
    -- CLKOUT3 = CLK_OUT4 = clock41 ~= 812.5MHz/20
    CLKOUT3_DIVIDE       => 20,
    CLKOUT3_PHASE        => 0.000,
    CLKOUT3_DUTY_CYCLE   => 0.500,
    CLKOUT3_USE_FINE_PS  => FALSE,

    -- CLKOUT4 = CLK_OUT5 = clock81 ~= 812.5MHz/10
    CLKOUT4_DIVIDE       => 10,
    CLKOUT4_PHASE        => 0.000,
    CLKOUT4_DUTY_CYCLE   => 0.500,
    CLKOUT4_USE_FINE_PS  => FALSE,

    -- CLKOUT5 = CLK_OUT6 = clock163 - 812.5MHz/5
    CLKOUT5_DIVIDE       => 5,
    CLKOUT5_PHASE        => 0.0,
    CLKOUT5_DUTY_CYCLE   => 0.500,
    CLKOUT5_USE_FINE_PS  => FALSE,

    -- CLKOUT6 = CLK_OUT7 = UNUSED
    CLKOUT6_DIVIDE       => 5,
    CLKOUT6_PHASE        => 0.000,
    CLKOUT6_DUTY_CYCLE   => 0.500,
    CLKOUT6_USE_FINE_PS  => FALSE,
    CLKIN1_PERIOD        => 10.000,
    REF_JITTER1          => 0.010)
  port map
    -- Output clocks
   (CLKFBOUT            => clk_fb,
--    CLKOUT0             => CLK325,
    CLKOUT1             => CLK_DVI,  -- ~135MHz
    CLKOUT1B            => CLK_DVIn,
    CLKOUT2             => CLK_VGA,
--    CLKOUT3             => CLK41,
--    CLKOUT4             => CLK81,
--    CLKOUT5             => CLK163,
    -- Input clock control
    CLKFBIN             => clk_fb,
    CLKIN1              => clk_in,
    CLKIN2              => '0',
    -- Tied to always select the primary input clock
    CLKINSEL            => '1',
    -- Ports for dynamic reconfiguration
    DADDR               => (others => '0'),
    DCLK                => '0',
    DEN                 => '0',
    DI                  => (others => '0'),
    DWE                 => '0',
    -- Ports for dynamic phase shift
    PSCLK               => '0',
    PSEN                => '0',
    PSINCDEC            => '0',
    -- Other control and status signals
    PWRDWN              => '0',
    RST                 => '0');
  
        
end rtl;
