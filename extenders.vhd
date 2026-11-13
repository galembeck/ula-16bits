-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Integrantes:
-- - Pedro Henrique Galembeck - 24005794;
-- - Beatriz Bistaffa Vitor - 24003635;
-- - Lorena villagelin - 24005273;
-- - Cecília Gontijo Veloso Teixeira Roque - 24003203;
-- - Cauan Figueiredo Braga - 24787038;

-- Este arquivo reúne os 2 extensores utilizados no datapath da CPU:
-- - sign_extend -> estende o imediato de 6 para 16 bits, preservando o sinal;
-- - zero_extend -> estende o endereço do JMP de 12 para 16 bits, com zeros.

-- ========================================================================================
-- sign_extend: extensor de sinal, que transforma o imediato de 6 bits da
-- instrução (bits 5 a 0 do RI) em um número de 16 bits, preservando o seu sinal.

-- Como o imediato está em complemento de dois, o bit mais significativo ("input(5)") é o
-- bit de sinal. Para estender o número sem mudar o seu valor, esse bit é copiado para
-- todas as posições novas (bits 15 a 6). Exemplos:
-- - "000101" (+5) -> "0000000000000101" (+5)
-- - "111011" (-5) -> "1111111111111011" (-5)

library ieee;
use ieee.std_logic_1164.all;

entity sign_extend is
	port (
		input : in std_logic_vector(5 downto 0); -- Entrada: imediato de 6 bits.
		output : out std_logic_vector(15 downto 0) -- Saída: imediato estendido para 16 bits.
	);
end entity sign_extend;

architecture logic of sign_extend is
begin
	output(15 downto 6) <= (others => input(5)); -- Cópia do bit de sinal nos bits novos.
	output(5 downto 0) <= input; -- Os 6 bits originais são mantidos.
end architecture logic;

-- ========================================================================================
-- zero_extend: extensor de zeros, que transforma o campo "end" de 12 bits da
-- instrução JMP (bits 11 a 0 do RI) em um endereço de 16 bits.

-- Como o endereço de salto é sempre positivo (absoluto), os 4 bits novos (15 a 12) são
-- preenchidos com '0'. Assim, o JMP alcança os endereços de 0 a 4095 (0x000 a 0xFFF).

library ieee;
use ieee.std_logic_1164.all;

entity zero_extend is
	port (
		input : in std_logic_vector(11 downto 0); -- Entrada: endereço de 12 bits.
		output : out std_logic_vector(15 downto 0) -- Saída: endereço estendido para 16 bits.
	);
end entity zero_extend;

architecture logic of zero_extend is
begin
	output <= "0000" & input; -- Concatenação de 4 zeros à esquerda.
end architecture logic;