library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

entity container is
  port(
    CLK_IN : in std_logic;

    btnCpuReset : in std_logic;
    
		-- VGA
		vgared		: out std_logic_vector(7 downto 0);
		vgagreen 	: out std_logic_vector(7 downto 0);
		vgablue 	: out std_logic_vector(7 downto 0);
		hsync 	: buffer std_logic;
		vsync 	: buffer std_logic;
                vdac_clk : out std_logic;
                vdac_sync_n : out std_logic;
                vdac_blank_n : out std_logic;
                
		-- Audio
		pwm_l : out std_logic;
		pwm_r : out std_logic;
		
		-- RS232
		RsRx : in std_logic;
		UART_TXD : out std_logic;

		-- SD card interface
		sdReset : out std_logic;
		sdMISO : in std_logic;
		sdMOSI : out std_logic;
		sdClock : out std_logic

		-- FIXME - add joystick ports
	);
end entity;


architecture RTL of container is

  signal clk7m : std_logic;
  signal clk28m : std_logic;
  signal powerled_out :  unsigned (1 downto 0);
  signal diskled_out : std_logic;	-- Use for SD access
  signal oddled_out : std_logic; -- Use for floppy access

  
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

		-- SDRAM
		
signal mm_ram_data_out : std_logic_vector(15 downto 0);
signal mm_ram_data_in : std_logic_vector(15 downto 0);
signal mm_ram_address : std_logic_vector(21 downto 1);
signal mm_ram_bhe : std_logic;
signal mm_ram_ble : std_logic;
signal mm_ram_we : std_logic;
signal mm_ram_oe : std_logic;

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

signal hostWR : std_logic_vector(15 downto 0);
signal hostAddr : std_logic_vector(23 downto 0);
signal hostState : std_logic_vector(2 downto 0);
signal hostL : std_logic;
signal hostU : std_logic;
signal hostRD : std_logic_vector(15 downto 0);
signal hostena	: std_logic;
signal hostena_in	: std_logic;
signal hostdata : std_logic_vector(15 downto 0);

COMPONENT Minimig1
	GENERIC ( NTSC : integer := 0 );
	PORT
	(
		cpu_address		:	 IN STD_LOGIC_VECTOR(23 DOWNTO 1);
		cpu_data		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		cpu_wrdata		:	 IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		n_cpu_ipl		:	 OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		n_cpu_as		:	 IN STD_LOGIC;
		n_cpu_uds		:	 IN STD_LOGIC;
		n_cpu_lds		:	 IN STD_LOGIC;
		cpu_r_w		:	 IN STD_LOGIC;
		n_cpu_dtack		:	 OUT STD_LOGIC;
		n_cpu_reset		:	 OUT STD_LOGIC;
		ram_data		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		ram_address		:	 OUT STD_LOGIC_VECTOR(21 DOWNTO 1);
		n_ram_ce		:	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		n_ram_bhe		:	 OUT STD_LOGIC;
		n_ram_ble		:	 OUT STD_LOGIC;
		n_ram_we		:	 OUT STD_LOGIC;
		n_ram_oe		:	 OUT STD_LOGIC;
		clk		:	 IN STD_LOGIC;
		clk28m		:	 IN STD_LOGIC;
		rxd		:	 IN STD_LOGIC;
		txd		:	 OUT STD_LOGIC;
		cts		:	 IN STD_LOGIC;
		rts		:	 OUT STD_LOGIC;
		n_joy1		:	 IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		n_joy2		:	 IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		n_15khz		:	 IN STD_LOGIC;
		pwrled		:	 OUT STD_LOGIC;
		kbddat		:	 IN STD_LOGIC;
		kbdclk		:	 IN STD_LOGIC;
		msdat		:	 IN STD_LOGIC;
		msclk		:	 IN STD_LOGIC;
		msdato		:	 OUT STD_LOGIC;
		msclko		:	 OUT STD_LOGIC;
		kbddato		:	 OUT STD_LOGIC;
		kbdclko		:	 OUT STD_LOGIC;
		n_scs		:	 IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		direct_sdi		:	 IN STD_LOGIC;
		sdi		:	 IN STD_LOGIC;
		sdo		:	 INOUT STD_LOGIC;
		sck		:	 IN STD_LOGIC;
		n_hsync		:	 OUT STD_LOGIC;
		n_vsync		:	 OUT STD_LOGIC;
		red		:	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		green		:	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		blue		:	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		aud_l		:	 OUT STD_LOGIC;
		aud_r		:	 OUT STD_LOGIC;
		cpu_config		:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		memcfg		:	 OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
		drv_snd		:	 OUT STD_LOGIC;
		floppyled		:	 OUT STD_LOGIC;
		init_b		:	 OUT STD_LOGIC;
		ramdata_in		:	 IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		cpurst		:	 IN STD_LOGIC;
		locked		:	 IN STD_LOGIC;
		sysclock		:	 IN STD_LOGIC;
		ascancode		:	 IN STD_LOGIC_VECTOR(8 DOWNTO 0);
		n_joy3		:	 IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		n_joy4		:	 IN STD_LOGIC_VECTOR(5 DOWNTO 0)
	);
