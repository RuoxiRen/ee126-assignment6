library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.all;


entity PipelinedCPU2 is
port(
     clk :in std_logic;
     rst :in std_logic;
     --Probe ports used for testing or for the tracker.
     DEBUG_IF_SQUASH : out std_logic;
     DEBUG_REG_EQUAL : out std_logic;
     -- Forwarding control signals
     DEBUG_FORWARDA : out std_logic_vector(1 downto 0);
     DEBUG_FORWARDB : out std_logic_vector(1 downto 0);

     --The current address (in various pipe stages)
     DEBUG_PC, DEBUG_PCPlus4_ID, DEBUG_PCPlus4_EX, DEBUG_PCPlus4_MEM,
               DEBUG_PCPlus4_WB: out STD_LOGIC_VECTOR(31 downto 0);
     -- instruction is a store.
     DEBUG_MemWrite, DEBUG_MemWrite_EX, DEBUG_MemWrite_MEM: out STD_LOGIC;
     -- instruction writes the regfile.
     DEBUG_RegWrite, DEBUG_RegWrite_EX, DEBUG_RegWrite_MEM, DEBUG_RegWrite_WB: out std_logic;
     -- instruction is a branch or a jump.
     DEBUG_Branch, DEBUG_Jump: out std_logic;

     DEBUG_PC_WRITE_ENABLE : out STD_LOGIC;
     --The current instruction (Instruction output of IMEM)
     DEBUG_INSTRUCTION : out std_logic_vector(31 downto 0);
     --DEBUG ports from other components
     DEBUG_TMP_REGS : out std_logic_vector(32*4 - 1 downto 0);
     DEBUG_SAVED_REGS : out std_logic_vector(32*4 - 1 downto 0);
     DEBUG_MEM_CONTENTS : out std_logic_vector(32*4 - 1 downto 0)
);
end PipelinedCPU2;


architecture PipelinedCPU_arch of PipelinedCPU2 is
component PC is 
port(
     clk          : in  STD_LOGIC; -- Propogate AddressIn to AddressOut on rising edge of clock
     write_enable : in  STD_LOGIC:='1'; -- Only write if '1'
     rst          : in  STD_LOGIC; -- Asynchronous reset! Sets AddressOut to 0x0
     AddressIn    : in  STD_LOGIC_VECTOR(31 downto 0); -- Next PC address
     AddressOut   : out STD_LOGIC_VECTOR(31 downto 0) -- Current PC address
);
end component;

