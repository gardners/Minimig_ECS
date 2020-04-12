----------------------------------------------------------------------------------
-- Debbug output on Nexys4DDR 7-Digit display
-- done by sy2002 in April 2020 for the MEGA65 project
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity debug_7digits is
port(
   clk            : in std_logic;     
   ram_address		: in std_logic_vector(21 downto 1); -- sram address bus 
   
   -- 7 segment display needs multiplexed approach due to common anode
   SSEG_AN     : out std_logic_vector (7 downto 0);   -- common anode: selects digit
   SSEG_CA     : out std_logic_vector (7 downto 0)    -- cathode: selects segment within a digit      
);
end debug_7digits;

architecture Behavioral of debug_7digits is

signal trigger_display : std_logic;
signal dbgout_ram_address : std_logic_vector(21 downto 1) := "111111111111111111111";
signal dbgout_cnt : unsigned(7 downto 0) := x"00";

component drive_7digits is
generic (
   CLOCK_DIVIDER        : integer                  -- clock divider: clock cycles per digit cycle
);
port (
   clk    : in std_logic;                          -- clock signal divided by above mentioned divider
   
   digits : in std_logic_vector(31 downto 0);      -- the actual information to be shown on the display
   mask   : in std_logic_vector(7 downto 0);       -- control individual digits ('1' = digit is lit)
   
   -- 7 segment display needs multiplexed approach due to common anode
   SSEG_AN     : out std_logic_vector (7 downto 0); -- common anode: selects digit
   SSEG_CA     : out std_logic_vector (7 downto 0) -- cathode: selects segment within a digit   
);
end component;

component SyTargetCounter is
generic (
   COUNTER_FINISH : integer;                 -- target value
   COUNTER_WIDTH  : integer range 2 to 32    -- bit width of target value
);
port (
   clk       : in std_logic;                 -- clock
   reset     : in std_logic;                 -- async reset
   
   cnt       : out std_logic_vector(COUNTER_WIDTH - 1 downto 0); -- current value
   overflow  : out std_logic := '0' -- true for one clock cycle when the counter wraps around
);
end component;

begin

   
   ram_read_delay : SyTargetCounter
      generic map (
         COUNTER_FINISH => 30000000,
         COUNTER_WIDTH => 26
      )
      port map (
         clk => clk,
         reset => '0',
         overflow => trigger_display
      );
      
   ram_reader : process(trigger_display)
   begin
      if rising_edge(trigger_display) then
         dbgout_ram_address <= ram_address;
         dbgout_cnt <= dbgout_cnt + 1;
      end if;
   end process;
      
   segdisplay : drive_7digits
      generic map (
         CLOCK_DIVIDER => 100000
      )
      port map (
         clk => clk,
         digits(31 downto 24) => std_logic_vector(dbgout_cnt(7 downto 0)),
         digits(23 downto 21) => (others => '0'),
         digits(20 downto 0) => dbgout_ram_address(21 downto 1),
         mask => x"FF",
         SSEG_AN => SSEG_AN,
         SSEG_CA => SSEG_CA
      );
   
end Behavioral;

