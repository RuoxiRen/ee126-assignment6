library ieee;
use ieee.std_logic_1164.all;

entity ForwardUnit is 
port(
     EXMEMregWrite    : in STD_LOGIC;
     MEMWBregWrite    : in STD_LOGIC; 
     EXMEMRd          : in STD_LOGIC_VECTOR(4 downto 0);
     IDEXRs           : in STD_LOGIC_VECTOR(4 downto 0);
     IDEXRt           : in STD_LOGIC_VECTOR(4 downto 0);
     MEMWBRd          : in STD_LOGIC_VECTOR(4 downto 0);
    
     ForwardA         : out STD_LOGIC_VECTOR(1 downto 0);
     ForwardB         : out STD_LOGIC_VECTOR(1 downto 0)
);
end ForwardUnit;

architecture ForwardUnit_arch of ForwardUnit is
begin
	process(EXMEMregWrite,MEMWBregWrite,EXMEMRd,IDEXRs,IDEXRt,MEMWBRd)
	begin
		if ((EXMEMregWrite='1') and (EXMEMRd /="00000") and (EXMEMRd = IDEXRs)) then
			ForwardA <= "10";
		elsif ((MEMWBRegWrite ='1') and (MEMWBRd /= "00000") and (MEMWBRd = IDEXRs)) then
			ForwardA <= "01";
		else
			ForwardA <= "00";
		end if;

		if ((EXMEMregWrite='1') and (EXMEMRd /="00000") and (EXMEMRd = IDEXRt)) then
			ForwardB <= "10";
		elsif ((MEMWBRegWrite ='1') and (MEMWBRd /= "00000") and (MEMWBRd = IDEXRt)) then
			ForwardB <= "01";
		else
			ForwardB <= "00";
		end if;
	end process;
end ForwardUnit_arch;