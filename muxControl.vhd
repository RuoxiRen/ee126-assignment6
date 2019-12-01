library IEEE;
use IEEE.STD_LOGIC_1164.ALL; -- STD_LOGIC and STD_LOGIC_VECTOR
use IEEE.numeric_std.ALL; -- to_integer and unsigned

entity MUXControl is 
port(
    RegDstIn    : in STD_LOGIC:='0';
    BranchIn    : in STD_LOGIC:='0';
    MemReadIn   : in STD_LOGIC:='0';
    MemtoRegIn  : in STD_LOGIC:='0';
    MemWriteIn  : in STD_LOGIC:='0';
    ALUSrcIn    : in STD_LOGIC:='0';
    RegWriteIn  : in STD_LOGIC:='0';
    JumpIn      : in STD_LOGIC:='0';
    ALUOpIn     : in STD_LOGIC_VECTOR(1 downto 0):="00";
    sel         : in std_logic;

    RegDstOut   : out STD_LOGIC:='0';
    BranchOut   : out STD_LOGIC:='0';
    MemReadOut  : out STD_LOGIC:='0';
    MemtoRegOut : out STD_LOGIC:='0';
    MemWriteOut : out STD_LOGIC:='0';
    ALUSrcOut   : out STD_LOGIC:='0';
    RegWriteOut : out STD_LOGIC:='0';
    JumpOut     : out STD_LOGIC:='0';
    ALUOpOut    : out STD_LOGIC_VECTOR(1 downto 0):="00"
);
end MUXControl;

architecture MUXControl_ar of MUXControl is
begin
	process(RegDstIn,BranchIn,MemReadIn,MemtoRegIn,MemWriteIn,ALUSrcIn,RegWriteIn,JumpIn,ALUOpIn,sel)
	begin
		if(sel = '0') then
			RegDstOut <= RegDstIn;
			BranchOut <= BranchIn;
			MemReadOut <= MemReadIn;
			MemtoRegOut <= MemtoRegIn;
			MemWriteOut <= MemWriteIn;
			ALUSrcOut <= ALUSrcIn;
			RegWriteOut <= RegWriteIn;
			JumpOut <= JumpIn;
			ALUOpOut <= ALUOpIn;
		else
			RegDstOut <= '0';
			BranchOut <= '0';
			MemReadOut <= '0';
			MemtoRegOut <= '0';
			MemWriteOut <= '0';
			ALUSrcOut <= '0';
			RegWriteOut <= '0';
			JumpOut <= '0';
			ALUOpOut <= "00";
		end if;
	end process;
end MUXControl_ar;




			