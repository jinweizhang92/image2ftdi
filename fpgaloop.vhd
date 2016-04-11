----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:52:04 02/20/2016 
-- Design Name: 
-- Module Name:    fpgaloop - Behavioral 
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

--Entity-----------------------------------------------------------------------------------------------------
entity fpgaloop is

	Port (	clk 		: in		STD_LOGIC;							--usb clock
				reset_h	: in		std_logic;
				rxf_l 	: in  	STD_LOGIC;
--				txe_l		: in  	STD_LOGIC;
				oe_l 		: out  	STD_LOGIC;
				rd_l		: out  	STD_LOGIC;
				wr_l 		: out  	STD_LOGIC;
				siwua		: out  	STD_LOGIC;
				d			: in		std_logic_vector(7 downto 0);
				clkb 		: in		STD_LOGIC;							--VGA clock
				r 			: out  	std_logic_vector(2 downto 0) := "000";
				g			: out  	std_logic_vector(2 downto 0) := "000";
				b 			: out  	std_logic_vector(2 downto 0) := "000";
				hs			: out  	STD_LOGIC;
				vs 			: out  	STD_LOGIC;
				rstb			: in		std_logic);

end fpgaloop;		  
--End entity--------------------------------------------------------------------------------------------------


--Architecture------------------------------------------------------------------------------------------------
architecture Behavioral of fpgaloop is

	signal	cnt_rst		: std_logic := '0';     --High active to reset address counter.
--	signal	cnt_add		: std_logic_vector(15 downto 0) := "0000000000000000";
	signal	chkrst		: std_logic_vector(15 downto 0) := "0000000000000000";	--check the reset vector ffffH
	signal	wea			: std_logic_vector (0 downto 0) := "0";
--	signal	half			: std_logic := '0';	--If high, first byte in two has been received
	signal	hld_l			: std_logic := '0';
	signal	wr_start		: std_logic := '0';		--Indicate the first cycle of the write process
	signal	byte_h		: std_logic_vector(7 downto 0) := "11111111";
	signal	byte_l		: std_logic_vector(7 downto 0) := "00000000";

	signal	addra			: std_logic_vector(15 downto 0) := "0000000000000000";
	signal	nxt_addra	: std_logic_vector(15 downto 0) := "0000000000000000";
	signal	addrb			: std_logic_vector(15 downto 0) := "0000000000000000";
	signal	dina			: std_logic_vector(8 downto 0) := "000000000";
	signal	doutb			: std_logic_vector(8 downto 0) := "000000000";
--	signal	clka			: std_logic;
--	signal	clkb			: std_logic;
--	signal	rstb			: std_logic := '0';
	signal	nxt_oe		: std_logic := '1';
	signal	nxt_rd		: std_logic := '1';
--	signal	nxt_wr		: std_logic := '1';
--	signal	nxt_siwua	: std_logic := '1';				
	type		states		is (s0, s1, s2, s3,s4);
	signal	state			: states	:= s0;
	signal	nxt_state	: states := s0;
	signal	crash			: std_logic := '0';
	signal	h_on			: std_logic_vector (2 downto 0) := "000";
	signal	count_h		: std_logic_vector(9 downto 0) := "0000000000";
	signal	count_v		: std_logic_vector(9 downto 0) := "0000000000";
	signal	hs_tmp		: std_logic := '1';
	signal	vs_tmp		: std_logic := '1';
	signal	r_tmp			: std_logic := '0';
	signal	g_tmp			: std_logic := '0';
	signal	b_tmp			: std_logic := '0';
	
	
	
--Define the component of my dual port memory---------------------------------------------------------------
	COMPONENT mydport
	 PORT (
	 clka : IN STD_LOGIC;
	 wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
	 addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	 dina : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
	 clkb : IN STD_LOGIC;
	 rstb : IN STD_LOGIC;
	 addrb : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	 doutb : OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
	 );
	END COMPONENT;
--End component --------------------------------------------------------------------------------------------


--Concurrent area-------------------------------------------------------------------------------------------
begin

	ram : mydport
	 PORT MAP (
	 clka => clk,
	 wea => wea,
	 addra => addra,
	 dina => dina,
	 clkb => clkb,
	 rstb => rstb,
	 addrb => addrb,
	 doutb => doutb
	 );

--Do need to write back-------------------------------------------------------------------------------------
	wr_l	<= '1';
	siwua	<= '1';

--Concatenate the 9-bit RGB data and feed into dina---------------------------------------------------------
	dina	<= (byte_h(0) & byte_l);
--	addrb	<= (count_v(7 downto 0)) & (count_h(7 downto 0));


--Drive RGB-------------------------------------------------------------------------------------------------
	hs <= hs_tmp;
	vs <= vs_tmp;
--	r <= (doutb(8 downto 6) and h_on) ;
--	g <= (doutb(5 downto 3) and h_on) ;
--	b <= (doutb(2 downto 0) and h_on) ;
	r <= doutb(8 downto 6) when (h_on = "111") else "000";
	g <= doutb(5 downto 3) when (h_on = "111") else "000";
	b <= doutb(2 downto 0) when (h_on = "111") else "000";

--Subtract the offset from hs and vs, the offset number may need to change----------------------------------
	addrb <= (  (count_v(7 downto 0) - 1) & (count_h(7 downto 0) -47)  ); 		

-- Check system reset when ffffH is received----------------------------------------------------------------
	crash <= '1' when ((byte_h & byte_l) = ("0000000000000000")) else '0';
	
	
--process to implement the state register-------------------------------------------------------------------

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
	
