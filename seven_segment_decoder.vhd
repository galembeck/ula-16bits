-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Código base: Projeto de Sistemas Digitais

-- Este arquivo contém o decodificador de 7 segmentos, que converte um número de 4 bits
-- (um dígito hexadecimal, de 0 a F) no padrão de segmentos dos displays HEX da placa.

-- Na placa, os segmentos acendem em nível BAIXO ('0' = aceso), e a ordem dos bits da saída
-- é "gfedcba" (bit 6 = segmento g, bit 0 = segmento a).

-- Como cada display mostra apenas 4 bits, um valor de 16 bits precisa de 4 decodificadores:
-- - HEX0 a HEX3 -> valor do PC;
-- - HEX4 a HEX7 -> RDM ou saída da ULA (escolhido pelo SW17).

library ieee;
use ieee.std_logic_1164.all;

entity seven_segment_decoder is
	port (
		input : in std_logic_vector(3 downto 0); -- Entrada: dígito hexadecimal (4 bits).
		segments : out std_logic_vector(6 downto 0) -- Saída: segmentos do display ("gfedcba").
	);
end entity seven_segment_decoder;

architecture logic of seven_segment_decoder is
begin
	with input select
		segments <=
			"1000000" when "0000", -- 0
			"1111001" when "0001", -- 1
			"0100100" when "0010", -- 2
			"0110000" when "0011", -- 3
			"0011001" when "0100", -- 4
			"0010010" when "0101", -- 5
			"0000010" when "0110", -- 6
			"1111000" when "0111", -- 7
			"0000000" when "1000", -- 8
			"0010000" when "1001", -- 9
			"0001000" when "1010", -- A
			"0000011" when "1011", -- b
			"1000110" when "1100", -- C
			"0100001" when "1101", -- d
			"0000110" when "1110", -- E
			"0001110" when "1111", -- F
			"1111111" when others; -- Desligado
end architecture logic;