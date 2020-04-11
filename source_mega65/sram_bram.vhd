----------------------------------------------------------------------------------
-- Basic SRAM implemented as BRAM
-- done by sy2002 in March/April 2020 for the MEGA65 project
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sram_bram is
port(
   clk            : in std_logic;  
   
   sram_in  		: in std_logic_vector(15 downto 0);  -- sram data bus in    
   sram_out		   : out std_logic_vector(15 downto 0); -- sram data bus out
   
   ram_address		: in std_logic_vector(21 downto 1); -- sram address bus 
   n_ram_bhe		: in std_logic;                     -- sram upper byte select
   n_ram_ble		: in std_logic;                     -- sram lower byte select
   n_ram_we		   : in std_logic;                     -- sram write enable
   n_ram_oe		   : in std_logic;                     -- sram output enable
   
   -- 7 segment display needs multiplexed approach due to common anode
   SSEG_AN     : out std_logic_vector (7 downto 0);   -- common anode: selects digit
   SSEG_CA     : out std_logic_vector (7 downto 0)    -- cathode: selects segment within a digit      
);
end sram_bram;

architecture Behavioral of sram_bram is

--constant ramsize : integer := 262143; -- 256k words 512 KB
constant ramsize : integer := 61439 + 3 * 1024;
type ram_t is array (0 to ramsize) of std_logic_vector(15 downto 0);
signal ram : ram_t := (others => x"0000");

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

   ram_readwrite : process (clk)
   begin
      if rising_edge(clk) then
         -- write      
         if n_ram_we = '0' then         
            if n_ram_bhe = '0' then
               ram(conv_integer(ram_address(18 downto 1)))(15 downto 8) <= sram_in(15 downto 8);
            end if;
            if n_ram_ble = '0' then
               ram(conv_integer(ram_address(18 downto 1)))(7 downto 0)  <= sram_in(7 downto 0);
            end if;
         end if;
         
         -- read
         if n_ram_oe = '0' then
            sram_out <= ram(conv_integer(ram_address));
         else
            sram_out <= (others => 'Z');
         end if;
      end if;
   end process;
   
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

