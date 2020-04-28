----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Description: dvid_test 
--  Top level design for testing my DVI-D interface
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity dvid_test is
    Port ( clk_in  : in  STD_LOGIC;
           data_p    : out  STD_LOGIC_VECTOR(2 downto 0);
           data_n    : out  STD_LOGIC_VECTOR(2 downto 0);
           clk_p          : out    std_logic;
           clk_n          : out    std_logic;
           reset : in std_logic
       );
         
end dvid_test;

architecture Behavioral of dvid_test is
   component clocking
   port (
      -- Clock in ports
      clk_in           : in     std_logic;
      -- Clock out ports
      CLK_DVI          : out    std_logic;
      CLK_DVIn         : out    std_logic;
      CLK_VGA          : out    std_logic;
      reset : in std_logic
   );
   end component;

   COMPONENT vga
   generic (
      hRez        : natural;
      hStartSync  : natural;
      hEndSync    : natural;
      hMaxCount   : natural;
      hsyncActive : std_logic;

      vRez        : natural;
      vStartSync  : natural;
      vEndSync    : natural;
      vMaxCount   : natural;
      vsyncActive : std_logic
    );

   PORT(
      pixelClock : IN std_logic;          
      Red : OUT std_logic_vector(7 downto 0);
      Green : OUT std_logic_vector(7 downto 0);
      Blue : OUT std_logic_vector(7 downto 0);
      hSync : OUT std_logic;
      vSync : OUT std_logic;
      blank : OUT std_logic
      );
   END COMPONENT;

   signal clk_dvi  : std_logic := '0';
   signal clk_dvin : std_logic := '0';
   signal clk_vga  : std_logic := '0';

   signal red     : std_logic_vector(7 downto 0) := (others => '0');
   signal green   : std_logic_vector(7 downto 0) := (others => '0');
   signal blue    : std_logic_vector(7 downto 0) := (others => '0');
   signal hsync   : std_logic := '0';
   signal vsync   : std_logic := '0';
   signal blank   : std_logic := '0';
   signal red_s   : std_logic_vector(0 downto 0);
   signal green_s : std_logic_vector(0 downto 0);
   signal blue_s  : std_logic_vector(0 downto 0);
   signal clock_s : std_logic_vector(0 downto 0);

   signal audio_l : std_logic_vector(15 downto 0) := x"0000";
   signal audio_r : std_logic_vector(15 downto 0) := x"0000";

   signal counter : integer := 0;

   signal audio_counter : integer := 0;
   signal sample_repeat : integer := 0;
   signal audio_address : integer := 0;
   signal audio_data : std_logic_vector(7 downto 0) := x"00";

   signal sample_ready : boolean := false;

   type sine_t is array (0 to 8) of unsigned(7 downto 0);
   signal sine_table : sine_t := (
     0 => to_unsigned(0,8),
     1 => to_unsigned(22,8),
     2 => to_unsigned(43,8),
     3 => to_unsigned(64,8),
     4 => to_unsigned(82,8),
     5 => to_unsigned(98,8),
     6 => to_unsigned(110,8),
     7 => to_unsigned(120,8),
     8 => to_unsigned(126,8)
     );
   
begin
   
   
clocking_inst : clocking port map (
      clk_in   => clk_in,
      -- Clock out ports
      CLK_DVI  => clk_dvi,  -- for 640x480@60Hz : 125MHZ
      CLK_DVIn => clk_dvin, -- for 640x480@60Hz : 125MHZ, 180 degree phase shift
      CLK_VGA  => clk_vga,   -- for 640x480@60Hz : 25MHZ 
      reset => reset
    );

Inst_dvid: entity work.dvid PORT MAP(
      clk       => clk_dvi,
      clk_n     => clk_dvin, 
      clk_pixel => clk_vga,
      clk_pixel_en => true,
      
      red_p     => red,
      green_p   => green,
      blue_p    => blue,
      blank     => blank,
      hsync     => hsync,
      vsync     => vsync,

      EnhancedMode => true,
      IsProgressive => true,
      IsPAL => true,
      Is30kHz => true,
      Limited_Range => true,
      Widescreen => false,

      HDMI_audio_L => audio_L,
      HDMI_audio_R => audio_R,
      HDMI_LeftEnable => true,
      HDMI_RightEnable => sample_ready,
      
      -- outputs to TMDS drivers
      red_s     => red_s,
      green_s   => green_s,
      blue_s    => blue_s,
      clock_s   => clock_s
   );
   
OBUFDS_blue  : OBUFDS port map ( O  => DATA_P(0), OB => DATA_N(0), I  => blue_s(0)  );
OBUFDS_red   : OBUFDS port map ( O  => DATA_P(1), OB => DATA_N(1), I  => green_s(0) );
OBUFDS_green : OBUFDS port map ( O  => DATA_P(2), OB => DATA_N(2), I  => red_s(0)   );
OBUFDS_clock : OBUFDS port map ( O  => CLK_P, OB => CLK_N, I  => clock_s(0) );
    -- generic map ( IOSTANDARD => "DEFAULT")    
   
Inst_vga: vga GENERIC MAP (
      hRez       => 720, hStartSync => 732, hEndSync   => 796, hMaxCount  => 861, hsyncActive => '0',
      vRez       => 576, vStartSync => 587, vEndSync   => 592, vMaxCount  => 623, vsyncActive => '1'
   ) PORT MAP(
      pixelClock => clk_vga,
      Red        => red,
      Green      => green,
      Blue       => blue,
      hSync      => hSync,
      vSync      => vSync,
      blank      => blank
      );

process (clk_in) is
begin

  if rising_edge(clk_vga) then

    if audio_address < 9 then
      audio_data <= std_logic_vector(sine_table(audio_address) + 128);
    elsif audio_address < 18 then
      audio_data <= std_logic_vector(sine_table(8 - (audio_address - 9)) + 128);
    elsif audio_address < 27 then
      audio_data <= std_logic_vector(128 - sine_table(audio_address - 18));
    elsif audio_address < 36 then
      audio_data <= std_logic_vector(128 - sine_table(8 - (audio_address - 27)));
    else
      audio_data <= x"80";
    end if;
    
    -- Strobe sample_ready at 48KHz
    if audio_counter /= 2083 then
      audio_counter <= audio_counter + 1;
      sample_ready <= false;
    else
      audio_l(15 downto 8) <= audio_data;
      audio_r(15 downto 8) <= audio_data;
      -- 48KHz sample rate, so 200Hz requires dividing by ~240
      if sample_repeat /= 240 then
        sample_repeat <= sample_repeat + 1;
      else
        sample_repeat <= 0;
        if audio_address /= 35 then
          audio_address <= audio_address + 1;
        else
          audio_address <= 0;
        end if;
      end if;
      sample_ready <= true;
    end if;
    
  end if;
end process;


end Behavioral;
