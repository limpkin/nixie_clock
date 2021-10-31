----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:17:54 07/30/2016 
-- Design Name: 
-- Module Name:    counter_divider - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity counter_divider is
    Port ( clk_in : in  STD_LOGIC;
           reset_in : in  STD_LOGIC;
           clock_div_out : out  STD_LOGIC);
end counter_divider;

architecture Behavioral of counter_divider is
	constant divider_constant : integer := 9999999;
	signal clk_1Hz_i : std_logic;
begin
	process(clk_in, reset_in)
		subtype count_type is integer range 0 to divider_constant;
		variable counter : count_type := 0;
	begin
		if reset_in = '0' then
			counter := 0;
			clk_1Hz_i <= '0';
		elsif clk_in'event and clk_in = '1' then
			if counter = divider_constant then
				counter := 0;
				clk_1Hz_i <= not clk_1Hz_i;
			else
				counter := counter + 1;
			end if;
		end if;
	end process;
	
clock_div_out <= clk_1Hz_i;
end Behavioral;

