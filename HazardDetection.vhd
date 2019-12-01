library ieee;
use ieee.std_logic_1164.all;

entity STALL is 
port(
    IDEXMemRead    : in std_logic;
    IDEXRt         : in STD_LOGIC_VECTOR(4 downto 0);
    IFIDRs         : in STD_LOGIC_VECTOR(4 downto 0);
    IFIDRt         : in STD_LOGIC_VECTOR(4 downto 0);    
    PCen           : out std_logic;
    IFIDen         : out std_logic;
    MUXControlen   : out std_logic
);
end STALL;

architecture STALL_arch of STALL is
begin
	process(IDEXMemRead,IDEXRt,IFIDRs,IFIDRt)
	begin
		if(IDEXMemRead = '1' and ((IDEXRt=IFIDRs) or (IDEXRt=IFIDRt))) then
			PCen <= '0';
			IFIDen <= '0';
			MUXControlen <= '1';
		else
			PCen <= '1';
			IFIDen <= '1';
			MUXControlen <= '0';
		end if;
	end process;
end STALL_arch;
