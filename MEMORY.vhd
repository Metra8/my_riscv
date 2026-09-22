library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is

	generic(
	
		MEM_WIDTH: integer := 32;
		NUM_BYTES: integer := 4;
		ADDR_WIDTH: integer := 17
		
		);
		
	port(
	
		clk: in std_logic;
		addr_ins: in std_logic_vector(ADDR_WIDTH-1 downto 0);
		wdata_ins: in std_logic_vector(MEM_WIDTH -1 downto 0);
		rdata_ins: out std_logic_vector(MEM_WIDTH -1 downto 0);
		we_ins: in std_logic;
		be_ins: in std_logic_vector(NUM_BYTES-1 downto 0);
		addr_dat: in std_logic_vector(ADDR_WIDTH-1 downto 0);
		wdata_dat: in std_logic_vector(MEM_WIDTH-1 downto 0);
		rdata_dat: out std_logic_vector(MEM_WIDTH-1 downto 0);
		we_dat: in std_logic;
		be_dat: in std_logic_vector(NUM_BYTES-1 downto 0)
		
		);
		
end memory;




architecture storage of memory is

	type mem_t is array(0 to 2**ADDR_WIDTH-1) of std_logic_vector(MEM_WIDTH-1 downto 0);
	shared variable mem: mem_t;


begin


instruction:	process(clk)
		begin

			
			if rising_edge(clk) then

				rdata_ins <= mem(to_integer(unsigned(addr_ins)));

				if we_ins = '1' then 

					if be_ins(0) = '1' then

						mem(to_integer(unsigned(addr_ins)))(7 downto 0) := wdata_ins(7 downto 0);

					end if;



					if be_ins(1) = '1' then

						mem(to_integer(unsigned(addr_ins)))(15 downto 8) := wdata_ins(15 downto 8);

					end if;



					if be_ins(2) = '1' then

						mem(to_integer(unsigned(addr_ins)))(23 downto 16) := wdata_ins(23 downto 16);

					end if;



					if be_ins(3) = '1' then

						mem(to_integer(unsigned(addr_ins)))(31 downto 24) := wdata_ins(31 downto 24);

					end if;

				end if;

			end if;

		end process;

data:		process(clk)
		begin

			
			if rising_edge(clk) then

				rdata_dat <= mem(to_integer(unsigned(addr_dat)));

				if we_dat = '1' then

					if be_dat(0) = '1' then

						mem(to_integer(unsigned(addr_dat)))(7 downto 0) := wdata_dat(7 downto 0);

					end if;



					if be_dat(1) = '1' then

						mem(to_integer(unsigned(addr_dat)))(15 downto 8) := wdata_dat(15 downto 8);

					end if;



					if be_dat(2) = '1' then

						mem(to_integer(unsigned(addr_dat)))(23 downto 16) := wdata_dat(23 downto 16);

					end if;



					if be_dat(3) = '1' then

						mem(to_integer(unsigned(addr_dat)))(31 downto 24) := wdata_dat(31 downto 24);

					end if;

				end if;

			end if;

		end process;



end storage;