END COMPONENT;

-- Peripherals

signal spi_chipselect : std_logic_vector(7 downto 0);	
signal spi_sdi : std_logic;
signal spi_sdo : std_logic;
signal spi_sck : std_logic;

-- Misc

signal powerled : std_logic;
signal sdled : std_logic;
signal floppyled : std_logic;

begin
	powerled_out<=powerled & '1';
--	oddled_out<=floppyled;
	diskled_out<=spi_chipselect(1);

	sdClock <= spi_sck;
	sdReset <= spi_chipselect(1);
	sdMOSI <= spi_sdi;

        vdac_blank_n <= '1';
        vdac_sync_n <= '1';
        vdac_clk <= clk28m;
        
	
MyMinimig: component Minimig1
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
		
		-- SDRAM
		
		ram_data	=> mm_ram_data_out,
		ram_address => mm_ram_address,
		n_ram_ce	=> open, -- mm_ram_ce,
		n_ram_bhe => mm_ram_bhe,
		n_ram_ble	=> mm_ram_ble,
		n_ram_we => mm_ram_we,
		n_ram_oe => mm_ram_oe,
		
		-- Clocks
		
		clk => clk7m,
		clk28m => clk28m, -- 28Mhz
		
		-- Peripherals                
                
--		txd => UART_TXD,
--		rxd => RsRx,
		txd => open,
		rxd => '1',
		cts => '0',
		rts => open,
		n_joy1	=> "111111",
		n_joy2 => "111111",
		n_15khz => '1',
		pwrled => powerled,
		kbddat => '1',
		kbdclk => '1',
		msdat => '1',
		msclk => '1',
--		msdato => ps2m_dat_out,
--		msclko => ps2m_clk_out,
--		kbddato => ps2k_dat_out,
--		kbdclko => ps2k_clk_out,
		n_scs => spi_chipselect(6 downto 4),
		direct_sdi => sdMISO,
		sdi => spi_sdi,
		sdo => spi_sdo,
		sck => spi_sck,
		
		-- Video
		
		n_hsync => hsync,
		n_vsync => vsync,
		red => vgared(7 downto 4),
		green => vgagreen(7 downto 4),
		blue => vgablueb(7 downto 4),
		
		aud_l => pwm_l,
		aud_r => pwm_r,
		cpu_config => cpu_config,
		memcfg => mem_config,
		drv_snd => open,
		floppyled => oddled_out,
		init_b => open,
		ramdata_in => mm_ram_data_in,
		cpurst => not (maincpuready and btnCpuReset),
		locked => btnCpuReset,
		sysclock => clk,
		ascancode => "100000000",
		n_joy3 => "111111",
		n_joy4	=> "111111"
	);
		
MainCPU: entity work.TG68K
   port map
	(        
		clk => clk7m,
		reset => n_cpu_reset and btnCpuReset,
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
		e => open,
		vma => open,

		  -- TG68 specific signals...
		  
      wrd => wrd,
      ena7RDreg => ena7RDreg,
      ena7WRreg => ena7WRreg,
      enaWRreg => enaWRreg,
       
      fromram => cpu_data_from_ram,
      ramready => cpu_ena,	-- dtack equivalent for fastram access 
      cpu => cpu_config,
      memcfg => mem_config,
      ramaddr => cpu_ramaddr,
      cpustate => cpustate,

		nResetOut => maincpuready,
      skipFetch => open,
      cpuDMA => cpu_dma,
      ramlds => cpu_ram_lds,
      ramuds => cpu_ram_uds
	);

mycfide : entity work.cfide 
  port map (
    -- XXX PGS I *think* this should be 28MHz, but it isn't clear
		sysclk => clk28m,
		n_reset => btnCpuReset,
		cpuena_in => hostena_in,
		memdata_in => hostRD,
		addr => hostaddr,
		cpudata_in => hostWR,
		state => hostState(1 downto 0),
		lds => hostL,
		uds => hostU,
		sd_di => spi_sdo,
		
		memce => hostState(2),
		cpudata => hostdata,
		cpuena => hostena,	-- And with enaWRreg as host clkena_in
		sd_cs => spi_chipselect,
		sd_clk => spi_sck,
		sd_do => spi_sdi,
		sd_dimm => sdMiso,
		enaWRreg => enaWRreg,
		debugTxD => UART_TXD,
		debugRxD => RsRx
   );

myhostcpu : entity work.TG68KdotC_Kernel
  port map(
-- XXX PGS Likewise, I don't know what speed this clock is actually supposed to
-- be
    clk => clk7m,
		nReset => btnCpuReset,
		clkena_in => hostena and enaWRreg,
		data_in => hostdata,
		addr(23 downto 0) => hostaddr,
		addr(31 downto 24) => open,
		data_write => hostWR,
		nWr => open, -- uses busstate instead?
		nUDS => hostU,
		nLDS => hostL,
		busstate	=> hostState(1 downto 0),
		nResetOut => open,
		FC => open,
-- for debug		
		skipFetch => open,
		regin => open
	);
	
end rtl;
