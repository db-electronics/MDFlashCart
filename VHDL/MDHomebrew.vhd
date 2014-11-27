--*************************************************************
--
--  $Rev:: 305                                            $:  Revision of last commit
--  $Author:: reneleonrichard                             $:  Author of last commit
--  $Date:: 2014-10-09 20:11:27 -0400 (Thu, 09 Oct 2014)  $:  Date of last commit
--  $HeadURL: https://subversion.assembla.com/svn/db_repository/trunk/FPGAProjects/SMSCart/src/SMSCart.vhd $
--
--*************************************************************
--  db MD Mapper
--  Copyright 2014 Rene Richard
--  DEVICE : EPM3064ATC100-10
--*************************************************************
--  db MD Mapper supports a face-melting 256 MEGA POWER
--*************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

library altera; 
use altera.altera_primitives_components.all;

entity MDHomebrew is 
	generic ( 
			MAPPER_SIZE_g	: integer := 6
	);
	port (
			--input from Genesis
			ADDRLO_p		:	in		std_logic_vector(2 downto 0); --Address 3,2,1
			ADDRHI_p		:	in		std_logic_vector(2 downto 0); --Address 21,20,19
			DATA_p		:	in 	std_logic_vector(MAPPER_SIZE_g-1 downto 0);
			nRST_p		:	in 	std_logic;
			nTIME_p		:	in		std_logic;
			nCE_p			:	in		std_logic;
			nLWR_p		:	in		std_logic;
			nUWR_p		:	in		std_logic;
			nOE_p			:	in		std_logic;
			
			--output to ROM
			DIR_p				:	out	std_logic;
			nROMCE_p			: 	out	std_logic;
			--ROM A19 and up
			ROMADDR_p		: 	out	std_logic_vector(MAPPER_SIZE_g-1 downto 0);
			
			--output to SRAM
			nSRAMCE_p		:	out	std_logic;
			SRAMWE_p			: 	out	std_logic;
			nLBS_p			:	out	std_logic;
			nUBS_p			:	out	std_logic
	);
end entity; 

architecture MDHomebrew_a of MDHomebrew is
	
	--Mapper slot registers, fitter will optimize any unused bits
	signal romSlot1_s		:	std_logic_vector(MAPPER_SIZE_g-1 downto 0);
	signal romSlot2_s		:	std_logic_vector(MAPPER_SIZE_g-1 downto 0);
	signal romSlot3_s		:	std_logic_vector(MAPPER_SIZE_g-1 downto 0);
	signal romSlot4_s		:	std_logic_vector(MAPPER_SIZE_g-1 downto 0);
	signal romSlot5_s		:	std_logic_vector(MAPPER_SIZE_g-1 downto 0);
	signal romSlot6_s		:	std_logic_vector(MAPPER_SIZE_g-1 downto 0);
	signal romSlot7_s		:	std_logic_vector(MAPPER_SIZE_g-1 downto 0);
	
	signal ramEn_s			:	std_logic;
	
begin
	
	--what little level conversion I can do is handled here
	SRAMWE_p <= '1' when (nLWR_p = '0' or nUWR_p = '0') else '0';
	nLBS_p <= '0' when (nLWR_p = '0' or nOE_p = '0') else '1';
	nUBS_p <= '0' when (nUWR_p = '0' or nOE_p = '0') else '1';
	
	DIR_p <= '1' when (nOE_p = '0' and nCE_p = '0') else '0';
	
	--drive CE depending on ramEn_s
	--RAM, when enabled, appears at 0x200000
	chipselects: process ( ADDRHI_p, nCE_p, ramEn_s)
	begin
		case ADDRHI_p(2) is --Address 21
			when '0' =>
				nSRAMCE_p <= '1';
				nROMCE_p <= nCE_p;
			when '1' =>
				if ramEn_s = '1' then
					nSRAMCE_p <= nCE_p;
					nROMCE_p <= '1';
				else
					nSRAMCE_p <= '1';
					nROMCE_p <= nCE_p;
				end if;
		end case;
	end process;
	
	--mapper registers
	mappers: process( nRST_p, nTIME_p, ADDRLO_p)
	begin
		if nRST_p = '0' then
			ramEn_s <= '0';
			romSlot1_s <= std_logic_vector(to_unsigned(1, romSlot1_s'length));
			romSlot2_s <= std_logic_vector(to_unsigned(2, romSlot2_s'length));
			romSlot3_s <= std_logic_vector(to_unsigned(3, romSlot3_s'length));
			romSlot4_s <= std_logic_vector(to_unsigned(4, romSlot4_s'length));
			romSlot5_s <= std_logic_vector(to_unsigned(5, romSlot5_s'length));
			romSlot6_s <= std_logic_vector(to_unsigned(6, romSlot6_s'length));
			romSlot3_s <= std_logic_vector(to_unsigned(7, romSlot7_s'length));
		elsif rising_edge(nTIME_p) then
			--no address(0) from genesis, but I append it here for clarity
			case (ADDRLO_p & '1') is
				when x"1" =>
					ramEn_s <= DATA_p(0);
				when x"3" => 
					romSlot1_s <= DATA_p;
				when x"5" =>
					romSlot2_s <= DATA_p;
				when x"7" =>
					romSlot3_s <= DATA_p;
				when x"9" =>
					romSlot4_s <= DATA_p;
				when x"B" =>
					romSlot5_s <= DATA_p;
				when x"D" =>
					romSlot6_s <= DATA_p;
				when x"F" =>
					romSlot7_s <= DATA_p;
				when others =>
					null;
			end case;
		end if;
	end process;

	--banking select
	--only looks at address, this way the address setup and hold times can be respected
	banking: process( ADDRHI_p )
	begin
		ROMADDR_p <= (others=>'0');
		if ramEn_s = '0' then
			case ADDRHI_p is --address 21,20 and 19
				when "000" =>
					-- first bank is always from lowest 512K of ROM 
					ROMADDR_p <= (others=>'0');
				when "001" =>
					ROMADDR_p <= romSlot1_s;
				when "010" =>
					ROMADDR_p <= romSlot2_s;
				when "011" =>
					ROMADDR_p <= romSlot3_s;
				when "100" =>
					ROMADDR_p <= romSlot4_s;
				when "101" =>
					ROMADDR_p <= romSlot5_s;
				when "110" =>
					ROMADDR_p <= romSlot6_s;
				when "111" =>
					ROMADDR_p <= romSlot7_s;
				when others =>
					ROMADDR_p <= (others=>'0');
			end case;
		end if;
	end process;
	
end MDHomebrew_a;