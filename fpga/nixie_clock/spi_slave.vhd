LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

entity spi_slave is
    port (
        RESET_IN        : in std_logic;
        CLK_IN          : in std_logic;
        SPI_CLK         : in std_logic;
        SPI_SS          : in std_logic;
        SPI_MOSI        : in std_logic;
        SPI_MISO        : out std_logic;
        SPI_DONE        : out std_logic;
        DATA_TO_TX_EN   : in std_logic;
        DATA_TO_TX      : in std_logic_vector(23 downto 0);
        DATA_RX         : out std_logic_vector(23 downto 0)
    );
end spi_slave;

architecture Behavioral of spi_slave is
    signal SCLK_latched, SCLK_old : std_logic;
    signal SS_latched, SS_old : std_logic;
    signal MOSI_latched: std_logic;
    signal TxData : std_logic_vector(23 downto 0);
    signal RxdData : std_logic_vector(23 downto 0);
begin
--
-- Sync process
--
    process(CLK_IN, RESET_IN)
        begin
            if (RESET_IN = '0') then
                RxdData <= (OTHERS => '0');
                TxData <= (OTHERS => '0');
                SCLK_old <= '0';
                SCLK_latched <= '0';
                SS_old <= '0';
                SS_latched <= '0';
                SPI_DONE <= '0';
                MOSI_latched <= '0';
            elsif (CLK_IN'EVENT AND CLK_IN = '1') THEN
                SCLK_latched <= SPI_CLK;
                SCLK_old <= SCLK_latched;
                SS_latched <= SPI_SS;
                SS_old <= SS_latched;
                MOSI_latched <= SPI_MOSI;
                SPI_done <= '0';

                -- Latching data to tx
                if(DATA_TO_TX_EN = '1') then
                    TxData <= DATA_TO_TX;
                end if;

                -- SPI done signal when SS goes from low to high
                if (SS_old = '0' and SS_latched = '1') then
                    SPI_DONE <= '1';
                end if;

                -- Data RX/TX logic
                if(SS_latched = '0') then
                    -- CLK LO to HI transition, sample data
                    if(SCLK_old = '0' and SCLK_latched = '1') then
                        RxdData <= RxdData(22 downto 0) & MOSI_latched;
                    -- CLK HI to LO transition, put data on the bus
                    elsif(SCLK_old = '1' and SCLK_latched = '0') then
                        TxData <= TxData(22 downto 0) & '1';
                    end if;
                end if;
            end if;
    end process;
    SPI_MISO <= TxData(23);
    DATA_RX <= RxdData;
end Behavioral;