component ADDALU is
-- Adds two signed 32-bit inputs
-- output = in1 + in2
port(
     in0    : in  STD_LOGIC_VECTOR(31 downto 0);
     in1    : in  STD_LOGIC_VECTOR(31 downto 0);
     output : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;

component ADDPC is
-- Adds two signed 32-bit inputs
-- output = in1 + in2
port(
     in0    : in  STD_LOGIC_VECTOR(31 downto 0);
     in1    : in  STD_LOGIC_VECTOR(31 downto 0);
     output : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;


component ALU is 
port(
     a         : in     STD_LOGIC_VECTOR(31 downto 0);
     b         : in     STD_LOGIC_VECTOR(31 downto 0);
     operation : in     STD_LOGIC_VECTOR(3 downto 0);
     result    : buffer STD_LOGIC_VECTOR(31 downto 0);
     zero      : buffer STD_LOGIC;
     overflow  : buffer STD_LOGIC
);
end component;

component ALUControl is
port(
     ALUOp     : in  STD_LOGIC_VECTOR(1 downto 0);
     Funct     : in  STD_LOGIC_VECTOR(5 downto 0);
     Operation : out STD_LOGIC_VECTOR(3 downto 0)
);
end component;

component AND2 is
port (
      in0    : in  STD_LOGIC;
      in1    : in  STD_LOGIC;
      output : out STD_LOGIC -- in0 and in1
);
end component;

component CPUControl is
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
end component;

component DMEM is
generic(NUM_BYTES : integer := 32);
port(
     WriteData          : in  STD_LOGIC_VECTOR(31 downto 0); -- Input data
     Address            : in  STD_LOGIC_VECTOR(31 downto 0); -- Read/Write address
     MemRead            : in  STD_LOGIC; -- Indicates a read operation
     MemWrite           : in  STD_LOGIC; -- Indicates a write operation
     Clock              : in  STD_LOGIC; -- Writes are triggered by a rising edge
     ReadData           : out STD_LOGIC_VECTOR(31 downto 0); -- Output data
     --Probe ports used for testing
     -- Four 32-bit words: DMEM(0) & DMEM(4) & DMEM(8) & DMEM(12)
     DEBUG_MEM_CONTENTS : out STD_LOGIC_VECTOR(32*4 - 1 downto 0)
);
end component;

component IMEM is
generic(NUM_BYTES : integer := 128);
port(
     Address  : in  STD_LOGIC_VECTOR(31 downto 0); -- Address to read from
     ReadData : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;

component MUXControl is 
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
end component;

component MUX5 is -- Two by one mux with 5 bit inputs/outputs
port(
    in0    : in STD_LOGIC_VECTOR(4 downto 0); -- sel == 0
    in1    : in STD_LOGIC_VECTOR(4 downto 0); -- sel == 1
    sel    : in STD_LOGIC; -- selects in0 or in1
    output : out STD_LOGIC_VECTOR(4 downto 0)
);
end component;

component MUX32ALUb is -- Two by one mux with 32 bit inputs/outputs
port(
    in0    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 0
    in1    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 1
    sel    : in STD_LOGIC; -- selects in0 or in1
    output : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;

component MUX32Branch is -- Two by one mux with 32 bit inputs/outputs
port(
    in0    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 0
    in1    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 1
    sel    : in STD_LOGIC; -- selects in0 or in1
    output : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;

component MUX32Jump is -- Two by one mux with 32 bit inputs/outputs
port(
    in0    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 0
    in1    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 1
    sel    : in STD_LOGIC; -- selects in0 or in1
    output : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;

component MUX32WB is -- Two by one mux with 32 bit inputs/outputs
port(
    in0    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 0
    in1    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 1
    sel    : in STD_LOGIC; -- selects in0 or in1
    output : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;

component MUX32ALUaEX is -- Two by one mux with 32 bit inputs/outputs
port(
    in0    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 0
    in1    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 1
    in2    : in STD_LOGIC_VECTOR(31 downto 0);
    sel    : in STD_LOGIC_VECTOR(1 downto 0); -- selects in0 or in1
    output : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;

component MUX32ALUbEX is -- Two by one mux with 32 bit inputs/outputs
port(
    in0    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 0
    in1    : in STD_LOGIC_VECTOR(31 downto 0); -- sel == 1
    in2    : in STD_LOGIC_VECTOR(31 downto 0);
    sel    : in STD_LOGIC_VECTOR(1 downto 0); -- selects in0 or in1
    output : out STD_LOGIC_VECTOR(31 downto 0)
);
end component;

component registers is
port(RR1      : in  STD_LOGIC_VECTOR (4 downto 0); 
     RR2      : in  STD_LOGIC_VECTOR (4 downto 0); 
     WR       : in  STD_LOGIC_VECTOR (4 downto 0); 
     WD       : in  STD_LOGIC_VECTOR (31 downto 0);
     RegWrite : in  STD_LOGIC;
     Clock    : in  STD_LOGIC;
     RD1      : out STD_LOGIC_VECTOR (31 downto 0);
     RD2      : out STD_LOGIC_VECTOR (31 downto 0);
     --Probe ports used for testing
     -- $t0 & $t1 & t2 & t3
     DEBUG_TMP_REGS : out STD_LOGIC_VECTOR(32*4 - 1 downto 0);
     -- $s0 & $s1 & s2 & s3
     DEBUG_SAVED_REGS : out STD_LOGIC_VECTOR(32*4 - 1 downto 0)
);
end component;

component ShiftLeft2Jump is -- Shifts the input by 2 bits
port(
     x : in  STD_LOGIC_VECTOR(31 downto 0);
     y : out STD_LOGIC_VECTOR(31 downto 0) -- x << 2
);
end component;

component ShiftLeft2Imm is -- Shifts the input by 2 bits
port(
     x : in  STD_LOGIC_VECTOR(31 downto 0);
     y : out STD_LOGIC_VECTOR(31 downto 0) -- x << 2
);
end component;

component SignExtend is
port(
     x : in  STD_LOGIC_VECTOR(15 downto 0);
     y : out STD_LOGIC_VECTOR(31 downto 0) -- sign-extend(x)
);
end component;


component IFIDReg is 
port(
     clk            : in   STD_LOGIC; 
     rst            : in   STD_LOGIC;
     flush          : in   STD_LOGIC;
     write_enable   : in   STD_LOGIC;
     addressIn      : in   STD_LOGIC_VECTOR(31 downto 0); 
     instructionIn  : in   STD_LOGIC_VECTOR(31 downto 0); 
     addressOut     : out  STD_LOGIC_VECTOR(31 downto 0):=X"00000000"; 
     instructionOut : out  STD_LOGIC_VECTOR(31 downto 0):=X"00000000" 
);
end component;


component IDEXReg is 
port(
     clk            : in STD_LOGIC;
     rst            : in STD_LOGIC;
     write_enable   : in STD_LOGIC;
     -- Control Signal 
     RegDstIn       : in STD_LOGIC;
     BranchIn       : in STD_LOGIC;
     MemReadIn      : in STD_LOGIC;
     MemtoRegIn     : in STD_LOGIC;
     MemWriteIn     : in STD_LOGIC;
     ALUSrcIn       : in STD_LOGIC;
     RegWriteIn     : in STD_LOGIC;
     ALUOpIn        : in STD_LOGIC_VECTOR(1 downto 0);
     -- PC
     addressIn      : in  STD_LOGIC_VECTOR(31 downto 0);  
     -- Register Data
     RD1In          : in  STD_LOGIC_VECTOR(31 downto 0);
     RD2In          : in  STD_LOGIC_VECTOR(31 downto 0); 
     extendedIn     : in  STD_LOGIC_VECTOR(31 downto 0);
     -- Instructions
     Ins2016In      : in STD_LOGIC_VECTOR(4 downto 0);
     Ins1511In      : in STD_LOGIC_VECTOR(4 downto 0);
     Ins2521In      : in STD_LOGIC_VECTOR(4 downto 0);
     -- Signal for WB and MEM
     WBsigOut       : out STD_LOGIC_VECTOR(1 downto 0):="00";
     MsigOut        : out STD_LOGIC_VECTOR(2 downto 0):="000";
    
    
     RegDstOut      : out STD_LOGIC:='0';
     ALUSrcOut      : out STD_LOGIC:='0';
     ALUOpOut       : out STD_LOGIC_VECTOR(1 downto 0):="00";
    
     addressOut     : out STD_LOGIC_VECTOR(31 downto 0):=x"00000000";
    
     RD1Out         : out STD_LOGIC_VECTOR(31 downto 0):=x"00000000";
     RD2Out         : out STD_LOGIC_VECTOR(31 downto 0):=x"00000000"; 
     extendedOut    : out STD_LOGIC_VECTOR(31 downto 0):=x"00000000";
    
     Ins2016Out     : out STD_LOGIC_VECTOR(4 downto 0):="00000";
     Ins1511Out     : out STD_LOGIC_VECTOR(4 downto 0):="00000";
     Ins2521Out     : out STD_LOGIC_VECTOR(4 downto 0):="00000"
);
end component;

component EXMEMReg is
port(
     clk           : in STD_LOGIC; -- Propogate AddressIn to AddressOut on rising edge of clock
     rst           : in STD_LOGIC;
     write_enable  : in STD_LOGIC;
     addressIn     : in STD_LOGIC_VECTOR(31 downto 0);
     WBsigIn       : in STD_LOGIC_VECTOR(1 downto 0);
     MsigIn        : in STD_LOGIC_VECTOR(2 downto 0);
  
     zeroIn        : in STD_LOGIC;
  
     ALUresultIn   : in  STD_LOGIC_VECTOR(31 downto 0); -- Only write if '1'
     RD2In         : in  STD_LOGIC_VECTOR(31 downto 0); -- Asynchronous reset! Sets AddressOut to 0x0
     
     WBRegIn       : in  STD_LOGIC_VECTOR(4 downto 0);
  
  
     addressOut    : out STD_LOGIC_VECTOR(31 downto 0):=x"00000000";
     WBsigOut      : out STD_LOGIC_VECTOR(1 downto 0):="00";
     branchOut     : out STD_LOGIC:='0';
     MemRegOut     : out STD_LOGIC:='0';
     MemWriteOut   : out STD_LOGIC:='0';
  
     zeroOut       : out STD_LOGIC:='0';
  
     ALUresultOut  : out STD_LOGIC_VECTOR(31 downto 0):=x"00000000"; -- Only write if '1'
     RD2Out        : out STD_LOGIC_VECTOR(31 downto 0):=x"00000000"; -- Asynchronous reset! Sets AddressOut to 0x0
     
     WBRegOut      : out STD_LOGIC_VECTOR(4 downto 0):="00000"


);
end component;

component MEMWBReg is
port(
     clk           : in  STD_LOGIC; -- Propogate AddressIn to AddressOut on rising edge of clock
     rst           : in  STD_LOGIC;
     write_enable  : in  STD_LOGIC;
     addressIn     : in  STD_LOGIC_VECTOR(31 downto 0);
     WBsigIn       : in  STD_LOGIC_VECTOR(1 downto 0);
 
     readdataIn    : in  STD_LOGIC_VECTOR(31 downto 0);  
     ALUresultIn   : in  STD_LOGIC_VECTOR(31 downto 0);
 
     WBRegIn       : in  STD_LOGIC_VECTOR(4 downto 0);

     addressOut    : out STD_LOGIC_VECTOR(31 downto 0):=x"00000000";
     RegWriteOut   : out STD_LOGIC:='0';
     MemtoRegOut   : out STD_LOGIC:='0';

     readdataOut   : out STD_LOGIC_VECTOR(31 downto 0):=x"00000000";  
     ALUresultOut  : out STD_LOGIC_VECTOR(31 downto 0):=x"00000000";

     WBRegOut      : out STD_LOGIC_VECTOR(4 downto 0):="00000"


);
end component;

component ForwardUnit is 
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
end  component;

component STALL is 
port(
    IDEXMemRead    : in std_logic;
    IDEXRt         : in STD_LOGIC_VECTOR(4 downto 0);
    IFIDRs         : in STD_LOGIC_VECTOR(4 downto 0);
    IFIDRt         : in STD_LOGIC_VECTOR(4 downto 0);    
    PCen           : out std_logic;
    IFIDen         : out std_logic;
    MUXControlen   : out std_logic
);
end component;

component isEqual is
port(
     data1 : in std_logic_vector(31 downto 0);
     data2 : in std_logic_vector(31 downto 0);
     equal : out std_logic
);
end component;



signal PCenSt , IFIDen: STD_LOGIC;
signal PCin , PCout , PCadd4IF , PCadd4ID , PCadd4EX , PCadd4MEM , PCadd4WB : STD_LOGIC_VECTOR(31 downto 0);
signal InstructionIF , InstructionID : STD_LOGIC_VECTOR(31 downto 0);
signal RegDstID , RegDstEX , BranchID , BranchMEM , MemReadID , MemtoRegID , MemtoRegMEM , MemtoRegWB , MemWriteID , MemWriteMEM , ALUSrcID , ALUSrcEX , RegWriteID , RegWriteWB , JumpID: STD_LOGIC;
signal RegDstID_RAW , BranchID_RAW , MemReadID_RAW , MemtoRegID_RAW , MemWriteID_RAW , ALUSrcID_RAW , RegWriteID_RAW , JumpID_RAW : STD_LOGIC;
signal WriteRegWB , WriteRegEX , WriteRegMEM : STD_LOGIC_VECTOR(4 downto 0);
signal ALUOpID, ALUOpID_RAW , ALUOpEX : STD_LOGIC_VECTOR(1 downto 0);
signal ALUOperationEX : STD_LOGIC_VECTOR(3 downto 0);
signal JumpAddrID : STD_LOGIC_VECTOR(31 downto 0);
signal ImmID, ImmEX , Imm4ID : STD_LOGIC_VECTOR(31 downto 0);
signal BranchAddrID : STD_LOGIC_VECTOR(31 downto 0);
signal WritedataWB , ReadData1ID , ReadData1EX , ReadData2ID , ReadData2EX , ReadData2MEM : STD_LOGIC_VECTOR(31 downto 0);
signal ALUResEX , ALUResMEM , ALUResWB , ALUbEX: STD_LOGIC_VECTOR(31 downto 0);
signal ALUzeroEX , zeroMEM , ALUoverflowEX : STD_LOGIC;
signal MEMRDataMEM , MEMRDataWB : STD_LOGIC_VECTOR(31 downto 0);
signal IAddr0: STD_LOGIC_VECTOR(31 downto 0);
signal BranchSigID : STD_LOGIC;
signal WBsigEX , WBsigMEM : STD_LOGIC_VECTOR(1 downto 0);
signal MsigEX : STD_LOGIC_VECTOR(2 downto 0);
signal Ins2016EX , Ins1511EX , Ins2521EX : STD_LOGIC_VECTOR(4 downto 0);
signal IDEXRt,IFIDRs,IFIDRt : STD_LOGIC_VECTOR(4 downto 0);
signal IDEXMemRead : STD_LOGIC;
signal MUXControlen : STD_LOGIC;
signal EXMEMregWrite : STD_LOGIC;
signal ALUselA , ALUselB : STD_LOGIC_VECTOR(1 downto 0);
signal ALUinA , ALUinB : STD_LOGIC_VECTOR(31 downto 0);

signal tmpReg , savedReg : STD_LOGIC_VECTOR(32*4-1 downto 0);
signal MEMContents : STD_LOGIC_VECTOR(32*4-1 downto 0);
signal EqualID : STD_LOGIC;

begin

IDEXMemRead <= MsigEX(1);
EXMEMregWrite <= WBsigMEM(1);

IDEXRt <= Ins2016EX;
IFIDRs <= InstructionID(20 downto 16);
IFIDRt <= InstructionID(15 downto 11);

-- IF

U0: PC port map(clk,PCenSt,rst,PCin,PCout);
U1: IMEM port map(PCout,InstructionIF);
U2: ADDPC port map(PCout,X"00000004",PCadd4IF);

U4: IFIDReg port map(clk,rst,BranchSigID or JumpID,IFIDen,PCadd4IF,InstructionIF,PCadd4ID,InstructionID);

-- ID


U5: STALL port map(IDEXMemRead,IDEXRt,IFIDRs,IFIDRt,PCenSt,IFIDen,MUXControlen);
U6: CPUControl port map(InstructionID(31 downto 26),RegDstID_RAW,BranchID_RAW,MemReadID_RAW,MemtoRegID_RAW,MemWriteID_RAW,ALUSrcID_RAW,RegWriteID_RAW,JumpID_RAW,ALUOpID_RAW);
U7: registers port map(InstructionID(25 downto 21),InstructionID(20 downto 16),WriteRegWB,WritedataWB,RegWriteWB,clk,ReadData1ID,ReadData2ID,tmpReg,savedReg);
U8: SignExtend port map(InstructionID(15 downto 0),ImmID);
U9: MUXControl port map(RegDstID_RAW,BranchID_RAW,MemReadID_RAW,MemtoRegID_RAW,MemWriteID_RAW,ALUSrcID_RAW,RegWriteID_RAW,JumpID_RAW,ALUOpID_RAW,MUXControlen,RegDstID,BranchID,MemReadID,MemtoRegID,MemWriteID,ALUSrcID,RegWriteID,JumpID,ALUOpID);

U10: isEqual port map(ReadData1ID,ReadData2ID,EqualID);
U11: AND2 port map(BranchID,EqualID,BranchSigID);
U12: ADDALU port map(PCadd4ID,Imm4ID,BranchAddrID);
U13: MUX32Branch port map(PCadd4IF,BranchAddrID,BranchSigID,IAddr0);
U14: ShiftLeft2Jump port map("000000"&InstructionID(25 downto 0),JumpAddrID);
U15: MUX32Jump port map (IAddr0,JumpAddrID,JumpID,PCin);
U16: ShiftLeft2Imm port map(ImmID,Imm4ID);



U17: IDEXReg port map(clk,rst,'1',RegDstID,BranchID,MemReadID,MemtoRegID,MemWriteID,ALUSrcID,RegWriteID,ALUOpID,PCadd4ID,ReadData1ID,ReadData2ID,ImmID,InstructionID(20 downto 16),InstructionID(15 downto 11),InstructionID(25 downto 21),WBsigEX,MsigEX,RegDstEX,ALUSrcEX,ALUOpEX,PCadd4EX,ReadData1EX,ReadData2EX,ImmEX,Ins2016EX,Ins1511EX,Ins2521EX);

-- EX


U18: MUX32ALUaEX port map(ReadData1EX,WritedataWB,ALUResMEM,ALUselA,ALUinA);
U19: MUX32ALUbEX port map(ReadData2EX,WritedataWB,ALUResMEM,ALUselB,ALUinB);

U20: MUX32ALUb port map(ALUinB,ImmEX,ALUSrcEX,ALUbEX);
U21: ALU port map(ALUinA,ALUbEX,ALUOperationEX,ALUResEX,ALUzeroEX,ALUoverflowEX);
U22: ALUControl port map(ALUOpEX,ImmEX(5 downto 0),ALUOperationEX);
U23: MUX5 port map(Ins2016EX,Ins1511EX,RegDstEX,WriteRegEX);

U24: ForwardUnit port map(EXMEMregWrite,RegWriteWB,WriteRegMEM,Ins2521EX,Ins2016EX,WriteRegWB,ALUselA,ALUselB);



U25: EXMEMReg port map(clk,rst,'1',PCadd4EX,WBsigEX,MsigEX,ALUzeroEX,ALUResEX,ALUinB,WriteRegEX,PCadd4MEM,WBsigMEM,BranchMEM,MemtoRegMEM,MemWriteMEM,zeroMEM,ALUResMEM,ReadData2MEM,WriteRegMEM);


-- MEM



U26: DMEM port map(ReadData2MEM,ALUResMEM,MemtoRegMEM,MemWriteMEM,clk,MEMRDataMEM,MEMContents);
U27: MEMWBReg port map(clk,rst,'1',PCadd4MEM,WBsigMEM,MEMRDataMEM,ALUResMEM,WriteRegMEM,PCadd4WB,RegWriteWB,MemtoRegWB,MEMRDataWB,ALUResWB,WriteRegWB);




-- WB
U28: MUX32WB port map(ALUResWB,MEMRDataWB,MemtoRegWB,WritedataWB);











-- PCenSt <='1';
DEBUG_INSTRUCTION <= InstructionID;
DEBUG_TMP_REGS <= tmpReg;
DEBUG_SAVED_REGS <= savedReg;
DEBUG_MEM_CONTENTS <= MEMContents;

DEBUG_PC <= PCout;
DEBUG_PCPlus4_ID <= PCadd4ID;
DEBUG_PCPlus4_EX <= PCadd4EX;
DEBUG_PCPlus4_MEM <= PCadd4MEM;
DEBUG_PCPlus4_WB <= PCadd4WB;

 --Probe ports used for testing or for the tracker.
DEBUG_IF_SQUASH <= BranchSigID or JumpID;
DEBUG_REG_EQUAL <= EqualID;
-- instruction is a store.
DEBUG_MemWrite <= MemWriteID;
DEBUG_MemWrite_EX <= MsigEX(0);
DEBUG_MemWrite_MEM <= MemWriteMEM;
-- instruction writes the regfile.
DEBUG_RegWrite <= RegWriteID;
DEBUG_RegWrite_EX <= WBsigEX(1);
DEBUG_RegWrite_MEM <= WBsigMEM(1);
DEBUG_RegWrite_WB <= RegWriteWB;
-- instruction is a branch or a jump.
DEBUG_Branch <= BranchSigID;
DEBUG_Jump <= JumpID;
--Value of PC.write_enable
DEBUG_PC_WRITE_ENABLE <= PCenSt;
-- Forwarding control signals
DEBUG_FORWARDA <= ALUselA;
DEBUG_FORWARDB <= ALUselB;









end architecture PipelinedCPU_arch;