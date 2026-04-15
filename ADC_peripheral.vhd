LIBRARY IEEE;
LIBRARY LPM;

USE lpm.lpm_components.ALL;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-- adc peripheral for scomp
entity ADC_peripheral is
    port (
        clk       : in    std_logic;
        nrst      : in    std_logic;
        io_addr   : in    std_logic_vector(10 downto 0);
        io_write  : in    std_logic;
        io_read   : in    std_logic;
        io_data   : inout std_logic_vector(15 downto 0);
        miso      : in    std_logic;
        sclk      : out   std_logic;
        conv      : out   std_logic;
        mosi      : out   std_logic
    );
end ADC_peripheral;

architecture internals of ADC_peripheral is

	-- register mappings (c0 -> addr_data, c1 -> addr_status)
    constant ADDR_DATA   : std_logic_vector(10 downto 0) := "00011000000";
    constant ADDR_STATUS : std_logic_vector(10 downto 0) := "00011000001";

    signal start_pulse   : std_logic;
    signal rx_data       : std_logic_vector(11 downto 0);
    signal latest_sample : std_logic_vector(11 downto 0);
    signal busy          : std_logic;
    signal busy_prev     : std_logic;
    signal need_start    : std_logic;

    signal io_en         : std_logic;
    signal read_data     : std_logic_vector(15 downto 0);

begin

    adc_ctrl_inst : entity work.LTC2308_ctrl
        generic map (
            CLK_DIV => 1
        )
        port map (
            clk     => clk,
            nrst    => nrst,
            start   => start_pulse,
            rx_data => rx_data,
            busy    => busy,
            sclk    => sclk,
            conv    => conv,
            mosi    => mosi,
            miso    => miso
        );

    io_bus : lpm_bustri
        generic map (
            lpm_width => 16
        )
        port map (
            data     => read_data,
            enabledt => io_en,
            tridata  => io_data
        );

    io_en <= '1' when io_read = '1' and
                     (io_addr = ADDR_DATA or io_addr = ADDR_STATUS)
        else '0';

	-- maps adc data and status registers onto read_data for scomp reads
    process(io_addr, latest_sample, busy)
    begin
        read_data <= (others => '0');

        case io_addr is
            when ADDR_DATA =>
                read_data(11 downto 0) <= latest_sample;

            when ADDR_STATUS =>
                read_data(1) <= busy;

            when others =>
                read_data <= (others => '0');
        end case;
    end process;
	
	-- 1.starts first conversion after reset. 2.detects when a conversion finishes. 3.stores the completed sample. 4. automatically trigger next conversion
    process(clk, nrst)
    begin
        if nrst = '0' then
            start_pulse   <= '0';
            need_start    <= '1';
            busy_prev     <= '0';
            latest_sample <= (others => '0');
        elsif rising_edge(clk) then
            start_pulse <= '0';

            if busy_prev = '1' and busy = '0' then
                latest_sample <= rx_data;
                need_start    <= '1';
            end if;

            if need_start = '1' then
                start_pulse <= '1';
                need_start  <= '0';
            end if;

            busy_prev <= busy;
        end if;
    end process;

end architecture internals;
