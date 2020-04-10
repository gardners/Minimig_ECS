library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

entity Fampiga is
port(
		clk 	: in std_logic;
		clk7m : in std_logic;
		clk28m : in std_logic;
		reset_n : in std_logic;
		powerled_out : out unsigned (1 downto 0);
		diskled_out : out std_logic;	-- Use for SD access
		oddled_out : out std_logic; -- Use for floppy access

		-- SRAM
		ram_data		   : out std_logic_vector(15 downto 0); -- sram data bus
		ramdata_in		: in std_logic_vector(15 downto 0);  -- sram data bus in    
		ram_address		: out std_logic_vector(21 downto 1); -- sram address bus
		n_ram_ce		   : out std_logic_vector(3 downto 0);  -- sram chip enable
		n_ram_bhe		: out std_logic;                     -- sram upper byte select
		n_ram_ble		: out std_logic;                     -- sram lower byte select
		n_ram_we		   : out std_logic;                     -- sram write enable
		n_ram_oe		   : out std_logic;                     -- sram output enable      
      		
		-- Game ports
		n_joy1         : in std_logic_vector(5 downto 0);
		n_joy2         : in std_logic_vector(5 downto 0);
	
		-- VGA
		vga_r		: out std_logic_vector(3 downto 0);
		vga_g 	: out std_logic_vector(3 downto 0);
		vga_b 	: out std_logic_vector(3 downto 0);
		vid_blank 	: out std_logic;
		vga_hsync 	: out std_logic;
		vga_vsync 	: out std_logic;
		n_15khz 	: in std_logic;
 
		-- PS/2
		ps2k_clk_in : inout std_logic;
		ps2k_clk_out : inout std_logic;
		ps2k_dat_in : inout std_logic;
		ps2k_dat_out : inout std_logic;
		ps2m_clk_in : inout std_logic;
		ps2m_clk_out : inout std_logic;
		ps2m_dat_in : inout std_logic;
		ps2m_dat_out : inout std_logic;
		
		-- Audio
		sigmaL : out std_logic;
		sigmaR : out std_logic;
		leftdatasum : out std_logic_vector(14 downto 0);
		rightdatasum : out std_logic_vector(14 downto 0);
		
		-- RS232
		rs232_rxd : in std_logic;
		rs232_txd : out std_logic;
		
		-- ESP8266 wifi modem
		-- amiga_rs232_rxd : in std_logic;
		-- amiga_rs232_txd : out std_logic;

		-- SD card interface
		sd_cs : out std_logic; 
		sd_miso : in std_logic;
		sd_mosi : out std_logic;
		sd_clk : out std_logic;

      led : out std_logic_vector(15 downto 0)

		-- FIXME - add joystick ports
	);
end entity;


architecture RTL of Fampiga is

		-- CPU
signal cpu_address : std_logic_vector(31 downto 0);
signal cpu_data_in : std_logic_vector(15 downto 0);
signal cpu_data_out : std_logic_vector(15 downto 0);
signal cpu_data_from_ram : std_logic_vector(15 downto 0);
signal n_cpu_ipl : std_logic_vector(2 downto 0);
signal n_cpu_as : std_logic;
signal n_cpu_uds : std_logic;
signal n_cpu_lds : std_logic;
signal cpu_r_w : std_logic;
signal n_cpu_dtack : std_logic;
signal n_cpu_reset : std_logic;
 
		-- Config

signal cpu_config : std_logic_vector(1 downto 0);
signal mem_config : std_logic_vector(5 downto 0);
signal cpu_ena : std_logic;

		-- TG68 signals
signal wrd : std_logic;
signal ena7RDreg : std_logic;
signal ena7WRreg : std_logic;
signal enaWRreg : std_logic;
signal enaRDreg : std_logic;
        
signal cpu_ramaddr : std_logic_vector(31 downto 0);
signal cpustate : std_logic_vector(5 downto 0);

signal maincpuready : std_logic;
signal cpu_dma : std_logic;
signal cpu_ram_lds : std_logic;
signal cpu_ram_uds : std_logic;

-- OSD CPU signals
signal scandoubler : std_logic;
signal hostWR : std_logic_vector(15 downto 0);
signal hostAddr : std_logic_vector(23 downto 0);
signal hostState : std_logic_vector(2 downto 0);
signal hostL : std_logic;
signal hostU : std_logic;
signal hostRD : std_logic_vector(15 downto 0);
signal hostena	: std_logic;
signal hostena_in	: std_logic;
signal hostdata : std_logic_vector(15 downto 0);

signal dummy1 : std_logic_vector(2 downto 0);
signal dummy2 : std_logic_vector(7 downto 0);

