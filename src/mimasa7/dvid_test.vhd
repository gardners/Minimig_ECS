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
         led : out std_logic_vector(7 downto 0);
         dip_sw : in std_logic_vector(7 downto 0);
         p13 : inout std_logic_vector(39 downto 0) := (others => 'Z');
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

   constant clock_frequency : integer := 27000000;
   constant target_sample_rate : integer := 48000;
   constant sine_table_length : integer := 36;
   signal sample_repeat_interval : unsigned(23 downto 0) := to_unsigned((target_sample_rate/sine_table_length)/200,24);
   signal audio_counter_interval : unsigned(23 downto 0) := to_unsigned(clock_frequency/target_sample_rate,24);
   signal sample_mask : std_logic_vector(7 downto 0) := x"80";
   
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

   type hex_t is array ( 0 to 15) of unsigned(7 downto 0);
   signal hex_table : hex_t := (
     0 => x"30",  1 => x"31",  2 => x"32",   3 => x"33",
     4 => x"34",  5 => x"35",  6 => x"36",   7 => x"37",
     8 => x"38",  9 => x"39", 10 => x"41",  11 => x"42",
     12 => x"43", 13 => x"44", 14 => x"45",  15 => x"46"
     );
   
   signal uart_tx_ready : std_logic := '0';
   signal uart_tx_byte : unsigned(7 downto 0) := x"00";
   signal uart_trigger : std_logic := '0';
   signal report_phase : integer := 0;

   type flag_array is array (0 to 7) of boolean;
   signal retflags : flag_array := (others => false);   
   signal flags : flag_array := (others => false);
   signal hi : unsigned(7 downto 0) := x"00";
   signal lo : unsigned(7 downto 0) := x"00";

   signal infoframes : unsigned(7 downto 0);
   
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
      IsPAL => false,
      Is30kHz => true,
      Limited_Range => false,
      Widescreen => false,

      EnhancedModeReturn => retflags(1),
      IsProgressiveReturn => retflags(2),
      IsPALReturn => retflags(3),
      Is30kHzReturn => retflags(4),
      Limited_RangeReturn => retflags(5),
      WidescreenReturn => retflags(6),
      InfoFrames => infoframes,
      
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
-- 640x480p60
--      hRez       => 640, hStartSync => 656, hEndSync   => 752, hMaxCount  => 800, hsyncActive => '0',
--      vRez       => 480, vStartSync => 490, vEndSync   => 492, vMaxCount  => 525, vsyncActive => '1'
-- 576p50
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

  tx0: entity work.UART_TX_CTRL
  port map ( SEND => uart_trigger,
             BIT_TMR_MAX => to_unsigned(100000000/2000000,16),
             DATA => uart_tx_byte,
             CLK => clk_in,
             READY => uart_tx_ready,
             UART_TX => P13(0)
             );


