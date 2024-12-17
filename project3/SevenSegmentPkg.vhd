-- Package declaration
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package SevenSegmentPkg is
    -- Declare a record type for seven-segment configuration
    type seven_segment_config is record
        a : std_logic;
        b : std_logic;
        c : std_logic;
        d : std_logic;
        e : std_logic;
        f : std_logic;
        g : std_logic;
    end record seven_segment_config;

    -- Declare an unconstrained array type using the record as the base type
    type seven_segment_array is array (natural range <>) of seven_segment_config;

    -- Declare the enumerated type for lamp configuration
    type lamp_configuration is (common_anode, common_cathode);

    -- Declare a constant for the default lamp configuration
    constant default_lamp_config : lamp_configuration := common_anode;

    -- Declare the hexadecimal digit subtype
    subtype hex_digit is natural range 0 to 15;

    -- Function prototypes
    function get_hex_digit (
        digit : in hex_digit;
        lamp_mode : in lamp_configuration := default_lamp_config
    ) return seven_segment_config;

    function lamps_off (
        lamp_mode : in lamp_configuration := default_lamp_config
    ) return seven_segment_config;
    
    function to_bcd (
        data_value : in std_logic_vector(15 downto 0)
    ) return std_logic_vector;

    -- Declare the hexadecimal seven-segment table
    constant seven_segment_table : seven_segment_array(0 to 15);
end package SevenSegmentPkg;

-- Package body
package body SevenSegmentPkg is
    -- Define the hexadecimal seven-segment table
    constant seven_segment_table : seven_segment_array(0 to 15) := (
        (a => '1', b => '1', c => '1', d => '1', e => '1', f => '1', g => '0'), -- Hexadecimal 0
        (a => '0', b => '1', c => '1', d => '0', e => '0', f => '0', g => '0'), -- Hexadecimal 1
        (a => '1', b => '1', c => '0', d => '1', e => '1', f => '0', g => '1'), -- Hexadecimal 2
        (a => '1', b => '1', c => '1', d => '1', e => '0', f => '0', g => '1'), -- Hexadecimal 3
        (a => '0', b => '1', c => '1', d => '0', e => '0', f => '1', g => '1'), -- Hexadecimal 4
        (a => '1', b => '0', c => '1', d => '1', e => '0', f => '1', g => '1'), -- Hexadecimal 5
        (a => '1', b => '0', c => '1', d => '1', e => '1', f => '1', g => '1'), -- Hexadecimal 6
        (a => '1', b => '1', c => '1', d => '0', e => '0', f => '0', g => '0'), -- Hexadecimal 7
        (a => '1', b => '1', c => '1', d => '1', e => '1', f => '1', g => '1'), -- Hexadecimal 8
        (a => '1', b => '1', c => '1', d => '1', e => '0', f => '1', g => '1'), -- Hexadecimal 9
        (a => '1', b => '1', c => '1', d => '0', e => '1', f => '1', g => '1'), -- Hexadecimal A
        (a => '0', b => '0', c => '1', d => '1', e => '1', f => '1', g => '1'), -- Hexadecimal B
        (a => '1', b => '0', c => '0', d => '1', e => '1', f => '1', g => '0'), -- Hexadecimal C
        (a => '0', b => '1', c => '1', d => '1', e => '1', f => '0', g => '1'), -- Hexadecimal D
        (a => '1', b => '0', c => '0', d => '1', e => '1', f => '1', g => '1'), -- Hexadecimal E
        (a => '1', b => '0', c => '0', d => '0', e => '1', f => '1', g => '1')  -- Hexadecimal F
    );

    -- Function to invert a seven_segment_config record
    function invert_config(config : seven_segment_config) return seven_segment_config is
    begin
        return (
            a => not config.a,
            b => not config.b,
            c => not config.c,
            d => not config.d,
            e => not config.e,
            f => not config.f,
            g => not config.g
        );
    end function;

    -- Implementation of the get_hex_digit function
    function get_hex_digit (
        digit : in hex_digit;
        lamp_mode : in lamp_configuration := default_lamp_config
    ) return seven_segment_config is
    begin
        if lamp_mode = common_anode then
            -- Use the invert_config function for common anode
            return invert_config(seven_segment_table(digit));
        else
            -- Use raw signals for common cathode
            return seven_segment_table(digit);
        end if;
    end function;

    -- Implementation of the lamps_off function
    function lamps_off (
        lamp_mode : in lamp_configuration := default_lamp_config
    ) return seven_segment_config is
    begin
        if lamp_mode = common_anode then
            return (a => '0', b => '0', c => '0', d => '0', e => '0', f => '0', g => '0');
        else
            return (a => '1', b => '1', c => '1', d => '1', e => '1', f => '1', g => '1');
        end if;
    end function;

    -- Implementation of the to_bcd function
    function to_bcd (
        data_value : in std_logic_vector(15 downto 0)
    ) return std_logic_vector is
        variable ret : std_logic_vector(19 downto 0);
        variable temp : std_logic_vector(data_value'range);
    begin
        -- Initialize temp and ret variables
        temp := data_value;
        ret := (others => '0');
        
        -- Main loop for binary to BCD conversion
        for i in data_value'range loop
            -- Adjust each digit in the BCD if it is 5 or greater
            for j in 0 to ret'length / 4 - 1 loop
                if unsigned(ret(4 * j + 3 downto 4 * j)) >= 5 then
                    ret(4 * j + 3 downto 4 * j) := 
                        std_logic_vector(unsigned(ret(4 * j + 3 downto 4 * j)) + 3);
                end if;
            end loop;

            -- Shift left by 1 bit
            ret := ret(ret'high - 1 downto 0) & temp(temp'high);
            temp := temp(temp'high - 1 downto 0) & '0';
        end loop;

        return ret;
    end function;

end package body SevenSegmentPkg;
