
----------------------------------------------------------------------------------
--
-- Prova Finale (Progetto di Reti Logiche)
-- Prof. Gianluca Palermo - Anno 2020/2021
--
-- Mattia Sironi (Codice Persona 10614502 Matricola 908267)
-- Lea Zancani (Codice Persona 10608972  Matricola 907360)
-- 
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity project_reti_logiche is
port (
      i_clk         : in  std_logic;
      i_start       : in  std_logic;
      i_rst         : in  std_logic;
      i_data        : in  std_logic_vector(7 downto 0);
      o_address     : out std_logic_vector(15 downto 0);
      o_done        : out std_logic;
      o_en          : out std_logic;
      o_we          : out std_logic;
      o_data        : out std_logic_vector (7 downto 0)
      );
end entity project_reti_logiche;

architecture gigi of project_reti_logiche is

signal count, count_next : std_logic_vector (15 downto 0);  
signal N_COL, N_RIG : std_logic_vector (7 downto 0);
signal N_CELL : std_logic_vector (15 downto 0);
signal N_COL_NEXT, N_RIG_NEXT : std_logic_vector (7 downto 0);
signal N_CELL_NEXT : std_logic_vector (15 downto 0);
signal MAX, MAX_NEXT, MIN, MIN_NEXT : std_logic_vector (7 downto 0);
signal shift_level, shift_level_next : integer :=0;
signal delta, delta_next: std_logic_vector (7 downto 0);
type state is (STATO_INIZIALE, BEFORE_READ, READ, SHIFT, WRITE, DONE);
signal current_state, next_state: state;
signal second_read, second_read_next : boolean; 
signal tmp, tmp_next : std_logic_vector (15 downto 0);
signal countw, countw_next : std_logic_vector (15 downto 0); 
begin
    
    CONTROL_PROCESS: process (i_clk, i_rst, i_start)
    begin
    
        if (i_rst = '1' or i_start = '0') then
        
            current_state <= STATO_INIZIALE;
                
        elsif (rising_edge(i_clk)) then

            count <= count_next;
            current_state <= next_state;
            N_CELL <= N_CELL_NEXT;
            N_COL <= N_COL_NEXT;
            N_RIG <= N_RIG_NEXT;
            MAX <= MAX_NEXT;
            MIN <= MIN_NEXT;
            delta <= delta_next;
            shift_level <= shift_level_next;
            tmp <= tmp_next;
            countw <= countw_next;
            second_read <= second_read_next;
                   
        end if;
        
        end process;
        
    DELTA_PROCESS: process (i_data, count, current_state, N_COL, N_RIG, N_CELL, MAX, MIN, delta, shift_level, tmp, countw, second_read)
    variable pixel : std_logic_vector(15 downto 0);    
    begin
        
        N_COL_NEXT <= N_COL;
        N_RIG_NEXT <= N_RIG;
        N_CELL_NEXT <= N_CELL;
        MAX_NEXT <= MAX;
        MIN_NEXT <= MIN;
        delta_next <= delta;
        shift_level_next <= shift_level;
        tmp_next <= tmp;
        countw_next <= countw;
        second_read_next <= second_read;
        count_next <= count; 
                
        case current_state is
        
            when STATO_INIZIALE =>
                
                o_address <= (others => '0');
                o_data <= (others => '-');
                o_done <= '0';
                o_en <= '0';
                o_we <= '0';
                count_next <= (others => '0');
                next_state <= BEFORE_READ; 
                N_CELL_NEXT <= (others => '0');
                N_COL_NEXT <= (others => '0');
                N_RIG_NEXT <= (others => '0');
                MAX_NEXT <= (others => '0');
                MIN_NEXT <= (others => '1');
                delta_next <= (others => '0');
                shift_level_next <= 0;
                second_read_next <= false;
                tmp_next <= (others => '0');
                countw_next <= (others => '0');                
        
            when BEFORE_READ =>
              
                o_done <= '0';
                o_en <= '1';
                o_we <= '0';
                o_address <= count;
                o_data <= (others => '-');
                next_state <= READ;                
         
            when READ =>
                
                if (count = 0) then
                
                    N_COL_NEXT <= i_data;
                    count_next <= count +1;
                    next_state <= BEFORE_READ;
                    
                elsif (count = 1) then
                 
                    N_RIG_NEXT <= i_data;
                    if (N_COL /= 0 and i_data /= 0) then 
                        N_CELL_NEXT <= std_logic_vector (unsigned(N_COL) * unsigned (i_data));
                        countw_next <= std_logic_vector (unsigned(N_COL) * unsigned (i_data) +2);
                        count_next <= count +1;
                        next_state <= BEFORE_READ;
                    else
                        next_state <= DONE;
                    end if;    
                    
                elsif (count < N_CELL +2 and second_read = false) then
                    if (i_data > MAX) then
                    
                        MAX_NEXT <= i_data;
                    
                    end if;
                    
                    if (i_data < MIN) then
                    
                        MIN_NEXT <= i_data;
                    
                    end if;
                    
                    count_next <= count+1;
                    next_state <= BEFORE_READ;
                    
                elsif (count = N_CELL +2 and second_read = false) then
                    
                    count_next <= (1 => '1', others => '0');
                    delta_next <= std_logic_vector( unsigned (MAX) - unsigned (MIN)); 
                    next_state <= SHIFT;
                    second_read_next <= true; -- ho finito la prima lettura per trovare max,min e delta.
                   
                elsif (count < N_CELL +2 and second_read = true) then
               
                    tmp_next <= "00000000" & std_logic_vector (unsigned (i_data) - unsigned (MIN));
                    count_next <= count +1;
                    next_state <= WRITE;
                    
                else 
                    next_state <= DONE;    
                                  
                end if;
                o_en <= '0';
                o_we <= '0';
                o_done <= '0';
                o_data <= (others => '-');
                o_address <= (others => '-');                
                
            when WRITE =>
            
                pixel := std_logic_vector(shift_left(unsigned(tmp),shift_level)) ;
                count_next <= count;
                o_address <= countw;
                
                if (unsigned(pixel) >255) then
                    o_data <= "11111111";
                            
                else
                
                    o_data <= pixel (7 downto 0);
                    
                end if;
                
                o_done <= '0';
                o_en <= '1';
                o_we <= '1';
                countw_next <= countw +1;
                next_state <= BEFORE_READ;               
                
            when SHIFT =>
                   
               if unsigned(DELTA) = 0 then
                            
                shift_level_next <= 8;
                          
                     
               elsif unsigned(DELTA) = 1 or unsigned(DELTA) = 2 then
                             
                shift_level_next  <= 7;
                         
               elsif unsigned(DELTA) >= 3 and unsigned(DELTA) <= 6 then
                            
                shift_level_next  <= 6;
                         
               elsif unsigned(DELTA) >= 7 and unsigned(DELTA) <= 14 then
                            
                shift_level_next <= 5;
                         
               elsif unsigned(DELTA) >= 15 and unsigned(DELTA) <= 30 then
                            
                shift_level_next  <= 4;
                         
               elsif unsigned(DELTA) >= 31 and unsigned(DELTA) <= 62 then
                            
                shift_level_next  <= 3;
                         
               elsif unsigned(DELTA) >= 63 and unsigned(DELTA) <= 126 then
                             
                shift_level_next  <= 2;
                         
               elsif unsigned(DELTA) >= 127 and unsigned(DELTA) <= 254 then
                            
                shift_level_next <= 1;
                         
               else 
                            
                shift_level_next <= 0;
                         
               end if;
                        
               count_next <= count;
               next_state <= BEFORE_READ;
               o_en <= '0';
               o_we <= '0';
               o_done <= '0';
               o_data <= (others => '-');
               o_address <= (others => '-');              
                                      
            when others => --when DONE
                
                o_address <= (others => '0');
                o_data <= (others => '-');
                o_done <= '1';
                o_en <= '0';
                o_we <= '0';                
                next_state <= STATO_INIZIALE;
                
        end case;
      
     end process;
            
end gigi;           
            
        
        
    
    