library ieee;
use ieee.std_logic_1164.all;

entity MUX32ALUaEX is -- Three by two mux with 32 bit inputs/outputs
port(
    in0    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 00
    in1    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 01
    in2    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 10
    sel    : in STD_LOGIC_VECTOR(1 downto 0); -- selects in0 or in1 or in2
    output : out STD_LOGIC_VECTOR(31 downto 0)
);
end MUX32ALUaEX;


architecture MUX32ALUaEX_ar of MUX32ALUaEX is
begin
	assign_output : process(in0, in1, sel) is
	begin
		if (sel = "00") then
			output <= in0;
		elsif (sel = "01") then
			output <= in1;
		elsif (sel = "10") then
			output <= in2;
		else
			output <= "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU";
		end if;
	end process assign_output;
end MUX32ALUaEX_ar;