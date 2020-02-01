LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_MISC.ALL;

-- this implementation supports add, lw, and beq. 
ENTITY MIPS IS

PORT(
 signal creset, clock 	: in 	STD_LOGIC;
 signal error 		:out std_logic_vector (3 downto 0));
END 	MIPS; -- the error code is set for unexpected events

ARCHITECTURE behavior OF MIPS IS

-- instruction memory is quite small - load programs by editing the initial values
TYPE INST_MEM IS ARRAY (0 to 15) of STD_LOGIC_VECTOR (31 DOWNTO 0);
 
SIGNAL iram : INST_MEM := (

x"8c020008", -- L1 : lw $2, 0x8($0)
x"8c03000c", --      lw $3, 0xc($0) 
x"00432020", --      add $4, $2, $3	 000000|00010|00011|00100|00000100000
x"00842020", --      add $4, $4, $4
x"00000000", --      beq $2, $2, L1 -- you have to adjust the offsets to be relative to PC+4
x"00842822", --      sub $5, $4, $4	 000000|00100|00100|00101|00000100010
x"30880000", --   	 andi $8, $4, 0xFFFF  001100|00100|01000|0000000000000000
x"00822824", -- 	 and $5, $4, $2  000000|00100|00010|00101|00000100100
x"00822825", --      or $5, $4, $2   000000|00100|00010|00101|00000100101
x"3487FFFF", --   	 ori $7, $4, 0xFFFF   001101|00100|00111|1111111111111111
x"0085102A", --   	 slt $2, $4, $5  000000|00100|00101|00010|00000101010
x"AC040008", --   	 sw $4, 0x8($0)  101011|00000|00100|0000000000001000
x"3C09FFFF", --   	 lui $9, 0xFFFF  001111|00000|01001|1111111111111111
);

-- data memory is organized in byte addressable form and some are initialized
TYPE DATA_RAM IS ARRAY (0 to 31) OF STD_LOGIC_VECTOR (7 DOWNTO 0);
   SIGNAL ram: DATA_RAM := (
      X"55", X"55", X"55", X"55",
      X"AA", X"AA", X"AA", X"AA",
      X"01", X"01", X"01", X"01",
      X"02", X"02", X"02", X"02",
      X"03", X"03", X"03", X"03",
      X"00", X"00", X"00", X"00",
      X"00", X"00", X"00", X"00",
      X"00", X"00", X"00", X"00"
      );

-- signals used in fetch logic
signal PC, Next_PC, Branch_PC, Jump_PC, Register_PC : std_logic_vector(11 downto 0) := (others=>'0');-- possible PC values
signal Instruction  : std_logic_vector (31 downto 0);
signal RegWrite: std_logic; -- controls when a register is written

-- signals used to read write the register file
TYPE register_file IS ARRAY ( 0 TO 31 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );
SIGNAL register_array	: register_file; 

-- intermediate decoded signals
SIGNAL read_data_1, read_data_2, Sign_extend : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
SIGNAL read_register_1_address		: STD_LOGIC_VECTOR( 4 DOWNTO 0 ); -- rs
SIGNAL read_register_2_address		: STD_LOGIC_VECTOR( 4 DOWNTO 0 ); -- rt
SIGNAL write_register_address_1		: STD_LOGIC_VECTOR( 4 DOWNTO 0 ); -- rd
SIGNAL write_register_address_0		: STD_LOGIC_VECTOR( 4 DOWNTO 0 ); -- rt
SIGNAL Instruction_immediate_value	: STD_LOGIC_VECTOR( 15 DOWNTO 0 );

-- fields of the encoded instruction 
signal Function_opcode 	: STD_LOGIC_VECTOR( 5 DOWNTO 0 );
signal Opcode	: std_logic_vector(5 downto 0);

-- control signal to pick the next instruction
signal PC_Mux : std_logic_vector(1 DOWNTO 0);

BEGIN  
              
  -- the process covers the sequential portion of the fetch logic
	PROCESS
