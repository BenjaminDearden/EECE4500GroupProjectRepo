library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
    port (
        -- Inputs
        clk_adc        : in  std_logic;                               -- ADC clock (producer domain)
        rst_n          : in  std_logic;                               -- Active-low reset
        eoc            : in  std_logic;                               -- End-of-conversion from ADC
        tail           : in  std_logic_vector(7 downto 0);            -- FIFO tail pointer (from consumer)

        -- Outputs
        soc            : out std_logic;                               -- Start-of-conversion signal to ADC
        fifo_write_en  : out std_logic;                               -- Write enable for FIFO
        head           : out std_logic_vector(7 downto 0)             -- FIFO head pointer (to producer)
    );
end entity control_unit;

architecture behavioral of control_unit is
    -- Control States
    type state_type is (START, WAIT_EOC, TRANSFER);
    signal current_state, next_state : state_type;

    -- Internal Signals
    signal fifo_full : std_logic; -- Internal FIFO full flag
    signal head_reg  : std_logic_vector(7 downto 0) := (others => '0'); -- Head pointer register
begin

    -- FIFO Full Logic
    process(head_reg, tail)
    begin
        if (unsigned(head_reg) + 1 = unsigned(tail)) then
            fifo_full <= '1'; -- FIFO is full when head pointer + 1 wraps to tail pointer
        else
            fifo_full <= '0';
        end if;
    end process;

    state_machine: process(clk_adc)
    begin
        if rising_edge(clk_adc) then
            if rst_n = '0' then
                current_state <= START;
                head_reg <= (others => '0'); -- Reset head pointer
            else
                current_state <= next_state;

                -- Update Outputs and Internal Registers
                case current_state is
                    when START =>
                        soc <= '1'; -- Trigger ADC conversion
                        fifo_write_en <= '0';

                    when WAIT_EOC =>
                        soc <= '0'; -- Wait for ADC conversion to complete
                        fifo_write_en <= '0';

                    when TRANSFER =>
                        soc <= '0'; -- No new ADC trigger
                        fifo_write_en <= '1'; -- Write data to FIFO
                        head_reg <= std_logic_vector(unsigned(head_reg) + 1); -- Increment head pointer

                    when others =>
                        soc <= '0';
                        fifo_write_en <= '0';
                end case;
            end if;
        end if;
    end process state_machine;

    -- Next State Logic
    process(current_state, eoc, fifo_full)
    begin
        -- Default next state
        next_state <= current_state;

        case current_state is
            when START =>
                if fifo_full = '0' then
                    next_state <= WAIT_EOC; -- Move to WAIT_EOC if FIFO has space
                end if;

            when WAIT_EOC =>
                if eoc = '1' then
                    next_state <= TRANSFER; -- Move to TRANSFER when ADC conversion is done
                end if;

            when TRANSFER =>
                next_state <= START; -- After transfer, return to START

            when others =>
                next_state <= START; -- Default to START state
        end case;
    end process;

    -- Drive the head output
    head <= head_reg;

end architecture behavioral;
