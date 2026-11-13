-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Código base: Projeto de Sistemas Digitais

-- Integrantes:
-- - Pedro Henrique Galembeck - 24005794;
-- - Beatriz Bistaffa Vitor - 24003635;
-- - Lorena villagelin - 24005273;
-- - Cecília Gontijo Veloso Teixeira Roque - 24003203;
-- - Cauan Figueiredo Braga - 24787038;

-- Este arquivo contém a Unidade Lógica e Aritmética (ULA) de 16 bits da CPU. Ela é
-- responsável por executar as operações necessárias para TODAS as instruções do projeto:
-- - ADD, ADDI      -> soma (a + b);
-- - LD, ST         -> soma para calcular o endereço (Rj + imediato);
-- - SUB            -> subtração (a - b);
-- - AND, OR        -> operações lógicas bit a bit;
-- - SLT            -> "set if less than": result = 1 se a < b (com sinal), senão 0;
-- - BEQ, BNE       -> subtração (Ri - Rj) e uso do sinal "zero" para decidir o salto.
-- Além disso, a ULA também é usada na busca (PC + 1) e na decodificação (PC + imediato).

-- Códigos de operação da ULA (aluOperation), seguindo o padrão do livro (Patterson & Hennessy):
-- - "000" -> AND
-- - "001" -> OR
-- - "010" -> ADD
-- - "110" -> SUB
-- - "111" -> SLT
-- O bit mais significativo (aluOperation(2)) funciona como "bInvert": quando vale '1', a
-- ULA inverte "b" e soma 1 (carry-in = '1'), ou seja, faz a + (b' + 1) = a - b (complemento
-- de dois). Assim, uma ÚNICA soma é usada tanto para ADD quanto para SUB e SLT.

-- Observações importantes:
-- - A saída "zero" será '1' quando result = 0x0000, caso contrário será '0'.
-- - A saída "overflow" será '1' quando ocorrer overflow na soma ou subtração (com sinal).
-- - A saída "carryOut" será o carry-out da soma nas operações de ADD e SUB.
-- - Os operandos são tratados como números com sinal (complemento de dois), já que o
--   imediato pode ser positivo ou negativo.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Biblioteca com os tipos "unsigned" e o operador "+".

entity arithmetic_logic_unit is
	port (
		a, b : in std_logic_vector(15 downto 0); -- Entrada(s): operandos "a" e "b" (16 bits).
		aluOperation : in std_logic_vector(2 downto 0); -- Entrada: código da operação.
		result : out std_logic_vector(15 downto 0); -- Saída: resultado da operação (16 bits).
		zero, overflow, carryOut : out std_logic -- Saída(s): sinais auxiliares.
	);
end entity arithmetic_logic_unit;

architecture logic of arithmetic_logic_unit is
	signal bInvert : std_logic; -- Indica se "b" deve ser invertido (subtração).
	signal bOperand : std_logic_vector(15 downto 0); -- "b" ou "NOT b", que entra na soma.
	signal cinVector : std_logic_vector(16 downto 0); -- Carry-in (bInvert) estendido para 17 bits.
	signal adderResult : std_logic_vector(16 downto 0); -- Soma com 17 bits (bit 16 = carry-out).

	signal sumResult, -- Resultado da soma (a + b ou a - b).
			 andResult, -- Resultado do AND.
			 orResult, -- Resultado do OR.
			 sltResult, -- Resultado do SLT.
			 selectedResult : std_logic_vector(15 downto 0); -- Resultado escolhido pelo "with-select".

	signal coutAdder : std_logic; -- Carry-out da soma.
	signal overflowAdder : std_logic; -- Overflow (com sinal) da soma.
	signal less : std_logic; -- '1' quando a < b (com sinal).
begin
	-- O bit 2 do código de operação indica se a operação é de subtração (SUB ou SLT).
	bInvert <= aluOperation(2);

	-- Seleção do segundo operando da soma: "b" normal (soma) ou "b" invertido (subtração).
	bOperand <= (NOT b) when bInvert = '1' else b;

	-- Implementação da soma de 16 bits: a + bOperand + bInvert.
	-- Os operandos são estendidos para 17 bits (com '0' à esquerda) para que o bit 16 do
	-- resultado guarde o carry-out. O "bInvert" entra como carry-in, somando o +1 que
	-- completa o complemento de dois na subtração: a + (b' + 1).
	cinVector <= "0000000000000000" & bInvert;
	adderResult <= std_logic_vector(unsigned('0' & a) + unsigned('0' & bOperand) + unsigned(cinVector));

	sumResult <= adderResult(15 downto 0); -- Resultado da soma (16 bits).
	coutAdder <= adderResult(16); -- Carry-out da soma.

	-- Implementação das operações lógicas feitas diretamente na arquitetura da ULA.
	andResult <= a AND b;
	orResult <= a OR b;

	-- Overflow (com sinal): ocorre quando os dois operandos que entram na soma têm o
	-- mesmo sinal, mas o resultado tem sinal diferente. Na subtração, o operando usado
	-- é o "b" invertido (bOperand), por isso a mesma expressão serve para os dois casos.
	overflowAdder <= '1' when ((a(15) XOR bOperand(15)) = '0' AND (a(15) XOR sumResult(15)) = '1') else '0';

	-- SLT: a < b se o resultado de (a - b) for negativo. Porém, se houver overflow, o bit
	-- de sinal do resultado fica "errado", então ele deve ser invertido (XOR com overflow).
	less <= sumResult(15) XOR overflowAdder;
	sltResult <= "000000000000000" & less; -- Resultado do SLT: 0x0001 ou 0x0000.

	-- Saída principal ("result") da Unidade Lógica e Aritmética (ULA).
	with aluOperation select
		selectedResult <=
			andResult when "000", -- AND
			orResult when "001", -- OR
			sumResult when "010", -- ADD
			sumResult when "110", -- SUB
			sltResult when "111", -- SLT
			x"0000" when others; -- Códigos não utilizados

	result <= selectedResult;

	-- Sinal "zero" indica se o resultado é zero (usado pelo BEQ e BNE).
	-- É utilizado o sinal interno "selectedResult", pois uma porta "out" não pode ser lida.
	zero <= '1' when selectedResult = x"0000" else '0';

	-- Sinal "carryOut" indica o carry-out das operações de soma ou subtração.
	carryOut <= coutAdder when (aluOperation = "010" OR aluOperation = "110") else '0';

	-- Sinal "overflow" indica se ocorreu overflow na soma ou subtração.
	overflow <= overflowAdder when (aluOperation = "010" OR aluOperation = "110") else '0';
end architecture logic;