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
-- - O atributo "ram_init_file" é lido apenas pelo Quartus (síntese). Para a simulação RTL
--   (ModelSim), existe a função "load_mif", que lê o mesmo arquivo .mif com a biblioteca
--   textio. Ela fica entre "synthesis translate_off/on", ou seja, o Quartus a ignora e ela
--   só existe na simulação. Ela aceita o formato usado em program_1.mif: endereços em
--   decimal (ADDRESS_RADIX = DEC), dados em hexadecimal (DATA_RADIX = HEX), linhas
--   "end : dado;" e intervalos "[ini..fim] : dado;".

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Biblioteca com o tipo "unsigned" e a função "to_integer".
-- #simulacao modelsim
-- synthesis translate_off
use std.textio.all; -- Leitura de arquivos texto (apenas na simulação, para ler o .mif).
-- synthesis translate_on

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

	-- synthesis translate_off
	-- #simulacao modelsim
	-- Converte um caractere hexadecimal em inteiro (-1 se não for hexadecimal).
	function hex_value(c : character) return integer is
	begin
		case c is
			when '0' to '9' => return character'pos(c) - character'pos('0');
			when 'A' to 'F' => return character'pos(c) - character'pos('A') + 10;
			when 'a' to 'f' => return character'pos(c) - character'pos('a') + 10;
			when others => return -1;
		end case;
	end function;

	-- #simulacao modelsim
	-- Lê o arquivo .mif e devolve o conteúdo inicial da memória (apenas na simulação).
	-- Procura o arquivo na pasta atual do ModelSim e em até duas pastas acima.
	impure function load_mif return memory_type is
		constant FILE_NAME : string := "program_1.mif";
		file mifFile : text;
		variable status : file_open_status;
		variable fileLine : line;
		variable result : memory_type := (others => (others => '0'));
		variable p, first, last, value : integer;
	begin
		file_open(status, mifFile, FILE_NAME, read_mode);
		if status /= open_ok then
			file_open(status, mifFile, "../" & FILE_NAME, read_mode);
		end if;
		if status /= open_ok then
			file_open(status, mifFile, "../../" & FILE_NAME, read_mode);
		end if;
		if status /= open_ok then
			report "memory: arquivo " & FILE_NAME & " nao encontrado; memoria zerada." severity warning;
			return result;
		end if;

		while not endfile(mifFile) loop
			readline(mifFile, fileLine);
			if fileLine'length > 0 then
				p := fileLine'low;
				-- Pula espaços e tabulações do início da linha.
				while p <= fileLine'high and (fileLine(p) = ' ' or fileLine(p) = HT) loop
					p := p + 1;
				end loop;

				first := -1;
				if p <= fileLine'high and fileLine(p) = '[' then
					-- Intervalo: [ini..fim]
					p := p + 1;
					first := 0;
					while p <= fileLine'high and fileLine(p) >= '0' and fileLine(p) <= '9' loop
						first := first * 10 + hex_value(fileLine(p));
						p := p + 1;
					end loop;
					while p <= fileLine'high and fileLine(p) = '.' loop
						p := p + 1;
					end loop;
					last := 0;
					while p <= fileLine'high and fileLine(p) >= '0' and fileLine(p) <= '9' loop
						last := last * 10 + hex_value(fileLine(p));
						p := p + 1;
					end loop;
				elsif p <= fileLine'high and fileLine(p) >= '0' and fileLine(p) <= '9' then
					-- Endereço único (decimal).
					first := 0;
					while p <= fileLine'high and fileLine(p) >= '0' and fileLine(p) <= '9' loop
						first := first * 10 + hex_value(fileLine(p));
						p := p + 1;
					end loop;
					last := first;
				end if;
				-- Linhas de cabeçalho, comentários, BEGIN e END são ignoradas (first = -1).

				if first >= 0 then
					-- Avança até o ':' e lê o dado em hexadecimal.
					while p <= fileLine'high and fileLine(p) /= ':' loop
						p := p + 1;
					end loop;
					p := p + 1;
					while p <= fileLine'high and (fileLine(p) = ' ' or fileLine(p) = HT) loop
						p := p + 1;
					end loop;
					value := 0;
					while p <= fileLine'high and hex_value(fileLine(p)) >= 0 loop
						value := value * 16 + hex_value(fileLine(p));
						p := p + 1;
					end loop;
					for i in first to last loop
						if i >= 0 and i <= 255 then
							result(i) := std_logic_vector(to_unsigned(value, 16));
						end if;
					end loop;
				end if;
			end if;
		end loop;

		file_close(mifFile);
		return result;
	end function;
	-- synthesis translate_on
begin
	-- Conversão dos 8 bits menos significativos do endereço para inteiro (índice do vetor).
	ramAddress <= to_integer(unsigned(address(7 downto 0)));

	-- Escrita síncrona: só grava na borda de subida do clock, quando "memWrite" = '1'.
	process(clk)
		-- #simulacao modelsim
		-- synthesis translate_off
		variable loaded : boolean := false;
		-- synthesis translate_on
	begin
		-- #simulacao modelsim
		-- synthesis translate_off
		-- Apenas na simulação: carrega o .mif uma única vez, no início (tempo 0).
		if not loaded then
			ram <= load_mif;
			loaded := true;
		end if;
		-- synthesis translate_on

		if rising_edge(clk) then
			if memWrite = '1' then
				ram(ramAddress) <= writeData;
			end if;
		end if;
	end process;

	-- Leitura assíncrona: o dado da posição endereçada aparece direto na saída.
	memData <= ram(ramAddress) when memRead = '1' else x"0000";
end architecture logic;