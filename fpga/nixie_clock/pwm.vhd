LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY pwm IS
  GENERIC(
      bits_resolution : INTEGER := 14;                                                          -- PWM resolution
      phases          : INTEGER := 60;                                                          -- Number of output pwms and phases
      phase_selwidth  : INTEGER := 6);                                                          -- Vector width to select a phase
  PORT(                 
      CLK_IN        : IN  STD_LOGIC;                                                            -- System clock
      RESET_IN      : IN  STD_LOGIC;                                                            -- Asynchronous reset
      ENA_IN        : IN  STD_LOGIC;                                                            -- Latches in new DUTY_IN cycle
      DUTY_IN       : IN  STD_LOGIC_VECTOR(bits_resolution-1 DOWNTO 0);                         -- DUTY_IN cycle
      CH_SELECT_IN  : IN  STD_LOGIC_VECTOR(phase_selwidth-1 DOWNTO 0);                          -- Channel select
      PWM_OUT       : OUT STD_LOGIC_VECTOR(phases-1 DOWNTO 0));                                 -- PWM outputs
END pwm;

ARCHITECTURE logic OF pwm IS
  TYPE compares IS ARRAY (0 TO phases-1) OF STD_LOGIC_VECTOR(bits_resolution-1 DOWNTO 0);       -- Data type for array of compare values
  SIGNAL counter : STD_LOGIC_VECTOR(bits_resolution-1 DOWNTO 0);                                -- Main PWM Counter, counting up
  SIGNAL compare_array : compares;                                                              -- Array of compare values
BEGIN
  PROCESS(CLK_IN, RESET_IN)
  BEGIN
    IF(RESET_IN = '0') THEN                                                                     --asynchronous reset
      compare_array <= (others=>(others=>'0'));                                                 --clear compares
      counter <= (OTHERS => '0');                                                               --clear counter
      PWM_OUT <= (OTHERS => '0');                                                               --clear pwm outputs
    ELSIF(CLK_IN'EVENT AND CLK_IN = '1') THEN                                                   --rising system clock edge
      IF(ENA_IN = '1') THEN                                                                     --latch in new DUTY_IN cycle
        compare_array(conv_integer(CH_SELECT_IN)) <= DUTY_IN;                                   --store new compare value
      END IF;
      FOR i IN 0 to phases-1 LOOP                                                               --control outputs for each phase
        IF(counter = compare_array(i)) THEN                                                     --we reached the compare value
          PWM_OUT(i) <= '0';                                                                    --deassert the pwm output
        ELSIF(counter = 0) THEN                                                                 --start of period
          PWM_OUT(i) <= '1';                                                                    --assert the pwm output
        END IF;
      END LOOP;
      counter <= counter + 1;
    END IF;
  END PROCESS;
END logic;
