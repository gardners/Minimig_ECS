----------------------------------------------------------------------------------
-- Basic SRAM implemented as BRAM
-- done by sy2002 in March/April 2020 for the MEGA65 project
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sram_bram is
port(
   clk            : in std_logic;  
   
   sram_in  		: in std_logic_vector(15 downto 0);  -- sram data bus in    
   sram_out		   : out std_logic_vector(15 downto 0); -- sram data bus out
   
   ram_address		: in std_logic_vector(21 downto 1); -- sram address bus
   n_ram_ce		   : in std_logic_vector(3 downto 0);  -- sram chip enable
   n_ram_bhe		: in std_logic;                     -- sram upper byte select
   n_ram_ble		: in std_logic;                     -- sram lower byte select
   n_ram_we		   : in std_logic;                     -- sram write enable
   n_ram_oe		   : in std_logic                      -- sram output enable      
);
end sram_bram;

architecture Behavioral of sram_bram is

type ram_t is array (0 to 262143) of std_logic_vector(15 downto 0);
signal ram : ram_t := (others => x"0000");

signal output: std_logic_vector(15 downto 0);

begin

   ram_readwrite : process (clk)
   begin
      if rising_edge(clk) then
         -- write      
--         if n_ram_we = '0' and n_ram_ce(0) = '0' then
         if n_ram_we = '0' then
            if n_ram_bhe = '0' then
               ram(conv_integer(ram_address(18 downto 1)))(15 downto 8) <= sram_in(15 downto 8);
            end if;
            if n_ram_ble = '0' then
               ram(conv_integer(ram_address(18 downto 1)))(7 downto 0)  <= sram_in(7 downto 0);
            end if;
         end if;
         
         -- read
--         if n_ram_ce(0) = '0' and n_ram_oe = '0' then
         if n_ram_oe = '0' then
            if n_ram_bhe = '0' then
               output(15 downto 8) <= ram(conv_integer(ram_address))(15 downto 8);
            end if;
            if n_ram_ble = '0' then
               output(7 downto 0) <= ram(conv_integer(ram_address))(7 downto 0);         
            end if;
         end if;
         output <= (others => 'Z');
      end if;
   end process;
   
   manage_tristate : process(n_ram_ce, n_ram_oe)
   begin
      if n_ram_ce(0) = '0' and n_ram_oe = '0' then
         sram_out <= output;
      else
         sram_out <= (others => 'Z');
      end if;
   end process;

end Behavioral;