variable Local_PC : std_logic_vector(11 downto 0); -- local computed value of the PC assigned to the PC signal
		
	BEGIN
	WAIT UNTIL ( clock'EVENT ) AND ( clock = '1' );
		IF creset = '1' THEN
			    Local_PC := X"000" ; -- initialize PC on reset
		ELSE 
		case PC_Mux is   -- this is the PC mux logic. Needs to change to support other instructions (e.g., jal)
			when "00" =>
				Local_PC := Next_PC;
			when "01" =>
				Local_PC := Branch_PC;
			when "10" =>
				Local_PC := Jump_PC;
			when "11" => 
				Local_PC := Register_PC;
			when others =>
				Local_PC := x"fff"; -- value will indidcate an error in PCMux value
		end case;
				
		END IF;
			-- update the PC and fetch the next instruction
		PC <= Local_PC; -- remember every signal should have only one driver!
		Instruction <= iram(CONV_INTEGER(Local_PC(5 downto 2)));
                END PROCESS;

	Next_PC <= PC +4; -- Auto update PC to PC+4. Branches offset from here. 
	

-- extract the fields of the instructions. Note these elements are computed regardless of the specific instruction
	Opcode                       	<= Instruction(31 downto 26);
	Function_opcode              	<= Instruction(5 downto 0);
	read_register_1_address 	<= Instruction( 25 DOWNTO 21 ); -- rs
	read_register_2_address 	<= Instruction( 20 DOWNTO 16 ); -- rt
	write_register_address_1	<= Instruction( 15 DOWNTO 11 ); -- rd
	write_register_address_0 	<= Instruction( 20 DOWNTO 16 ); -- rt which is the destination for some instructions
	Instruction_immediate_value  	<= Instruction( 15 DOWNTO 0 );
	read_data_1 <= register_array(CONV_INTEGER( read_register_1_address ) );  -- read content of rs
		 
	read_data_2 <= register_array(CONV_INTEGER( read_register_2_address ) );  -- read contents of rt

	Sign_extend <= X"0000" & Instruction_immediate_value  -- Sign Extend 16-bits to 32-bits
                       WHEN Instruction_immediate_value(15) = '0'
                       ELSE	X"FFFF" & Instruction_immediate_value;
		
-- compute possible next PC values
	Branch_PC 	<= Next_PC + (Sign_extend (9 downto 0) & "00"); -- convert word offset to byte offset
	Jump_PC <= (Instruction_immediate_value(9 DOWNTO 0) & "00");
	Register_PC <= read_Data_1(11 DOWNTO 0);
-- Next instruction address mux. Compute the value of PCMux
PC_Mux <= "01" when ((read_data_1 = read_data_2) and (opcode = "000100")) else -- for beq
	"10" when (opcode = "000010" or opcode = "000011") else "11" when (opcode = "000000" and Function_opcode = "001000") else "00";

 -- register file write control. Compute the value of the RegWrite signal
RegWrite <= '0' when (opcode = "000100") -- no register writes for beq
	else '1';	-- all other instructions write the register file

PROCESS ( Instruction ) -- when we fetch a new instruction, this process executes
-- declarations for variables whose values are computed in the process, 
-- and assigned to signals at the end - remember should have a singe driver
-- for each signal

variable rf_write_data, memory_address  : std_logic_vector(31 downto 0);
variable rf_dest : std_logic_vector (4 downto 0);
variable error_check : std_logic_vector(3 downto 0);
variable branch_condition : std_logic; 

 	BEGIN
 		-- switch on opcode 
  	CASE Opcode IS
 						 
        WHEN "000000" 	=> --sll
		-- for register-to-register ops need to decode the func field
            CASE Function_opcode IS
              	WHEN "100000" => -- add registers
                
                	rf_write_data := read_Data_1 + read_data_2; -- compute the register write value
					rf_dest := write_register_address_1;  -- set register destination to rd

          		WHEN "100010" => -- sub

          			rf_write_data := read_data_1 - read_data_2; -- compute the register write value
					rf_dest := write_register_address_1;  -- set register destination to rd

          		WHEN "100100" => --and

          			rf_write_data := read_data_1 and read_data_2;
          			rf_dest := write_register_address_1;

          		WHEN "100101" => --or

          			rf_write_data := read_data_1 or read_data_2;
          			rf_dest := write_register_address_1;

				WHEN "101010" => --slt

					IF read_Data_1 < read_data_2 THEN	
						rf_write_data := X"00000001";
					ELSE
						rf_write_data := X"00000000";
					END IF;
					rf_dest := write_register_address_1;

          		WHEN others =>     -- think of this as an error code denoting illegal func field
	             	error_check := x"A";


            END CASE;
	
		WHEN "100011" => -- lw
	             	memory_address := read_data_1 + Sign_extend;
					-- make sure we stay within the 32 byte memory size
	             	rf_write_data (7 DOWNTO 0)   := ram(CONV_INTEGER(memory_address (4 downto 0)));
	             	rf_write_data (15 DOWNTO 8)  := ram(CONV_INTEGER(memory_address(4 downto 0)+1));
	             	rf_write_data (23 DOWNTO 16) := ram(CONV_INTEGER(memory_address(4 downto 0)+2));
	             	rf_write_data (31 DOWNTO 24) := ram(CONV_INTEGER(memory_address(4 downto 0)+3));
			rf_dest := write_register_address_0; -- write to rt


		WHEN "000011" => --jal

				rf_write_data := x"00000" & (Next_PC);
				rf_dest := "11111";


		WHEN "101011" => --sw

				memory_address := read_data_1 + Sign_extend;
				ram(CONV_INTEGER(memory_address(4 downto 0))) <= read_data_2(7 DOWNTO 0);
				ram(CONV_INTEGER(memory_address(4 downto 0) + 1)) <= read_data_2(15 DOWNTO 8);
				ram(CONV_INTEGER(memory_address(4 downto 0) + 2)) <= read_data_2(23 DOWNTO 16);
				ram(CONV_INTEGER(memory_address(4 downto 0) + 3)) <= read_data_2(31 DOWNTO 24);

		WHEN "001111" => --lui

				rf_write_data := Instruction_immediate_value & register_array(CONV_INTEGER(write_register_address_0))(15 DOWNTO 0);
				rf_dest := write_register_address_0;

  		WHEN "001101" => --ori

  			rf_write_data := read_data_1 or (x"0000" & Instruction_immediate_value);
  			rf_dest := write_register_address_0	;

  		WHEN "001100" => --andi

  			rf_write_data := read_data_1 and (x"FFFF" & Instruction_immediate_value);
  			rf_dest := write_register_address_0	;	

		WHEN OTHERS	=>  error_check := x"B";  -- indicates illegal opcode

   	END CASE;	

	-- write the results of the execution to the register file

		if creset = '1' then
		FOR i IN 0 TO 31 LOOP -- initialize registers on reset
				 register_array(i) <= CONV_STD_LOGIC_VECTOR( i, 32 );
 			 END LOOP;-- update PC adn register file on reset
		else
			if RegWrite = '1' then			-- register file write
				register_array( CONV_INTEGER( rf_dest)) <= rf_write_data;
			end if;
		end if;

		Error <= error_check;
												
   END PROCESS;

end behavior;