-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Este arquivo contém o debouncer do botão usado como clock da CPU.

-- Quando um botão mecânico é apertado, o contato "trepida" por alguns milissegundos e o
-- sinal oscila várias vezes entre '0' e '1'. Sem o debouncer, cada oscilação seria uma
-- borda de clock, e a CPU avançaria vários ciclos em um único aperto.

-- Funcionamento: o debouncer usa o clock de 50 MHz da placa para observar o botão. A saída
-- só muda depois que a entrada ficar 10 ms seguidos com o mesmo valor (500.000 ciclos de
-- 20 ns). Qualquer oscilação nesse intervalo reinicia a contagem.

library ieee;
use ieee.std_logic_1164.all;

entity debouncer is
	port (
		clk : in std_logic; -- Entrada: clock de 50 MHz da placa (CLOCK_50).
		buttonIn : in std_logic; -- Entrada: botão com ruído ('1' = apertado).
		buttonOut : out std_logic -- Saída: botão sem ruído.
	);
end entity debouncer;

architecture logic of debouncer is
	constant DEBOUNCE_TIME : integer := 500000; -- 10 ms com clock de 50 MHz.

	signal stableValue : std_logic := '0'; -- Último valor estável do botão.
	signal counter : integer range 0 to DEBOUNCE_TIME := 0; -- Tempo com a entrada diferente.
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if buttonIn = stableValue then
				counter <= 0; -- Entrada igual à saída: nada muda, zera a contagem.
			elsif counter = DEBOUNCE_TIME then
				stableValue <= buttonIn; -- Entrada diferente por 10 ms: aceita o novo valor.
				counter <= 0;
			else
				counter <= counter + 1; -- Entrada diferente: continua contando.
			end if;
		end if;
	end process;

	buttonOut <= stableValue;
end architecture logic;