COMPONENT Minimig1
	GENERIC ( NTSC : integer := 0 );
	PORT
	(
		cpu_address		:	 IN STD_LOGIC_VECTOR(23 DOWNTO 1);
		cpu_data		   :	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		cpu_wrdata		:	 IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		n_cpu_ipl		:	 OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		n_cpu_as		   :	 IN STD_LOGIC;
		n_cpu_uds		:	 IN STD_LOGIC;
		n_cpu_lds		:	 IN STD_LOGIC;
		cpu_r_w		   :	 IN STD_LOGIC;
		n_cpu_dtack		:	 OUT STD_LOGIC;
		n_cpu_reset		:	 OUT STD_LOGIC;
      
      --SRAM
		ram_data		   :	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- sram data bus
		ramdata_in		:	 IN STD_LOGIC_VECTOR(15 DOWNTO 0);  -- sram data bus in    
		ram_address		:	 OUT STD_LOGIC_VECTOR(21 DOWNTO 1); -- sram address bus
		n_ram_ce		   :	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);  -- sram chip enable
		n_ram_bhe		:	 OUT STD_LOGIC;                     -- sram upper byte select
		n_ram_ble		:	 OUT STD_LOGIC;                     -- sram lower byte select
		n_ram_we		   :	 OUT STD_LOGIC;                     -- sram write enable
		n_ram_oe		   :	 OUT STD_LOGIC;                     -- sram output enable      
      
		clk		      :	 IN STD_LOGIC;
		clk28m		   :	 IN STD_LOGIC;
		rxd		      :	 IN STD_LOGIC;
		txd		      :	 OUT STD_LOGIC;
		cts		      :	 IN STD_LOGIC;
		rts		      :	 OUT STD_LOGIC;
		n_joy1		   :	 IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		n_joy2		   :	 IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		n_15khz		   :	 IN STD_LOGIC;
		pwrled		   :	 OUT STD_LOGIC;
		kbddat		   :	 IN STD_LOGIC;
		kbdclk		   :	 IN STD_LOGIC;
		msdat		      :	 IN STD_LOGIC;
		msclk		      :	 IN STD_LOGIC;
		msdato		   :	 OUT STD_LOGIC;
		msclko		   :	 OUT STD_LOGIC;
		kbddato		   :	 OUT STD_LOGIC;
		kbdclko		   :	 OUT STD_LOGIC;
		n_scs		      :	 IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		direct_sdi		:	 IN STD_LOGIC;
		sdi		      :	 IN STD_LOGIC;
		sdo		      :	 INOUT STD_LOGIC;
		sck		      :	 IN STD_LOGIC;
		n_hsync		   :	 OUT STD_LOGIC;
		n_vsync		   :	 OUT STD_LOGIC;
		video_blank		:	 OUT STD_LOGIC;
		red		      :	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		green		      :	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		blue		      :	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		leftdatasum		:	 OUT STD_LOGIC_VECTOR(14 DOWNTO 0);
		rightdatasum	:	 OUT STD_LOGIC_VECTOR(14 DOWNTO 0);
		left           :   OUT STD_LOGIC;
		right          :   OUT STD_LOGIC;
		cpu_config		:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		memcfg		   :	 OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
		drv_snd		   :	 OUT STD_LOGIC;
		floppyled		:	 OUT STD_LOGIC; 
		init_b		   :	 OUT STD_LOGIC;
		cpurst		   :	 IN STD_LOGIC;
		locked		   :	 IN STD_LOGIC;      
		sysclock		   :	 IN STD_LOGIC;
		ascancode		:	 IN STD_LOGIC_VECTOR(8 DOWNTO 0);
		n_joy3		   :	 IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		n_joy4		   :	 IN STD_LOGIC_VECTOR(5 DOWNTO 0)
	);
END COMPONENT;

-- Peripherals

signal spi_chipselect : std_logic_vector(7 downto 0);	
signal spi_sdi : std_logic;
signal spi_sdo : std_logic;
signal spi_sck : std_logic;
signal sysreset : std_logic;
signal clk_enablez : std_logic;
signal ramm_address : std_logic_vector(23 downto 1);
-- Misc

signal fastramcfg : std_logic_vector(2 downto 0);
signal turbochipram : std_logic;

signal powerled : std_logic;
signal sdled : std_logic;
signal floppyled : std_logic;
signal cpu_reset1 : std_logic;
 
begin
	powerled_out<=powerled & '1';
--	oddled_out<=floppyled;
	diskled_out<=spi_chipselect(1);

	sd_clk <= spi_sck;
	sd_cs <= spi_chipselect(1);
	sd_mosi <= spi_sdi;

	
