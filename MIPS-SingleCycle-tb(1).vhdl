LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.STD_LOGIC_MISC.ALL;
-- This is the MIPS simulator testbench
entity MIPS_tb is
end MIPS_tb;

ARCHITECTURE behavior of MIPS_tb is

constant clock_period : time := 100 ns;

component MIPS
	port (creset, clock : in STD_LOGIC; error : out std_logic_vector (3 downto 0));
end component;

for MIPS_instance_1 : MIPS use entity work.MIPS;

signal clock : STD_LOGIC := '0';
signal creset : STD_LOGIC := '1';
signal error : std_logic_vector (3 downto 0);

BEGIN
	MIPS_instance_1 : MIPS port map (creset => creset, clock => clock, error=>error);

	-- reset the logic
	logic_reset :process
		begin
		creset <= '1';
		wait for 120 ns;
		creset <= '0';
		wait;
		end
	process;

	-- Clock process definitions
	clock_process :process
		begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
		end 
	process;
	

end behavior;
