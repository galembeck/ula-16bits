-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Código base: Projeto de Sistemas Digitais

-- Este arquivo contém o "package" do projeto, responsável pelo armazenamento e controle de
-- todos os componentes que serão utilizados na CPU: a Unidade Lógica e Aritmética (I), o
-- registrador de 16 bits (II), o banco de registradores (III), o controle da ULA (IV), os
-- extensores de sinal (V) e de zeros (VI), os multiplexadores (VII, VIII e IX) e o
-- decodificador de 7 segmentos (X), a memória (XI), o datapath (XII), a unidade de
-- controle (XIII), a CPU (XIV) e o debouncer (XV).


library ieee;
use ieee.std_logic_1164.all;

package components_list is
	-- Componente: Unidade Lógica e Aritmética de 16 bits (I)
	component arithmetic_logic_unit
		port (
			a, b : in std_logic_vector(15 downto 0); -- Entrada(s): operandos "a" e "b".
			aluOperation : in std_logic_vector(2 downto 0); -- Entrada: código da operação.
			result : out std_logic_vector(15 downto 0); -- Saída: resultado da operação.
			zero, overflow, carryOut : out std_logic -- Saída(s): sinais auxiliares.
		);
	end component arithmetic_logic_unit;

	-- Componente: Registrador de 16 bits com carga (II)
	component register_16bits
		port (
			clk, reset, load : in std_logic; -- Entrada(s): clock, reset e habilitação de escrita.
			d : in std_logic_vector(15 downto 0); -- Entrada: dado a ser armazenado.
			q : out std_logic_vector(15 downto 0) -- Saída: dado armazenado.
		);
	end component register_16bits;

	-- Componente: Banco de registradores (8 x 16 bits) (III)
	component register_bank
		port (
			clk, reset, regWrite : in std_logic; -- Entrada(s): clock, reset e habilitação de escrita.
			readRegister1, readRegister2 : in std_logic_vector(2 downto 0); -- Entrada(s): registradores lidos.
			writeRegister : in std_logic_vector(2 downto 0); -- Entrada: registrador escrito.
			writeData : in std_logic_vector(15 downto 0); -- Entrada: dado a ser escrito.
			readData1, readData2 : out std_logic_vector(15 downto 0) -- Saída(s): dados lidos.
		);
	end component register_bank;

	-- Componente: Controle da ULA (IV)
	component alu_control
		port (
			aluOp : in std_logic_vector(1 downto 0); -- Entrada: tipo de operação (vindo da UC).
			opcode : in std_logic_vector(3 downto 0); -- Entrada: opcode da instrução (vindo do RI).
			aluOperation : out std_logic_vector(2 downto 0) -- Saída: código de operação da ULA.
		);
	end component alu_control;

	-- Componente: Extensor de sinal 6 -> 16 bits (V)
	component sign_extend
		port (
			input : in std_logic_vector(5 downto 0); -- Entrada: imediato de 6 bits.
			output : out std_logic_vector(15 downto 0) -- Saída: imediato estendido.
		);
	end component sign_extend;

	-- Componente: Extensor de zeros 12 -> 16 bits (VI)
	component zero_extend
		port (
			input : in std_logic_vector(11 downto 0); -- Entrada: endereço de 12 bits.
			output : out std_logic_vector(15 downto 0) -- Saída: endereço estendido.
		);
	end component zero_extend;

	-- Componente: Multiplexador 2 -> 1 de 16 bits (VII)
	component mux_2to1_16bits
		port (
			sel : in std_logic; -- Entrada: seletor.
			input0, input1 : in std_logic_vector(15 downto 0); -- Entrada(s): opções 0 e 1.
			output : out std_logic_vector(15 downto 0) -- Saída: entrada escolhida.
		);
	end component mux_2to1_16bits;

	-- Componente: Multiplexador 3 -> 1 de 16 bits (VIII)
	component mux_3to1_16bits
		port (
			sel : in std_logic_vector(1 downto 0); -- Entrada: seletor.
			input0, input1, input2 : in std_logic_vector(15 downto 0); -- Entrada(s): opções 0, 1 e 2.
			output : out std_logic_vector(15 downto 0) -- Saída: entrada escolhida.
		);
	end component mux_3to1_16bits;

	-- Componente: Multiplexador 2 -> 1 de 3 bits (IX)
	component mux_2to1_3bits
		port (
			sel : in std_logic; -- Entrada: seletor.
			input0, input1 : in std_logic_vector(2 downto 0); -- Entrada(s): opções 0 e 1.
			output : out std_logic_vector(2 downto 0) -- Saída: entrada escolhida.
		);
	end component mux_2to1_3bits;

	-- Componente: Decodificador de 7 segmentos (X)
	component seven_segment_decoder
		port (
			input : in std_logic_vector(3 downto 0); -- Entrada: dígito hexadecimal (4 bits).
			segments : out std_logic_vector(6 downto 0) -- Saída: segmentos do display ("gfedcba").
		);
	end component seven_segment_decoder;

	-- Componente: Memória de 256 x 16 bits, inicializada por .mif (XI)
	component memory
		port (
			clk : in std_logic; -- Entrada: clock (usado apenas na escrita).
			memRead, memWrite : in std_logic; -- Entrada(s): habilitação de leitura e de escrita.
			address : in std_logic_vector(15 downto 0); -- Entrada: endereço (PC ou ALUOut).
			writeData : in std_logic_vector(15 downto 0); -- Entrada: dado a ser gravado.
			memData : out std_logic_vector(15 downto 0) -- Saída: dado lido da memória.
		);
	end component memory;

	-- Componente: Caminho de dados (datapath) (XII)
	component datapath
		port (
			clk, reset : in std_logic; -- Entrada(s): clock e reset.
			pcWrite, pcWriteCond, bne : in std_logic; -- Escrita do PC e tipo de desvio.
			iorD, memRead, memWrite, irWrite : in std_logic; -- Memória e RI.
			regSrc, memtoReg, regWrite : in std_logic; -- Banco de registradores.
			aluSrcA : in std_logic; -- 1º operando da ULA.
			aluSrcB, aluOp, pcSource : in std_logic_vector(1 downto 0); -- 2º operando, operação e novo PC.
			opcode : out std_logic_vector(3 downto 0); -- Opcode da instrução.
			pcOut, mdrOut, aluResultOut : out std_logic_vector(15 downto 0) -- PC, RDM e saída da ULA.
		);
	end component datapath;

	-- Componente: Unidade de controle (máquina de estados) (XIII)
	component control_unit
		port (
			clk, reset : in std_logic; -- Entrada(s): clock e reset.
			opcode : in std_logic_vector(3 downto 0); -- Entrada: opcode da instrução.
			pcWrite, pcWriteCond, bne : out std_logic; -- Escrita do PC e tipo de desvio.
			iorD, memRead, memWrite, irWrite : out std_logic; -- Memória e RI.
			regSrc, memtoReg, regWrite : out std_logic; -- Banco de registradores.
			aluSrcA : out std_logic; -- 1º operando da ULA.
			aluSrcB, aluOp, pcSource : out std_logic_vector(1 downto 0); -- 2º operando, operação e novo PC.
			stateLeds : out std_logic_vector(8 downto 0) -- Estado atual (um bit por estado).
		);
	end component control_unit;

	-- Componente: CPU (datapath + unidade de controle) (XIV)
	component cpu
		port (
			clk, reset : in std_logic; -- Entrada(s): clock e reset.
			pcOut, mdrOut, aluResultOut : out std_logic_vector(15 downto 0); -- Saída(s): PC, RDM e ULA.
			stateLeds : out std_logic_vector(8 downto 0) -- Saída: estado da unidade de controle.
		);
	end component cpu;

	-- Componente: Debouncer do botão de clock (XV)
	component debouncer
		port (
			clk : in std_logic; -- Entrada: clock de 50 MHz da placa.
			buttonIn : in std_logic; -- Entrada: botão com ruído.
			buttonOut : out std_logic -- Saída: botão sem ruído.
		);
	end component debouncer;
end package components_list;