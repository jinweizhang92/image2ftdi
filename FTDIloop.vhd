----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:49:11 02/13/2016 
-- Design Name: 
-- Module Name:    FTDIloop - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FTDIloop is

    Port ( clk 		: in		STD_LOGIC;
	        reset_h	: in		std_logic;
           rxf_l 		: in  	STD_LOGIC;
           txe_l		: in  	STD_LOGIC;
           oe_l 		: out  	STD_LOGIC;
           rd_l		: out  	STD_LOGIC;
           wr_l 		: out  	STD_LOGIC;
			  siwua		: out  	STD_LOGIC;
			  d			: inout	std_logic_vector(7 downto 0));
			  



end FTDIloop;


architecture Behavioral of FTDIloop is

	signal	nxt_eni		: std_logic := '0';
	signal	nxt_eno		: std_logic := '1';
	signal	d_reg			: std_logic_vector(7 downto 0) := "00000000";
	signal	nxt_oe		: std_logic := '1';
	signal	nxt_rd		: std_logic := '1';
	signal	nxt_wr		: std_logic := '1';
	signal	nxt_siwua	: std_logic := '1';				--how to implement siwu signal--a few clock cycles after writing
	signal	eni			: std_logic := '0';
	signal	eno			: std_logic := '1';
	type		states	is (s0, s1, s2, s3, s4, s5, s6);
	signal	state		: states	:= s0;
	signal	nxt_state	: states := s0;

begin

--process to implement the state register

	clkd: process (clk)
	begin
		if (clk'event and clk = '1') then
			if (reset_h = '1') then
				state <= s0;
			else
				state <= nxt_state;
			end if;
		end if;
	end process clkd;
	
--process to determine the next state

	state_trans: process (rxf_l, txe_l, state)
	begin
		nxt_state <= state;
		case state is 
			when s0 => if (rxf_l = '0') then 
								nxt_state <= s1;
							end if;
			when s1 => 	nxt_state <= s2;

			when s2 =>  --if ((txe_l = '0') or (nxt_rd = '1') ) then 
								nxt_state <= s3;
							--end if;
			when s3 =>  if (txe_l = '0') then
								nxt_state <= s4;								
							end if;
			when s4 => --if (nxt_wr = '1') then 
								nxt_state <= s5;
							--end if;
			when s5 =>	nxt_state <= s6;
			
			when s6 =>	nxt_state <= s0;
			
		end case;
	end process state_trans;
	
--process to define the output values

	output: process (rxf_l, txe_l, state)
	begin
		
		nxt_rd	<= '1';
		nxt_wr	<= '1';
		nxt_oe	<= '1';
		nxt_eno	<= '1';
		nxt_eni	<= '0';
		nxt_siwua <= '1';
		case state is 
			when s0 =>  if (rxf_l = '0') then
								nxt_oe <= '0';
								nxt_siwua <= '1';
--							else 
--								nxt_oe <= '1';
							end if;
							
--			when s1 => wait the data to be driven on d
			when s1 =>  if (rxf_l = '0') then
								nxt_rd	<= '0';
								nxt_eni	<= '1';
								nxt_oe	<= '0';
--							else
--								nxt_rd <= '1';
--								nxt_eni <= '0';
							end if;

			when s2 =>  --if (txe_l = '0') then
								--nxt_oe <= '1';
								--nxt_rd <= '1';
								--nxt_eni <= '0';
--								nxt_wr <= '0';
--								nxt_eno <= '0';
--							else
--								--nxt_oe <= '0';
--								--nxt_rd <= '0';
--								--nxt_eni <= '1';					
--							end if;	
							nxt_oe <= '1';
							nxt_eni <= '0';
							nxt_rd <= '1';
			
			when s3 =>  if (txe_l = '0') then
								nxt_wr  <= '0';
								nxt_eno <= '0';
							else
								nxt_wr  <= '1';
								nxt_eno <= '1';
							end if;
							--nxt_wr  <= '1';
							--nxt_eno <= '1';
			when s4 =>  --if (txe_l = '1') then 
--								nxt_wr  <= '1';
--								nxt_eno <= '1';
--							else
--								nxt_wr  <= '0';
--								nxt_eno <= '0';
--							end if;
							nxt_wr  <= '1';
							nxt_eno <= '1';

			when s5 =>  nxt_siwua <= '1';
			
			when s6 =>	nxt_siwua <= '0';
			
		end case;
	end process output;
	
--process to latch the next signals
	nxtsignal: process (clk)
	begin
		if (clk'event and clk = '1') then
			if (eni = '1') then
				d_reg <= d;
			end if;
			
			eni	<= nxt_eni;
			eno	<= nxt_eno;
			oe_l	<= nxt_oe;
			rd_l	<= nxt_rd;
			wr_l	<= nxt_wr;
			siwua	<= nxt_siwua;
			
		end if;		
	end process nxtsignal;
	
		
--write back by using tri_state buffer		
	d <= d_reg when (eno = '0') else "ZZZZZZZZ";
		
	
end Behavioral;

