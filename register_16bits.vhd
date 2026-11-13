-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Integrantes:
-- - Pedro Henrique Galembeck - 24005794;
-- - Beatriz Bistaffa Vitor - 24003635;
-- - Lorena villagelin - 24005273;
-- - Cecília Gontijo Veloso Teixeira Roque - 24003203;
-- - Cauan Figueiredo Braga - 24787038;

-- Este arquivo contém a implementação de um registrador de 16 bits com sinal de carga
-- ("load"). Ele é o bloco básico de armazenamento da CPU e será reutilizado em vários
-- pontos do datapath: PC, RI, RDM, A, B, ALUOut e cada um dos 8 registradores do banco.

-- Funcionamento:
-- - "reset" = '1' -> o registrador é zerado imediatamente (reset assíncrono).
-- - Na borda de subida do clock ("rising_edge"), se "load" = '1', o valor de "d" é
--   copiado para "q". Se "load" = '0', o registrador mantém o valor anterior.

-- Diferente da ULA (circuito combinacional), o registrador é um circuito SEQUENCIAL: a
-- saída depende do valor guardado, e só muda no momento da borda do clock. Por isso ele
-- é descrito com um "process" sensível ao "clk" e ao "reset".

library ieee;
use ieee.std_logic_1164.all;

entity register_16bits is
	port (
		clk, reset, load : in std_logic; -- Entrada(s): clock, reset e habilitação de escrita.
		d : in std_logic_vector(15 downto 0); -- Entrada: dado a ser armazenado.
		q : out std_logic_vector(15 downto 0) -- Saída: dado armazenado.
	);
end entity register_16bits;

architecture logic of register_16bits is
begin
	process(clk, reset)
	begin
		if reset = '1' then
			q <= x"0000"; -- Reset: zera o registrador.
		elsif rising_edge(clk) then
			if load = '1' then
				q <= d; -- Borda de subida com "load" ativo: guarda o novo valor.
			end if;
		end if;
	end process;
end architecture logic;