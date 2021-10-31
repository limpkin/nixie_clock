library IEEE;
Library UNISIM;
use UNISIM.vcomponents.all;
use IEEE.STD_LOGIC_1164.ALL;

entity TOP is
    port ( 
            clk_in : in  STD_LOGIC;
            spi_clk_in : in  STD_LOGIC;
            spi_mosi_in : in  STD_LOGIC;
            spi_miso_out : out  STD_LOGIC;
            spi_ncs_in : in  STD_LOGIC;
            nixies : out STD_LOGIC_VECTOR(59 downto 0)
        );
end TOP;

architecture Behavioral of TOP is

component dcm_multiplier 
    port 
    ( 
        CLKIN_IN : in std_logic; 
        CLKFX_OUT : out std_logic 
    ); 
end component; 
 
component pwm is
    generic
    (
        bits_resolution : INTEGER := 14;                                                        -- PWM resolution
        phases          : INTEGER := 60;                                                        -- Number of output pwms and phases
        phase_selwidth  : INTEGER := 6                                                          -- Vector width to select a phase
    );                                                          
    port
    (                 
        CLK_IN        : IN  STD_LOGIC;                                                          -- System clock
        RESET_IN      : IN  STD_LOGIC;                                                          -- Asynchronous reset
        ENA_IN        : IN  STD_LOGIC;                                                          -- Latches in new DUTY_IN cycle
        DUTY_IN       : IN  STD_LOGIC_VECTOR(bits_resolution-1 DOWNTO 0);                       -- DUTY_IN cycle
        CH_SELECT_IN  : IN  STD_LOGIC_VECTOR(phase_selwidth-1 DOWNTO 0);                        -- Channel select
        PWM_OUT       : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0)                                 -- PWM outputs
    );                                 
end component;

component spi_slave is
    port 
    (
        RESET_IN        : in std_logic;                                                         -- Async Reset
        CLK_IN          : in std_logic;                                                         -- System clock
        SPI_CLK         : in std_logic;                                                         -- SPI CLK
        SPI_SS          : in std_logic;                                                         -- SPI Slave Select
        SPI_MOSI        : in std_logic;                                                         -- SPI MOSI
        SPI_MISO        : out std_logic;                                                        -- SPI MISO
        SPI_DONE        : out std_logic;                                                        -- Informing SS went up
        DATA_TO_TX_EN   : in std_logic;                                                         -- Latch to store tx data
        DATA_TO_TX      : in std_logic_vector(23 downto 0);                                     -- tx data
        DATA_RX         : out std_logic_vector(23 downto 0)                                     -- Data received
    );
end component;  

    signal high_frequency_clk : std_logic;
    signal pwm_duty_val_latch : std_logic;
    signal spi_frame_received_latch : std_logic;
    signal spi_frame_received_data : std_logic_vector(23 downto 0);
begin

    -- PWM latch if 2 MSB of first SPI byte are 0 (other commands)
    pwm_duty_val_latch <= spi_frame_received_latch and not spi_frame_received_data(23) and not spi_frame_received_data(22);
     
   C0 : dcm_multiplier
        port map 
        (
            CLKFX_OUT => high_frequency_clk,
            CLKIN_IN => clk_in 
        );
                
    C1 : pwm
        port map
        ( 
            RESET_IN => '1', 
            CLK_IN => high_frequency_clk,
            ENA_IN => pwm_duty_val_latch,
            DUTY_IN => spi_frame_received_data(13 downto 0),
            CH_SELECT_IN => spi_frame_received_data(21 downto 16),
            PWM_OUT => nixies
        );
       
    -- SPI slave: loopback
    C2 : spi_slave
        port map
        ( 
          RESET_IN        => '1',
          CLK_IN          => high_frequency_clk,
          SPI_CLK         => spi_clk_in,
          SPI_SS          => spi_ncs_in,
          SPI_MOSI        => spi_mosi_in,
          SPI_MISO        => spi_miso_out,
          SPI_DONE        => spi_frame_received_latch,
          DATA_TO_TX_EN   => spi_frame_received_latch,
          DATA_TO_TX      => spi_frame_received_data,
          DATA_RX         => spi_frame_received_data
        );  
end Behavioral;

