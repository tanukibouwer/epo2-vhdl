library IEEE;
use ieee.std_logic_1164.all;

entity controller is
    port (
        clk   : in std_logic;
        reset : in std_logic;

        sensor_data     : in std_logic_vector (2 downto 0);
        next_direction  : in std_logic_vector (1 downto 0); -- 00 = straight, 01 = left, 10 = right, 11 = backwards
        stop_checkpoint : in std_logic;
        new_direction   : in std_logic;

        motor_l_reset     : out std_logic;
        motor_l_direction : out std_logic; -- 1 = forward, 0 = backwards

        motor_r_reset     : out std_logic;
        motor_r_direction : out std_logic; -- 0 = forward, 1 = backwards

        ask_next_direction : out std_logic
    );
end entity controller;

architecture behavioural of controller is

    signal motor_left_reset, motor_right_reset             : std_logic := '0';
    signal motor_left_direction, motor_right_direction     : std_logic := '0';
    signal turning, skip_checkpoint, checkpoint, skip_turn : std_logic := '0';
    type direction_state is (forward_1, right_1, left_1, left_2, right_2, backward, forward_2);
    signal state, next_state                               : direction_state;
    signal fsm_direction                                   : std_logic_vector(1 downto 0); -- Direction signal in de if statements moet nog hiernaar worden aangepast.


begin

    process (clk, reset)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                motor_left_reset  <= '1';
                motor_right_reset <= '1';
                turning           <= '0';
                skip_checkpoint   <= '0';
                checkpoint        <= '0';
                skip_checkpoint   <= '0';
            elsif (turning = '1') then
                if (skip_turn = '1') then
                    if (sensor_data = "111") then
                        skip_turn <= '0';
                    end if;
                elsif (sensor_data = "011" or sensor_data = "110") then
                    turning <= '0';
                end if;
            elsif (sensor_data = "000") then
                -- Checkpoint
                checkpoint <= '1';
                if (skip_checkpoint = '1') then
                    -- Skip checkpoint
                    motor_left_reset      <= '0';
                    motor_right_reset     <= '0';
                    motor_left_direction  <= '1';
                    motor_right_direction <= '0';
                elsif (stop_checkpoint = '1') then
                    motor_left_reset  <= '1';
                    motor_right_reset <= '1';
                elsif (next_direction = "00") then
                    -- Straight
                    motor_left_reset      <= '0';
                    motor_right_reset     <= '0';
                    motor_left_direction  <= '1';
                    motor_right_direction <= '0';
                elsif (next_direction = "01") then
                    -- Left
                    motor_left_reset      <= '0';
                    motor_right_reset     <= '0';
                    motor_left_direction  <= '0';
                    motor_right_direction <= '0';
                    skip_turn             <= '1';
                elsif (next_direction = "10") then
                    -- Right
                    motor_left_reset      <= '0';
                    motor_right_reset     <= '0';
                    motor_left_direction  <= '1';
                    motor_right_direction <= '1';
                    skip_turn             <= '1';
                elsif (next_direction = "11") then
                    -- Backwards
                    motor_left_reset      <= '0';
                    motor_right_reset     <= '0';
                    motor_left_direction  <= '0';
                    motor_right_direction <= '0';
                    turning               <= '1';
                    skip_turn             <= '1';
                end if;
            elsif (sensor_data = "001") then
                motor_left_reset      <= '1';
                motor_right_reset     <= '0';
                motor_right_direction <= '0';
            elsif (sensor_data = "010") then
                motor_left_reset      <= '0';
                motor_right_reset     <= '0';
                motor_left_direction  <= '1';
                motor_right_direction <= '0';
            elsif (sensor_data = "011") then
                motor_left_reset      <= '0';
                motor_right_reset     <= '0';
                motor_left_direction  <= '0';
                motor_right_direction <= '0';
            elsif (sensor_data = "100") then
                motor_left_reset     <= '0';
                motor_right_reset    <= '1';
                motor_left_direction <= '1';
            elsif (sensor_data = "101") then
                motor_left_reset      <= '0';
                motor_right_reset     <= '0';
                motor_left_direction  <= '1';
                motor_right_direction <= '0';
            elsif (sensor_data = "110") then
                motor_left_reset      <= '0';
                motor_right_reset     <= '0';
                motor_left_direction  <= '1';
                motor_right_direction <= '1';
            elsif (sensor_data = "111") then
                motor_left_reset      <= '0';
                motor_right_reset     <= '0';
                motor_left_direction  <= '1';
                motor_right_direction <= '0';
            end if;
            if (checkpoint = '1' and sensor_data = "101") then
                checkpoint <= '0';
                if (skip_checkpoint = '1') then
                    skip_checkpoint <= '0';
                else
                    skip_checkpoint    <= '1';
                    ask_next_direction <= '1';
                end if;
            end if;
            if (new_direction = '1') then
                ask_next_direction <= '0';
            end if;
        end if;
    end process;

    process(state)
    begin
        case state is 
            when forward_1 =>
            fsm_direction <= "00";
            next_state <= right_1;

            when right_1 =>
            fsm_direction <= "10";
            next_state <= left_1;

            when left_1 => 
            fsm_direction <= "01";
            next_state <= left_2;

            when left_2 =>
            fsm_direction <= "01";
            next_state <= right_2;

            when right_2 =>
            fsm_direction <= "10";
            next_state <= backward;

            when backward =>
            fsm_direction <= "11";
            next_state <= forward_2;

            when forward_2 =>
            fsm_direction <= "00";
            next_state <= forward_2;
        end case;
    end process;

    process(reset, ask_next_direction) --update de state als the main controller een nieuwe value voor direction wil.
    begin
        if (reset = '1') then
            state <= forward_1;
        elsif (ask_next_direction = '1') then
            state <= next_state;
        end if;
    end process;




    motor_l_reset <= motor_left_reset;
    motor_r_reset <= motor_right_reset;

    motor_l_direction <= motor_left_direction;
    motor_r_direction <= motor_right_direction;

end architecture behavioural;