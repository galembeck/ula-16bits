-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Integrantes:
-- - Pedro Henrique Galembeck - 24005794;
-- - Beatriz Bistaffa Vitor - 24003635;
-- - Lorena villagelin - 24005273;
-- - Cecília Gontijo Veloso Teixeira Roque - 24003203;
-- - Cauan Figueiredo Braga - 24787038;

-- Este arquivo reúne os 3 multiplexadores utilizados no datapath da CPU:
-- - MUX 2 : 1 (16 bits) -> IorD, MemtoReg e ALUSrcA;
-- - MUX 3 : 1 (16 bits) -> ALUSrcB e PCSource;
-- - MUX 2 : 1 (3 bits)  -> RegSrc.

-- ========================================================================================
-- MUX 2 : 1 (16 bits): multiplexador de 2 entradas de 16 bits. O sinal "sel" escolhe
-- qual das entradas aparece na saída:
-- - sel = '0' -> output = input0
-- - sel = '1' -> output = input1

-- No datapath, ele é utilizado nos seguintes pontos:
-- - IorD     -> endereço da memória: PC (0) ou ALUOut (1);
-- - MemtoReg -> dado escrito no banco: ALUOut (0) ou RDM (1);
-- - ALUSrcA  -> 1º operando da ULA: PC (0) ou A (1).

library ieee;
use ieee.std_logic_1164.all;

entity mux_2to1_16bits is
	port (
		sel : in std_logic; -- Entrada: seletor.
		input0, input1 : in std_logic_vector(15 downto 0); -- Entrada(s): opções 0 e 1.
		output : out std_logic_vector(15 downto 0) -- Saída: entrada escolhida.
	);
end entity mux_2to1_16bits;

architecture logic of mux_2to1_16bits is
begin
	with sel select
		output <=
			input0 when '0',
			input1 when others;
end architecture logic;

-- ========================================================================================
-- MUX 3 : 1 (16 bits): multiplexador de 3 entradas de 16 bits. O sinal "sel" (2 bits)
-- escolhe qual das entradas aparece na saída:
-- - sel = "00" -> output = input0
-- - sel = "01" -> output = input1
-- - sel = "10" -> output = input2
-- - sel = "11" -> não utilizado (saída zerada)

-- No datapath, ele é utilizado nos seguintes pontos:
-- - ALUSrcB  -> 2º operando da ULA: B (00), constante 1 (01) ou imediato estendido (10);
-- - PCSource -> novo valor do PC: saída da ULA (00), ALUOut (01) ou endereço do JMP (10).

library ieee;
use ieee.std_logic_1164.all;

entity mux_3to1_16bits is
	port (
		sel : in std_logic_vector(1 downto 0); -- Entrada: seletor.
		input0, input1, input2 : in std_logic_vector(15 downto 0); -- Entrada(s): opções 0, 1 e 2.
		output : out std_logic_vector(15 downto 0) -- Saída: entrada escolhida.
	);
end entity mux_3to1_16bits;

architecture logic of mux_3to1_16bits is
begin
	with sel select
		output <=
			input0 when "00",
			input1 when "01",
			input2 when "10",
			x"0000" when others;
end architecture logic;

-- ========================================================================================
-- MUX 2 : 1 (3 bits): multiplexador de 2 entradas de 3 bits, usado para escolher o
-- número de um registrador (e não um dado de 16 bits). O sinal "sel" escolhe a saída:
-- - sel = '0' -> output = input0
-- - sel = '1' -> output = input1

-- No datapath, ele é utilizado no sinal RegSrc, que define o registrador lido na porta 2
-- do banco: Rk (0), nas instruções do tipo R, ou Ri (1), nas instruções ST, BEQ e BNE.

library ieee;
use ieee.std_logic_1164.all;

entity mux_2to1_3bits is
	port (
		sel : in std_logic; -- Entrada: seletor.
		input0, input1 : in std_logic_vector(2 downto 0); -- Entrada(s): opções 0 e 1.
		output : out std_logic_vector(2 downto 0) -- Saída: entrada escolhida.
	);
end entity mux_2to1_3bits;

architecture logic of mux_2to1_3bits is
begin
	with sel select
		output <=
			input0 when '0',
			input1 when others;
end architecture logic;