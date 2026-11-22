-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Código base: exemplo de teste de memória disponibilizado pelo professor

-- Este arquivo é um teste da memória na placa DE2-115, feito ANTES de montar a CPU completa.
-- Ele permite conferir se o arquivo .mif foi carregado corretamente: o endereço é escolhido
-- nos switches e o conteúdo daquela posição aparece nos LEDs e nos displays.

-- Mapeamento na placa:
-- - SW7 a SW0      -> endereço da memória (0 a 255);
-- - LEDR15 a LEDR0 -> conteúdo da posição (16 bits, em binário);
-- - HEX3 a HEX0    -> conteúdo da posição (em hexadecimal);
-- - HEX5 e HEX4    -> endereço escolhido (em hexadecimal).

-- Para usar: defina "memory_test" como entidade principal (top-level), compile e grave na
-- placa. Compare o valor mostrado em cada endereço com a listagem do programa no .mif.

library ieee;
use ieee.std_logic_1164.all;

use work.components_list.all;

entity memory_test is
	port (
		SW : in std_logic_vector(7 downto 0); -- Entrada(s): switches SW[7:0] (endereço).
		LEDR : out std_logic_vector(15 downto 0); -- Saída(s): LEDR[15:0] (conteúdo).
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5 : out std_logic_vector(6 downto 0) -- Saída(s): displays.
	);
end entity memory_test;

architecture logic of memory_test is
	signal address : std_logic_vector(15 downto 0); -- Endereço de 16 bits (8 bits dos switches).
	signal memData : std_logic_vector(15 downto 0); -- Conteúdo lido da memória.
begin
	-- O endereço vem dos switches; os 8 bits mais significativos ficam em zero.
	address <= "00000000" & SW(7 downto 0);

	-- Instanciamento da memória apenas para leitura (sem escrita e sem clock).
	memoryInstance: memory
		port map (
			clk => '0', -- Clock não utilizado (não há escrita);
			memRead => '1', -- Leitura sempre habilitada;
			memWrite => '0', -- Escrita desabilitada;
			address => address, -- Endereço escolhido nos switches;
			writeData => x"0000", -- Dado de escrita não utilizado;
			memData => memData -- Conteúdo da posição;
		);

	-- Conteúdo da memória nos LEDs vermelhos.
	LEDR <= memData;

	-- Conteúdo da memória nos displays HEX3 a HEX0 (4 bits por display).
	hex0Decoder: seven_segment_decoder port map (memData(3 downto 0), HEX0);
	hex1Decoder: seven_segment_decoder port map (memData(7 downto 4), HEX1);
	hex2Decoder: seven_segment_decoder port map (memData(11 downto 8), HEX2);
	hex3Decoder: seven_segment_decoder port map (memData(15 downto 12), HEX3);

	-- Endereço nos displays HEX5 e HEX4.
	hex4Decoder: seven_segment_decoder port map (SW(3 downto 0), HEX4);
	hex5Decoder: seven_segment_decoder port map (SW(7 downto 4), HEX5);
end architecture logic;