library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_cdc is
    generic (
        DATA_WIDTH : integer := 12;  -- Width of the data
        ADDR_WIDTH : integer := 4    -- Width of the address pointers
    );
    port (
        clk_a        : in std_logic;                                -- Producer clock
        rst_a_n      : in std_logic;                                -- Active-low reset for producer
        write_en     : in std_logic;                                -- Write enable signal
        data_in      : in std_logic_vector(DATA_WIDTH-1 downto 0);  -- Data to write
        clk_b        : in std_logic;                                -- Consumer clock
        rst_b_n      : in std_logic;                                -- Active-low reset for consumer
        read_en      : in std_logic;                                -- Read enable signal
        data_out     : out std_logic_vector(DATA_WIDTH-1 downto 0); -- Data to read
        fifo_empty   : out std_logic;                               -- FIFO empty flag
        fifo_full    : out std_logic;                               -- FIFO full flag
        head         : out std_logic_vector(ADDR_WIDTH-1 downto 0); -- FIFO head pointer (producer side)
        tail         : out std_logic_vector(ADDR_WIDTH-1 downto 0)  -- FIFO tail pointer (consumer side)
    );
end entity fifo_cdc;

architecture behavioral of fifo_cdc is

    -- FIFO Memory Declaration
    type fifo_memory is array (2**ADDR_WIDTH-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal fifo : fifo_memory;

    -- Write and Read Pointers (Binary and Gray)
    signal write_ptr_bin        : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal write_ptr_gray       : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal write_ptr_gray_sync  : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0'); -- Synced to clk_b

    signal read_ptr_bin         : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal read_ptr_gray        : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
    signal read_ptr_gray_sync   : std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0'); -- Synced to clk_a

    -- Two-Stage Synchronizers
    signal write_ptr_gray_sync_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal read_ptr_gray_sync_reg  : std_logic_vector(ADDR_WIDTH-1 downto 0);

    -- Function for Gray to Binary Conversion
    function gray_to_binary(gray : std_logic_vector) return std_logic_vector is
        variable bin : std_logic_vector(gray'range) := (others => '0');
    begin
        bin(bin'high) := gray(gray'high); 
        for i in bin'high-1 downto 0 loop
            bin(i) := gray(i) xor bin(i+1);
        end loop;
        return bin;
    end function gray_to_binary;

    -- FIFO Status
    signal fifo_empty_internal   : std_logic := '1';
    signal fifo_full_internal    : std_logic := '0';

begin

    -- Assign head (write pointer) and tail (read pointer) to outputs
    head <= write_ptr_bin;
    tail <= read_ptr_bin;

    -- Binary to Gray Code Conversion
    write_ptr_gray <= std_logic_vector(unsigned(write_ptr_bin) xor (unsigned(write_ptr_bin) srl 1));
    read_ptr_gray  <= std_logic_vector(unsigned(read_ptr_bin) xor (unsigned(read_ptr_bin) srl 1));

    -- Two-Stage Flip-Flop Synchronizers
    process(clk_b)
    begin
        if rising_edge(clk_b) then
            if rst_b_n = '0' then
                write_ptr_gray_sync_reg <= (others => '0');
                write_ptr_gray_sync     <= (others => '0');
            else
                write_ptr_gray_sync_reg <= write_ptr_gray;           -- Stage 1
                write_ptr_gray_sync     <= write_ptr_gray_sync_reg;  -- Stage 2
            end if;
        end if;
    end process;

    process(clk_a)
    begin
        if rising_edge(clk_a) then
            if rst_a_n = '0' then
                read_ptr_gray_sync_reg <= (others => '0');
                read_ptr_gray_sync     <= (others => '0');
            else
                read_ptr_gray_sync_reg <= read_ptr_gray;           -- Stage 1
                read_ptr_gray_sync     <= read_ptr_gray_sync_reg;  -- Stage 2
            end if;
        end if;
    end process;

    -- FIFO Empty and Full Flags
    fifo_empty_internal <= '1' when read_ptr_bin = gray_to_binary(write_ptr_gray_sync) else '0';
    fifo_full_internal  <= '1' when unsigned(write_ptr_bin) + 1 = unsigned(gray_to_binary(read_ptr_gray_sync)) else '0';

    fifo_empty <= fifo_empty_internal;
    fifo_full  <= fifo_full_internal;

    -- FIFO Write Operation
    process(clk_a)
    begin
        if rising_edge(clk_a) then
            if rst_a_n = '0' then
                write_ptr_bin <= (others => '0');
            elsif write_en = '1' and fifo_full_internal = '0' then
                fifo(to_integer(unsigned(write_ptr_bin))) <= data_in;
                write_ptr_bin <= std_logic_vector(unsigned(write_ptr_bin) + 1);
            end if;
        end if;
    end process;

    -- FIFO Read Operation
    process(clk_b)
    begin
        if rising_edge(clk_b) then
            if rst_b_n = '0' then
                read_ptr_bin <= (others => '0');
                data_out <= (others => '0');
            elsif read_en = '1' and fifo_empty_internal = '0' then
                data_out <= fifo(to_integer(unsigned(read_ptr_bin)));
                read_ptr_bin <= std_logic_vector(unsigned(read_ptr_bin) + 1);
            end if;
        end if;
    end process;

end architecture behavioral;
