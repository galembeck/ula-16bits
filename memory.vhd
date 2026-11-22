-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Código base: exemplo de memória disponibilizado pelo professor (memória inicializada por .mif)

-- Este arquivo contém a memória da CPU: 256 posições de 16 bits cada, usada tanto para as
-- instruções do programa quanto para os dados (memória única, como no datapath multiciclo).

-- A memória é declarada como um vetor ("array") de 256 palavras de 16 bits. O atributo
-- "ram_init_file" indica ao Quartus o arquivo .mif que define o conteúdo inicial da
-- memória (o programa a ser testado e seus dados).

-- Funcionamento:
-- - LEITURA (combinacional/assíncrona): o dado da posição indicada por "address" aparece
--   em "memData" sempre que "memRead" = '1' (caso contrário, a saída fica zerada). Como a
--   leitura não depende do clock, a instrução já está disponível no mesmo ciclo da busca, e
--   o RI (ou o RDM) a guarda na borda do clock, exatamente como no datapath do livro.
-- - ESCRITA (síncrona): na borda de subida do clock, se "memWrite" = '1', o valor de
--   "writeData" é gravado na posição indicada por "address" (usado pela instrução ST).

-- Observações importantes:
-- - Como a memória tem 256 posições, apenas os 8 bits menos significativos do endereço
--   (address(7 downto 0)) são utilizados. O PC e o ALUOut têm 16 bits, mas os programas de
--   teste ficam dentro dos endereços 0 a 255.
-- - O atributo "ram_init_file" é lido apenas pelo Quartus (síntese). Em uma simulação RTL
--   direta (ModelSim com o .vhd), o conteúdo do .mif não é carregado.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Biblioteca com o tipo "unsigned" e a função "to_integer".

entity memory is
	port (
		clk : in std_logic; -- Entrada: clock (usado apenas na escrita).
		memRead, memWrite : in std_logic; -- Entrada(s): habilitação de leitura e de escrita.
		address : in std_logic_vector(15 downto 0); -- Entrada: endereço (PC ou ALUOut).
		writeData : in std_logic_vector(15 downto 0); -- Entrada: dado a ser gravado (registrador B).
		memData : out std_logic_vector(15 downto 0) -- Saída: dado lido da memória.
	);
end entity memory;

architecture logic of memory is
	-- Tipo da memória: vetor de 256 posições (0 a 255), cada uma com 16 bits.
	type memory_type is array (0 to 255) of std_logic_vector(15 downto 0);
	signal ram : memory_type;

	-- Carregamento do conteúdo inicial da memória a partir do arquivo .mif.
	attribute ram_init_file : string;
	attribute ram_init_file of ram : signal is "program_1.mif";

	signal ramAddress : integer range 0 to 255; -- Endereço convertido para inteiro (8 bits).
begin
	-- Conversão dos 8 bits menos significativos do endereço para inteiro (índice do vetor).
	ramAddress <= to_integer(unsigned(address(7 downto 0)));

	-- Escrita síncrona: só grava na borda de subida do clock, quando "memWrite" = '1'.
	process(clk)
	begin
		if rising_edge(clk) then
			if memWrite = '1' then
				ram(ramAddress) <= writeData;
			end if;
		end if;
	end process;

	-- Leitura assíncrona: o dado da posição endereçada aparece direto na saída.
	memData <= ram(ramAddress) when memRead = '1' else x"0000";
end architecture logic;