process (clk_vga) is
begin

  if rising_edge(clk_vga) then

    if audio_address < 9 then
      audio_data <= std_logic_vector(sine_table(audio_address) + 128);
    elsif audio_address < 18 then
      audio_data <= std_logic_vector(sine_table(8 - (audio_address - 9)) + 128);
    elsif audio_address < 27 then
      audio_data <= std_logic_vector(127 - sine_table(audio_address - 18));
    elsif audio_address < 36 then
      audio_data <= std_logic_vector(127 - sine_table(8 - (audio_address - 27)));
    else
      audio_data <= x"80";
    end if;

    sample_mask <= dip_sw;

    for i in 0 to 7 loop
      if dip_sw(i)='0' then
        lo(i) <= '1';
      else
        lo(i) <= '0';
      end  if;
      if dip_sw(i)='1' then
        flags(i) <= true;
        hi(i) <= '1';
      else
        flags(i) <= false;
        hi(i) <= '0';
      end if;
    end loop;    
    
    uart_trigger <= '0';

    -- Strobe sample_ready at 48KHz
    if audio_counter /= to_integer(audio_counter_interval) then
      audio_counter <= audio_counter + 1;
      sample_ready <= false;
    else
      audio_counter <= 0;
      sample_ready <= true;

      audio_l <= (others => '0');
      audio_r <= (others => '0');
      led <= (others => '0');
      if dip_sw(0)='0' then
        audio_l(7) <= audio_data(7);
        audio_r(7) <= audio_data(7);
        led(7) <= audio_data(7);
      else
        audio_l(12 downto 6) <= audio_data(7 downto 1) and sample_mask(7 downto 1);
        audio_r(12 downto 6) <= audio_data(7 downto 1) and sample_mask(7 downto 1);
        led(7 downto 1) <= audio_data(7 downto 1) and sample_mask(7 downto 1);
        null;
      end if;
        
      if sample_repeat /= to_integer(sample_repeat_interval) then
        sample_repeat <= sample_repeat + 1;
      else
        sample_repeat <= 0;
        if audio_address /= 35 then
          audio_address <= audio_address + 1;          
        else
          audio_address <= 0;
        end if;
      end if;

      -- Also update display
      if report_phase /= 99 then
        report_phase <= report_phase + 1;
      else
        report_phase <= 0;
      end if;
      uart_trigger <= '1';
      case report_phase is
        when  0 => uart_tx_byte <= x"0d";

        -- Sample mask $xx
        when  1 => uart_tx_byte <= x"53";
        when  2 => uart_tx_byte <= x"61";
        when  3 => uart_tx_byte <= x"6d";
        when  4 => uart_tx_byte <= x"70";
        when  5 => uart_tx_byte <= x"6c";
        when  6 => uart_tx_byte <= x"65";
        when  7 => uart_tx_byte <= x"20";
        when  8 => uart_tx_byte <= x"6d";
        when  9 => uart_tx_byte <= x"61";
        when 10 => uart_tx_byte <= x"73";
        when 11 => uart_tx_byte <= x"6b";
        when 12 => uart_tx_byte <= x"20";
        when 13 => uart_tx_byte <= x"24";
        when 14 => uart_tx_byte <= hex_table(to_integer(unsigned(sample_mask(7 downto 4))));
        when 15 => uart_tx_byte <= hex_table(to_integer(unsigned(sample_mask(3 downto 0))));
                   
        -- 
        when 16 => uart_tx_byte <= x"2e";
        when 17 => uart_tx_byte <= x"20";
        when 18 => uart_tx_byte <= x"44";
        when 19 => uart_tx_byte <= x"49";
        when 20 => uart_tx_byte <= x"50";
        when 21 => uart_tx_byte <= x"75";
        when 22 => uart_tx_byte <= x"20";
        when 23 => uart_tx_byte <= x"24";
        when 24 => uart_tx_byte <= hex_table(to_integer(unsigned(dip_sw(7 downto 4))));
        when 25 => uart_tx_byte <= hex_table(to_integer(unsigned(dip_sw(3 downto 0))));

        when 26 => uart_tx_byte <= x"2e";
        when 27 => uart_tx_byte <= x"20";
        when 28 => uart_tx_byte <= x"4c";
        when 29 => uart_tx_byte <= x"4f";
        when 30 => uart_tx_byte <= x"3d";
        when 31 => uart_tx_byte <= x"48";
        when 32 => uart_tx_byte <= x"49";
        when 33 => uart_tx_byte <= x"20";
        when 34 => uart_tx_byte <= hex_table(to_integer(unsigned(lo(7 downto 4))));
        when 35 => uart_tx_byte <= hex_table(to_integer(unsigned(lo(3 downto 0))));
        when 36 => uart_tx_byte <= hex_table(to_integer(unsigned(hi(7 downto 4))));
        when 37 => uart_tx_byte <= hex_table(to_integer(unsigned(hi(3 downto 0))));
        when 38 => uart_tx_byte <= x"20";
        when 39 => if flags(0) then uart_tx_byte <= x"30"; else uart_tx_byte <= x"2e"; end if;
        when 40 => if flags(1) then uart_tx_byte <= x"31"; else uart_tx_byte <= x"2e"; end if;
        when 41 => if flags(2) then uart_tx_byte <= x"32"; else uart_tx_byte <= x"2e"; end if;
        when 42 => if flags(3) then uart_tx_byte <= x"33"; else uart_tx_byte <= x"2e"; end if;
        when 43 => if flags(4) then uart_tx_byte <= x"34"; else uart_tx_byte <= x"2e"; end if;
        when 44 => if flags(5) then uart_tx_byte <= x"35"; else uart_tx_byte <= x"2e"; end if;
        when 45 => if flags(6) then uart_tx_byte <= x"36"; else uart_tx_byte <= x"2e"; end if;
        when 46 => if flags(7) then uart_tx_byte <= x"37"; else uart_tx_byte <= x"2e"; end if;
        when 47 => uart_tx_byte <= x"20";
        when 48 => if retflags(1) then uart_tx_byte <= x"31"; else uart_tx_byte <= x"2e"; end if;
        when 49 => if retflags(2) then uart_tx_byte <= x"32"; else uart_tx_byte <= x"2e"; end if;
        when 50 => if retflags(3) then uart_tx_byte <= x"33"; else uart_tx_byte <= x"2e"; end if;
        when 51 => if retflags(4) then uart_tx_byte <= x"34"; else uart_tx_byte <= x"2e"; end if;
        when 52 => if retflags(5) then uart_tx_byte <= x"35"; else uart_tx_byte <= x"2e"; end if;
        when 53 => if retflags(6) then uart_tx_byte <= x"36"; else uart_tx_byte <= x"2e"; end if;
        when 54 => uart_tx_byte <= x"20";
        when 55 => uart_tx_byte <= hex_table(to_integer(infoframes(7 downto 4)));
        when 56 => uart_tx_byte <= hex_table(to_integer(infoframes(3 downto 0)));
                   
        when others => uart_tx_byte <= x"00";
      end case;
      
      
      
    end if;
    
  end if;
end process;


end Behavioral;
