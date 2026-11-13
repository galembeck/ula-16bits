-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Integrantes:
-- - Pedro Henrique Galembeck - 24005794;
-- - Beatriz Bistaffa Vitor - 24003635;
-- - Lorena villagelin - 24005273;
-- - Cecília Gontijo Veloso Teixeira Roque - 24003203;
-- - Cauan Figueiredo Braga - 24787038;

-- Este arquivo contém o banco de registradores da CPU: 8 registradores (R0 a R7) de 16 bits
-- cada, endereçados por 3 bits (os campos Ri, Rj e Rk da instrução têm 3 bits).

-- O banco possui:
-- - 2 portas de LEITURA (combinacionais): "readRegister1" e "readRegister2" escolhem quais
--   registradores aparecem em "readData1" e "readData2" (no datapath: Rj e Rk/Ri).
-- - 1 porta de ESCRITA (síncrona): na borda de subida do clock, se "regWrite" = '1', o valor
--   de "writeData" é gravado no registrador indicado por "writeRegister" (no datapath: Ri).

-- Estrutura interna:
-- - 8 instâncias do componente "register_16bits" (reg0 a reg7);
-- - um decodificador 3 -> 8 que gera o "load" de cada registrador (apenas o registrador
--   escolhido por "writeRegister" recebe '1', e somente quando "regWrite" = '1');
-- - dois multiplexadores 8 -> 1 (um para cada porta de leitura).

-- Observação: todos os registradores podem ser escritos, inclusive o R0.

library ieee;
use ieee.std_logic_1164.all;

use work.components_list.all;

entity register_bank is
	port (
		clk, reset, regWrite : in std_logic; -- Entrada(s): clock, reset e habilitação de escrita.
		readRegister1, readRegister2 : in std_logic_vector(2 downto 0); -- Entrada(s): registradores lidos.
		writeRegister : in std_logic_vector(2 downto 0); -- Entrada: registrador escrito.
		writeData : in std_logic_vector(15 downto 0); -- Entrada: dado a ser escrito.
		readData1, readData2 : out std_logic_vector(15 downto 0) -- Saída(s): dados lidos.
	);
end entity register_bank;

architecture logic of register_bank is
	signal decodedRegister : std_logic_vector(7 downto 0); -- Saída do decodificador 3 -> 8.
	signal loadRegister : std_logic_vector(7 downto 0); -- "load" de cada registrador (R7 a R0).

	signal r0, r1, r2, r3, r4, r5, r6, r7 : std_logic_vector(15 downto 0); -- Conteúdo de cada registrador.
begin
	-- Decodificador 3 -> 8: transforma o número do registrador de escrita em um único bit '1'.
	with writeRegister select
		decodedRegister <=
			"00000001" when "000", -- R0
			"00000010" when "001", -- R1
			"00000100" when "010", -- R2
			"00001000" when "011", -- R3
			"00010000" when "100", -- R4
			"00100000" when "101", -- R5
			"01000000" when "110", -- R6
			"10000000" when "111", -- R7
			"00000000" when others;

	-- O registrador só é escrito se for o escolhido E se "regWrite" estiver ativo.
	loadRegister <= decodedRegister when regWrite = '1' else "00000000";

	-- Instanciamento dos 8 registradores de 16 bits.
	reg0: register_16bits port map (clk, reset, loadRegister(0), writeData, r0);
	reg1: register_16bits port map (clk, reset, loadRegister(1), writeData, r1);
	reg2: register_16bits port map (clk, reset, loadRegister(2), writeData, r2);
	reg3: register_16bits port map (clk, reset, loadRegister(3), writeData, r3);
	reg4: register_16bits port map (clk, reset, loadRegister(4), writeData, r4);
	reg5: register_16bits port map (clk, reset, loadRegister(5), writeData, r5);
	reg6: register_16bits port map (clk, reset, loadRegister(6), writeData, r6);
	reg7: register_16bits port map (clk, reset, loadRegister(7), writeData, r7);

	-- Porta de leitura 1: multiplexador 8 -> 1 controlado por "readRegister1".
	with readRegister1 select
		readData1 <=
			r0 when "000",
			r1 when "001",
			r2 when "010",
			r3 when "011",
			r4 when "100",
			r5 when "101",
			r6 when "110",
			r7 when "111",
			x"0000" when others;

	-- Porta de leitura 2: multiplexador 8 -> 1 controlado por "readRegister2".
	with readRegister2 select
		readData2 <=
			r0 when "000",
			r1 when "001",
			r2 when "010",
			r3 when "011",
			r4 when "100",
			r5 when "101",
			r6 when "110",
			r7 when "111",
			x"0000" when others;
end architecture logic;