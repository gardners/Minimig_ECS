library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity debounce is
  port (clk : in std_logic;
	signal_in : in std_logic;
	signal_out : out std_logic
	);
end entity;

architecture quick_and_dirty of debounce is
  signal s1 : std_logic;
  signal s2 : std_logic;

begin

  process(clk) 
  begin
    if rising_edge(clk) then
      s1 <= signal_in;
      s2 <= s1;
      signal_out <= signal_in and s1 and s2;
    end if;
  end process;

end quick_and_dirty;
