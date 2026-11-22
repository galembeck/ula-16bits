-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Este arquivo é a entidade principal (top-level) do projeto: liga a CPU aos recursos da
-- placa FPGA DE2-115, conforme pedido no enunciado.

-- Mapeamento na placa:
-- - KEY0           -> clock da CPU (cada aperto = 1 ciclo), passando pelo debouncer;
-- - KEY1           -> reset (zera PC, registradores e volta a UC para a busca);
-- - CLOCK_50       -> clock de 50 MHz, usado apenas pelo debouncer;
-- - HEX3 a HEX0    -> valor do PC (hexadecimal);
-- - HEX7 a HEX4    -> SW17 = '0': valor lido da memória (RDM) | SW17 = '1': saída da ULA;
-- - LEDG8 a LEDG0  -> estado atual da unidade de controle (um LED aceso por estado).

-- Observação: na DE2-115, os botões KEY valem '0' quando apertados. Por isso eles são
-- invertidos (NOT) antes de serem usados.

library ieee;
use ieee.std_logic_1164.all;

use work.components_list.all;

entity cpu_board is
	port (
		CLOCK_50 : in std_logic; -- Entrada: clock de 50 MHz da placa.
		KEY : in std_logic_vector(1 downto 0); -- Entrada(s): botões KEY0 (clock) e KEY1 (reset).
		SW : in std_logic_vector(17 downto 17); -- Entrada: switch SW17 (seleção do display).
		HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(6 downto 0); -- Saída(s): displays.
		LEDG : out std_logic_vector(8 downto 0) -- Saída(s): LEDs verdes (estado da UC).
	);
end entity cpu_board;

architecture logic of cpu_board is
	signal buttonPressed, cpuClock, reset : std_logic; -- Botões já invertidos e clock limpo.
	signal pc, mdr, aluResult : std_logic_vector(15 downto 0); -- Saídas da CPU.
	signal displayValue : std_logic_vector(15 downto 0); -- Valor mostrado em HEX7 a HEX4.
begin
	-- Inversão dos botões (na placa, '0' = apertado).
	buttonPressed <= NOT KEY(0);
	reset <= NOT KEY(1);

	-- Debouncer: o botão KEY0, sem ruído, vira o clock da CPU.
	debouncerInstance: debouncer port map (CLOCK_50, buttonPressed, cpuClock);

	-- Instanciamento da CPU.
	cpuInstance: cpu
		port map (
			clk => cpuClock, -- Clock vindo do botão;
			reset => reset, -- Reset vindo do botão;
			pcOut => pc, -- Valor do PC;
			mdrOut => mdr, -- Valor do RDM;
			aluResultOut => aluResult, -- Saída da ULA;
			stateLeds => LEDG -- Estado da UC direto nos LEDs verdes;
		);

	-- SW17 escolhe o que aparece em HEX7 a HEX4: RDM ('0') ou saída da ULA ('1').
	displayMux: mux_2to1_16bits port map (SW(17), mdr, aluResult, displayValue);

	-- HEX3 a HEX0: valor do PC.
	hex0Decoder: seven_segment_decoder port map (pc(3 downto 0), HEX0);
	hex1Decoder: seven_segment_decoder port map (pc(7 downto 4), HEX1);
	hex2Decoder: seven_segment_decoder port map (pc(11 downto 8), HEX2);
	hex3Decoder: seven_segment_decoder port map (pc(15 downto 12), HEX3);

	-- HEX7 a HEX4: RDM ou saída da ULA.
	hex4Decoder: seven_segment_decoder port map (displayValue(3 downto 0), HEX4);
	hex5Decoder: seven_segment_decoder port map (displayValue(7 downto 4), HEX5);
	hex6Decoder: seven_segment_decoder port map (displayValue(11 downto 8), HEX6);
	hex7Decoder: seven_segment_decoder port map (displayValue(15 downto 12), HEX7);
end architecture logic;