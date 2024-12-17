library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity consumer_logic is
    port (
        clk_consumer : in  std_logic;                               -- Consumer clock
        rst_n        : in  std_logic;                               -- Active-low reset
        fifo_data    : in  std_logic_vector(11 downto 0);           -- Data from FIFO
        fifo_empty   : in  std_logic;                               -- FIFO empty flag
        fifo_read_en : out std_logic                                -- Read enable for FIFO
    );
end entity consumer_logic;

architecture behavioral of consumer_logic is
    -- Internal Signal
    signal read_en : std_logic := '0';                              -- Internal read enable
begin
    process(clk_consumer)
    begin
        if rising_edge(clk_consumer) then
            if rst_n = '0' then
                read_en <= '0';
            elsif fifo_empty = '0' then
                -- Enable reading when FIFO is not empty
                read_en <= '1';
            else
                read_en <= '0';
            end if;
        end if;
    end process;

    fifo_read_en <= read_en; -- Drive FIFO read enable

end architecture behavioral;
