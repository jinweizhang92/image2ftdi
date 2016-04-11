----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:33:25 02/09/2016 
-- Design Name: 
-- Module Name:    FPGA_VGA - Behavioral 
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

entity VGA_drv is
    Port ( clk : in 	 STD_LOGIC;
           r 	: out  STD_LOGIC;
           g	: out  STD_LOGIC;
           b 	: out  STD_LOGIC;
           hs	: out  STD_LOGIC;
           vs 	: out  STD_LOGIC);
end VGA_drv;

architecture Behavioral of VGA_drv is

signal count_h	: std_logic_vector(9 downto 0) := "0000000000";
signal count_v	: std_logic_vector(9 downto 0) := "0000000000";
signal hs_tmp	: std_logic := '1';
signal vs_tmp	: std_logic := '1';
signal r_tmp	: std_logic := '0';
signal g_tmp	: std_logic := '0';
signal b_tmp	: std_logic := '0';
signal h_on		: std_logic := '0';

begin
	hs <= hs_tmp;
	vs <= vs_tmp;
	r <= r_tmp and h_on;
	g <= g_tmp and h_on;
	b <= b_tmp and h_on;

--Hsync counter process
	counterh_process: process (clk)
	begin 
		if (clk = '1' and clk'event) then
			if (count_h = 799) then		
				count_h <= (others => '0');
				hs_tmp <= '1';
			else 
			
				count_h <= count_h + 1; 
				
				if (count_h = 47) then		-- Turn on RGB after back porch
					h_on <= '1';
				end if;
				
				if (count_h = 703) then		-- 640 + 48 + 16 = 704 cycles	
					hs_tmp <= '0';
				end if;			
				
				if (count_h = 687) then		-- Turn off RGB before front porch
					h_on <= '0';
				end if;
				
				
			end if;
		end if;
	end process counterh_process;


--Vsync counter process
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

				
					--Drive color to green
					if (count_v = 80)then			
						r_tmp <= '0';
						g_tmp <= '1';
						b_tmp <= '0';
					end if;
					--Drive color to red
					if (count_v = 140)then			
						r_tmp <= '1';
						g_tmp <= '0';
						b_tmp <= '0';
					end if;
					--Drive color to blue				
					if (count_v = 200)then			
						r_tmp <= '0';
						g_tmp <= '0';
						b_tmp <= '1';
					end if;
					if (count_v = 260)then			
						r_tmp <= '1';
						g_tmp <= '1';
						b_tmp <= '0';
					end if;
					if (count_v = 320)then			
						r_tmp <= '1';
						g_tmp <= '0';
						b_tmp <= '1';
					end if;
					if (count_v = 380)then			
						r_tmp <= '0';
						g_tmp <= '1';
						b_tmp <= '1';
					end if;
					if (count_v = 440)then			
						r_tmp <= '1';
						g_tmp <= '1';
						b_tmp <= '1';
					end if;
					if (count_v = 500)then			
						r_tmp <= '0';
						g_tmp <= '0';
						b_tmp <= '0';
					end if;
		
				--end rgb drving
				
				
			end if;
		end if;
	end process counterv_process;




end Behavioral;

