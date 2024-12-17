library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.SevenSegmentPkg.all;
entity toplevel is
    port (
        -- Clock and Reset
        clk_10mhz       : in std_logic;                               
        clk_50mhz       : in std_logic;                               
        reset_n         : in std_logic;                               
		  segments : out seven_segment_array(3 downto 0) 

    );
end entity toplevel;

architecture behavior of toplevel is

    -- Internal Signals
    signal pll_clk         : std_logic;                               -- 10 MHz clock from PLL
    signal soc_fsm         : std_logic;                               -- SOC signal for control unit
    signal eoc_fsm         : std_logic;                               -- EOC signal for control unit
    signal adc_data_out    : natural range 0 to 2**12 - 1;            -- ADC 12-bit output
    signal slow_clock      : std_logic;                               -- Slow clock output from ADC
    signal fifo_write_en   : std_logic;                               -- FIFO write enable signal
    signal fifo_data_in    : std_logic_vector(11 downto 0);           -- Data input to FIFO
    signal fifo_data_out   : std_logic_vector(11 downto 0);           -- Data output from FIFO
    signal fifo_read_en    : std_logic;                               -- FIFO read enable signal
    signal fifo_full       : std_logic;                               -- FIFO full flag
    signal fifo_empty      : std_logic;                               -- FIFO empty flag
    signal fifo_head       : std_logic_vector(7 downto 0);            -- FIFO head pointer
    signal fifo_tail       : std_logic_vector(7 downto 0);            -- FIFO tail pointer
begin 

    -- PLL Instance
    pll_inst: entity work.PLL
        port map (
            inclk0 => clk_10mhz,
            c0     => pll_clk
        );

    -- MAX10 ADC Instance
    max10_adc_inst: entity work.max10_adc
        port map (
            pll_clk => pll_clk,
            chsel   => 0,                  
            soc     => soc_fsm,             
            tsen    => '1',                 -- tsd
            dout    => adc_data_out,        
            eoc     => eoc_fsm,             
            clk_dft => slow_clock           
        );

    -- ADC Control Unit Instance
    control_unit_inst: entity work.control_unit
        port map (
            clk_adc       => slow_clock,    
            rst_n         => reset_n,      
            eoc           => eoc_fsm,      
            tail          => fifo_tail,    
            soc           => soc_fsm,     
            fifo_write_en => fifo_write_en,
            head          => fifo_head    
        );

    -- FIFO Instance
    fifo_inst: entity work.fifo_cdc
        generic map (
            DATA_WIDTH => 12,             
            ADDR_WIDTH => 8                
        )
        port map (
            clk_a        => slow_clock,     
            rst_a_n      => reset_n,        
            write_en     => fifo_write_en, 
            data_in      => std_logic_vector(to_unsigned(adc_data_out, 12)), 
            clk_b        => clk_50mhz,    
            rst_b_n      => reset_n,       
            read_en      => fifo_read_en,  
            data_out     => fifo_data_out, 
            fifo_empty   => fifo_empty,   
            fifo_full    => fifo_full,    
            head         => fifo_head,     
            tail         => fifo_tail     
        );

    -- Consumer Logic 
    consumer_inst: entity work.consumer_logic
        port map (
            clk_consumer => clk_50mhz,     
            rst_n        => reset_n,     
            fifo_data    => fifo_data_out, 
            fifo_empty   => fifo_empty,    
            fifo_read_en => fifo_read_en   
        );
		  -- Seven-Segment Display 
    seven_seg_inst: entity work.SevenSegmentDisplay
        port map (
            data_in  => fifo_data_out,
            segments => segments       
        );


end architecture behavior;