MyMinimig: COMPONENT Minimig1
	generic map
	(
		NTSC => 0 
	)
	port map
	(
		-- CPU signals
		cpu_address => cpu_address(23 downto 1),
		cpu_data	=> cpu_data_in,
		cpu_wrdata => cpu_data_out,
		n_cpu_ipl => n_cpu_ipl,
		n_cpu_as => n_cpu_as,
		n_cpu_uds => n_cpu_uds,
		n_cpu_lds	=> n_cpu_lds,
		cpu_r_w => cpu_r_w,
		n_cpu_dtack => n_cpu_dtack,
		n_cpu_reset => n_cpu_reset,
		
		-- SRAM
		
		ram_data	   => ram_data,
		ramdata_in  => ramdata_in,      
		ram_address => ram_address,
		n_ram_ce	   => n_ram_ce,
		n_ram_bhe   => n_ram_bhe,
		n_ram_ble	=> n_ram_ble,
		n_ram_we    => n_ram_we,
		n_ram_oe    => n_ram_oe,      
      		
		-- Clocks
		
		clk => clk7m, -- 113Mhz
		clk28m => clk28m, -- 28Mhz
		
		-- Peripherals
		
		rxd => rs232_rxd,
		txd => rs232_txd,
		--rxd => '1',
		--txd => open,
		cts => '0',
		rts => open,
		n_joy1	=> n_joy1,
		n_joy2 => n_joy2,
		n_15khz => n_15khz,
		pwrled => powerled,
		kbddat => ps2k_dat_in,
		kbdclk => ps2k_clk_in,
		msdat => ps2m_dat_in,
		msclk => ps2m_clk_in,
		msdato => ps2m_dat_out,
		msclko => ps2m_clk_out,
		kbddato => ps2k_dat_out,
		kbdclko => ps2k_clk_out,
		n_scs => spi_chipselect(6 downto 4),
		direct_sdi => sd_miso,
		sdi => spi_sdi,
		sdo => spi_sdo,
		sck => spi_sck,
		
		-- Video
		
		n_hsync => vga_hsync,
		n_vsync => vga_vsync,
		video_blank => vid_blank,
		red => vga_r,
		green => vga_g,
		blue => vga_b, 
		
		-- Audio
		 left => sigmaL,
		 right => sigmaR,		
		leftdatasum => leftdatasum,
		rightdatasum => rightdatasum,
		
		cpu_config => cpu_config,
		memcfg => mem_config, 
		drv_snd => open,
		floppyled => oddled_out,
		init_b => open,
		cpurst => cpu_reset1,
      locked => '1',      
		sysclock => clk,
		ascancode => "100000000",
		n_joy3 => "111111",
		n_joy4	=> "111111"
	);
	
   led(0) <= n_cpu_reset;
   led(1) <= maincpuready;
   led(2) <= cpu_reset1;
   led(3) <= sysreset;
   led(15 downto 4) <= (others => '0');
   
	cpu_reset1 <= not (maincpuready and n_cpu_reset and reset_n);
	sysreset <= n_cpu_reset;
	 
MainCPU: entity work.TG68K
   port map
	(        
		clk => clk,
		reset => sysreset,
		clkena_in => '1',
		  
	  -- Standard MC68000 signals...
		  
		IPL => n_cpu_ipl,
		dtack => n_cpu_dtack,

		vpa => '1',
		ein => '1',
		 
		addr => cpu_address,
		data_read => cpu_data_in,
		data_write => cpu_data_out,
		as => n_cpu_as,
		uds => n_cpu_uds,
		lds => n_cpu_lds,
		rw => cpu_r_w,
		--e => open,
		--vma => open,

		  -- TG68 specific signals...
		  
      wrd => wrd,
      ena7RDreg => ena7RDreg,
      ena7WRreg => ena7WRreg,
      enaWRreg => enaWRreg,
       
      fromram => cpu_data_from_ram,
      ramready => cpu_ena,	-- dtack equivalent for fastram access 
      cpu => cpu_config,
	  fastramcfg => fastramcfg,
	  turbochipram => turbochipram,
      ramaddr => cpu_ramaddr,
      cpustate => cpustate,

		nResetOut => maincpuready,
      --skipFetch => open,
      cpuDMA => cpu_dma,
      ramlds => cpu_ram_lds,
      ramuds => cpu_ram_uds
	);

 

	
mycfide : entity work.cfide 
   port map ( 
		sysclk => clk,
		n_reset => reset_n,
		cpuena_in => hostena_in,
		memdata_in => hostRD,
		addr => hostaddr,
		cpudata_in => hostWR,
		state => hostState(1 downto 0),
		lds => hostL,
		uds => hostU,
		sd_di => spi_sdo,
		 
		fastramsize => fastramcfg,
		turbochipram => turbochipram,
		scandoubler => scandoubler, 
		memce => hostState(2),
		cpudata => hostdata,
		cpuena => hostena,	-- And with enaWRreg as host clkena_in
		sd_cs => spi_chipselect,
		sd_clk => spi_sck,
		sd_do => spi_sdi,
		sd_dimm => sd_miso,
		enaWRreg => enaWRreg,
		debugTxD => open,
		debugRxD => '1'
   );
   
clk_enablez <= hostena and enaWRreg;
myhostcpu : entity work.TG68KdotC_Kernel
   port map(clk => clk,
		nReset => reset_n,
		clkena_in => clk_enablez,
		data_in => hostdata,
		addr(23 downto 0) => hostaddr, 
		addr(31 downto 24) => dummy2,
		data_write => hostWR,
		nWr => open, -- uses busstate instead?
		nUDS => hostU,
		nLDS => hostL,
		busstate	=> hostState(1 downto 0)
		--nResetOut => open,
		--FC => open,
-- for debug		
		--skipFetch => open,
		--regin => open
	);
   	
end rtl;
