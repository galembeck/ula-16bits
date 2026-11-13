-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Código base: Projeto de Sistemas Digitais

-- Integrantes:
-- - Pedro Henrique Galembeck - 24005794;
-- - Beatriz Bistaffa Vitor - 24003635;
-- - Lorena villagelin - 24005273;
-- - Cecília Gontijo Veloso Teixeira Roque - 24003203;
-- - Cauan Figueiredo Braga - 24787038;

-- Este arquivo contém o "package" do projeto, responsável pelo armazenamento e controle de
-- todos os componentes que serão utilizados na CPU: a Unidade Lógica e Aritmética (I), o
-- registrador de 16 bits (II), o banco de registradores (III), o controle da ULA (IV), os
-- extensores de sinal (V) e de zeros (VI) e os multiplexadores (VII, VIII e IX).

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
end package components_list;