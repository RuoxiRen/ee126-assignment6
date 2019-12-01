library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.all;

entity isEqual is
port(
	data1 : in std_logic_vector(31 downto 0);
	data2 : in std_logic_vector(31 downto 0);
	equal : out std_logic
);
end isEqual;

architecture isEqual_arch of isEqual is
begin
	process(data1,data2)
	begin
		if data1 = data2 then
			equal <= '1';
		else 
			equal <= '0';
		end if;
	end process;
end isEqual_arch;