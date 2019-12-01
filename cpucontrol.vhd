library IEEE;
use IEEE.STD_LOGIC_1164.ALL; -- STD_LOGIC and STD_LOGIC_VECTOR
use IEEE.numeric_std.ALL; -- to_integer and unsigned

entity CPUControl is
-- Functionality should match the truth table shown in Figure 4.22 of the textbook, inlcuding the
--    output 'X' values.
-- The truth table in Figure 4.22 omits the jump instruction:
--    Jump = '1'
--    MemWrite = RegWrite = '0'
--    all other outputs = 'X'
port(Opcode   : in  STD_LOGIC_VECTOR(5 downto 0);
     RegDst   : out STD_LOGIC;
     Branch   : out STD_LOGIC;
     MemRead  : out STD_LOGIC;
     MemtoReg : out STD_LOGIC;
     MemWrite : out STD_LOGIC;
     ALUSrc   : out STD_LOGIC;
     RegWrite : out STD_LOGIC;
     Jump     : out STD_LOGIC;
     ALUOp    : out STD_LOGIC_VECTOR(1 downto 0)
);
end CPUControl;

architecture cpucontrol_behaviour of CPUControl is
begin 
	process(Opcode)
	begin 
		case (Opcode) is
			when "000000" => -- R type
				RegDst <= '1';
				Branch <= '0';
				MemRead <= '0';
				MemtoReg <= '0';
				MemWrite <= '0';
				ALUSrc <= '0';
				RegWrite <= '1';
				Jump <= '0';
				ALUOp <= "10";
			when "100011" => -- lw
				RegDst <= '0';
				Branch <= '0';
				MemRead <= '1';
				MemtoReg <= '1';
				MemWrite <= '0';
				ALUSrc <= '1';
				RegWrite <= '1';
				Jump <= '0';
				ALUOp <= "00";
			when "101011" => -- sw
				RegDst <= 'X';
				Branch <= '0';
				MemRead <= '0';
				MemtoReg <= 'X';
				MemWrite <= '1';
				ALUSrc <= '1';
				RegWrite <= '0';
				Jump <= '0';
				ALUOp <= "00";
			when "000100" => -- beq
				RegDst <= 'X';
				Branch <= '1';
				MemRead <= '0';
				MemtoReg <= 'X';
				MemWrite <= '0';
				ALUSrc <= '0';
				RegWrite <= '0';
				Jump <= '0';
				ALUOp <= "01";
			when "000010" => -- jump
				RegDst <= 'X';
				Branch <= 'X';
				MemRead <= 'X';
				MemtoReg <= 'X';
				MemWrite <= '0';
				ALUSrc <= 'X';
				RegWrite <= '0';
				Jump <= '1';
				ALUOp <= "XX";
			when others => 
				RegDst <= 'X';
				Branch <= 'X';
				MemRead <= 'X';
				MemtoReg <= 'X';
				MemWrite <= 'X';
				ALUSrc <= 'X';
				RegWrite <= 'X';
				Jump <= 'X';
				ALUOp <= "XX";
		end case;
	end process;
end cpucontrol_behaviour;