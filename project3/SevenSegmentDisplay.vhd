library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.SevenSegmentPkg.all;

entity SevenSegmentDisplay is
    port (      
        data_in  : in  std_logic_vector(11 downto 0); -- 12-bit data input from FIFO
        segments : out seven_segment_array(3 downto 0) 
    );
end entity SevenSegmentDisplay;
architecture logic of SevenSegmentDisplay is
    -- Internal signals
    signal bcd        : std_logic_vector(19 downto 0); -- BCD representation of the input
    signal full_value : std_logic_vector(15 downto 0); -- Extended 16-bit binary input
begin
    full_value <= "0000" & data_in;

    -- Convert the binary value to BCD
    bcd <= to_bcd(full_value);

    gen_digits: for i in segments'range generate
        segments(i) <= get_hex_digit(
            digit => to_integer(unsigned(bcd(4 * i + 3 downto 4 * i))),
            lamp_mode => common_anode --
        );
    end generate gen_digits;
end architecture logic;
