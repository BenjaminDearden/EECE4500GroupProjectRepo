library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;
use work.SevenSegmentPkg.all;

entity seven_segment_agent is
    generic (
        lamp_mode_common_anode : boolean := true; -- Configuration of the lamps in the seven-segment displays.
        decimal_support         : boolean := true; --  decimal numbers.
        implementer             : natural range 1 to 255 := 1; -- Determines the implementer of the core.
        revision                : natural range 0 to 255 := 0  -- Revision of the core.
    );
    port (
        clk        : in std_logic; -- .
        reset_n    : in std_logic; -- Active-low reset signal.
        address    : in std_logic_vector(1 downto 0); -- Address bus
        read       : in std_logic; -- Active high signal 
        readdata   : out std_logic_vector(31 downto 0); -- Read data bus
        write      : in std_logic; -- Active high signal 
        writedata  : in std_logic_vector(31 downto 0); -- Write data bus, 
        lamps      : out std_logic_vector(41 downto 0) -- Lamps outpu
    );
end entity seven_segment_agent;

architecture Behavioral of seven_segment_agent is
	function lamp_mode
		return lamp_configuration
	is
	begin
		if lamp_mode_common_anode then
			return common_anode;
		end if;
		return common_cathode;
	end function lamp_mode;

	function features_reg
		return std_logic_vector
	is
		variable ret: std_logic_vector(31 downto 0) := ( others => '0' );
	begin
		ret(31 downto 24) := std_logic_vector(to_unsigned(implementer, 8)); -- implemnter ID
		ret(23 downto 16) := std_logic_vector(to_unsigned(implementer, 8)); -- core revision 
		if decimal_support then
			ret(0) := '1';
		end if;
		if lamp_mode_common_anode then
			ret(3) := '1';
		end if;
		return ret;
	end function features_reg;

    -- 32-bit signals for registers
    signal data    : std_logic_vector(31 downto 0);
    signal control : std_logic_vector(31 downto 0);
    signal features : std_logic_vector(31 downto 0); -- Read-only register for features
    signal magic    : std_logic_vector(31 downto 0) := x"41445335"; -- Magic number, 0x41445335
    signal bcd_output : std_logic_vector(19 downto 0);  -- BCD Output 
    signal digits: seven_segment_array(0 to 5);
    signal bcd_data: std_logic_vector(23 downto 0);
begin
    process (clk) is 
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                data <= (others => '0');
                control <= (others => '0');
            elsif write = '1' then
            	case address is
                        when "00" => -- Data register
                            data <= writedata;

                        when "01" => -- Control register
								
                            control(0) <= writedata(0); -- Bit for "Turn on lamps"
                            
                            if decimal_support then
                                control(1) <= writedata(1);
                            end if;

                        when others =>
                            null;
                  end case;
              elsif read = '1' then
                    case address is
                        when "00" => -- Data register
                            readdata <= data;

                        when "01" => -- Control register
                            readdata <= control; 

                        when "10" => -- Features register
                            readdata <= features_reg;

                        when "11" => -- Magic number
                            readdata <= magic;

                        when others =>
                            -- For invalid addresses, return zero
                            readdata <= (others => '0');
                    end case;
            end if;
        end if;
    end process;

    drive_digits: for i in digits'range generate
	digits(i) <= lamps_off(lamp_mode) when control(0) = '0'
		     else get_hex_digit(to_integer(unsigned(bcd_data(4*i + 3 downto 4*i))), lamp_mode) when control(1) = '1' and decimal_support
		     else get_hex_digit(to_integer(unsigned(data(4*i + 3 downto 4*i))), lamp_mode);
    end generate drive_digits;
 
    bcd_data <= "0000" & to_bcd(data(15 downto 0));
    lamps <= concat_segments(digits);
	

end architecture Behavioral;