--process to determine the next state-----------------------------------------------------------------------

	state_trans: process (rxf_l, crash, addra, state)
	begin
		nxt_state <= state;
		case state is 
			when s0 => if (rxf_l = '0') then 
								nxt_state <= s1;
							end if;
							
			when s1 => 	nxt_state <= s2;
														

			when s2 =>  if(rxf_l = '1') then
								nxt_state <= s0;
							elsif (addra = 65535) then
								nxt_state <= s3;
							end if;
							if (crash = '1') then
								nxt_state <= s4;
							end if;
								
			when s3 =>  if (rxf_l = '0') then
								nxt_state <= s2;
							else
								nxt_state <= s0;
							end if;
			when s4 =>	nxt_state <= s0; 				
			
		end case;
	end process state_trans;
	
	
--process to define the output values----------------------------------------------------------------
	output: process (rxf_l, addra, state)
	begin
		cnt_rst	<= '0';
		nxt_rd	<= '1';
----	nxt_wr	<= '1';
		nxt_oe	<= '1';
----	nxt_siwua <= '1';
		hld_l <= '0';

		case state is 
			when s0 =>  if (rxf_l = '0') then
								nxt_oe <= '0';
							end if;
							
							hld_l <= '0';
							
--			when s1, wait the data to be driven on d
			when s1 => 
								nxt_rd	<= '0';
								nxt_oe	<= '0';
								hld_l		<= '1';

			when s2 =>  if (rxf_l = '0') then
								hld_l		<= '1';
								nxt_oe	<= '0';
								nxt_rd	<= '0';
							else
								hld_l		<= '0';
								nxt_oe	<= '1';
								nxt_rd	<= '1';
								
							end if; 
							
			when s3 =>  cnt_rst <= '1';
			
			when s4 =>  nxt_oe	<= '1';
							nxt_rd	<= '1';
							cnt_rst	<= '1'; 		--crash occurs then reset counter

		
		end case;
	end process output;
	
	
--Process to latch the next signals for usb-------------------------------------------------------
	nxtsignal: process (clk)
	begin
		if (clk'event and clk = '1') then
			oe_l	<= nxt_oe;
			rd_l	<= nxt_rd;
------	wr_l	<= nxt_wr;
------	siwua	<= nxt_siwua;

		end if;		
	end process nxtsignal;
	
--Process to transfer read data to byte_h and byte_l----------------------------------------------
	byte2: process (clk)
	begin
		if (clk'event and clk = '1') then
			if (state = s2) then
				if(hld_l = '1') then 
					byte_h <= d;	
				end if;
				byte_l <= byte_h;
			end if;
			
		end if;
	end process byte2;
	
--Process of address_a counter--------------------------------------------------------------------
	cnt_addra : process (clk)
	begin
			if (clk'event and clk = '1') then
				if (cnt_rst = '1') then 
					nxt_addra <= (others => '0');
				elsif (wea = "1" and state = s2 and rxf_l = '0') then
					
					nxt_addra <= nxt_addra + 1;
					addra <= nxt_addra;
				end if;
				
			end if;
			
	end process cnt_addra;
	
	
--process to set and reset wea--------------------------------------------------------------------
	mywea: process (clk)
	begin
		if (clk'event and clk = '0') then
			if (state = s2) then
				if (rxf_l = '0') then
					--Flip wea
					if (wea(0) = '0') then
						 wea(0) <= '1';
					else
						wea(0) <= '0';
					end if;
				end if;

			end if;
			if (crash = '1') then
				wea(0) <= '0';
			end if;	
		end if;
		
		
	end process mywea;	
	
	
----Process to check one byte or one pair of bytes have been received when rxf_l pulls high--------
--	pair: process (rxf_l)
--	begin
--		if (rxf_l'event and rxf_l = '1') then		
--				--If wea(0) is high, write is enable, then the next byte is the first byte of the pair
--				half <= wea(0);
--		end if;
--		if (rxf_l'event and rxf_l = '0') then
--				half <= '0';
--		end if;
--	end process pair;
	
	
--Hsync counter process--------------------------------------------------------------------------
	counterh_process: process (clkb)
	begin 
		if (clkb = '1' and clkb'event) then
			if (count_h = 799) then		
				count_h <= (others => '0');
				hs_tmp <= '1';
			else 
				
				if (count_h = 47) then		-- Turn on RGB after back porch
					h_on <= "111";
				end if;
				
				if (count_h = 703) then		-- 640 + 48 + 16 = 704 cycles	
					hs_tmp <= '0';
				end if;			
				
				if (count_h = 687) then		-- Turn off RGB before front porch
					h_on <= "000";
				end if;
				count_h <= count_h + 1;
				
			end if;
		end if;
	end process counterh_process;
	
	
--Vsync counter process--------------------------------------------------------------------------
	counterv_process: process (hs_tmp)		--Feed the hs_tmp pulse to the clock of Vsync counter
	begin
		if (hs_tmp = '0' and hs_tmp'event) then
			if (count_v = 524) then		--480 + 10 + 33 +2 = 525 cycles	
				count_v <= (others => '0');
				vs_tmp <= '1';
			else 
				count_v <= count_v + 1; 
				if (count_v = 522) then		-- 480 + 10 + 33 = 523 cycles	
					vs_tmp <= '0';
				end if;
				
			--Drive RGB when h_on is high
	
--						r_tmp <= '0';
--						g_tmp <= '1';
--						b_tmp <= '0';					
		
			--end rgb drving
				
				
			end if;
		end if;
	end process counterv_process;


	
	
end Behavioral;

