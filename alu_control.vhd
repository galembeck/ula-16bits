-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Integrantes:
-- - Pedro Henrique Galembeck - 24005794;
-- - Beatriz Bistaffa Vitor - 24003635;
-- - Lorena villagelin - 24005273;
-- - Cecília Gontijo Veloso Teixeira Roque - 24003203;
-- - Cauan Figueiredo Braga - 24787038;

-- Este arquivo contém o Controle da ULA, responsável por gerar o código de operação da ULA
-- ("aluOperation") a partir de dois sinais:
-- - "aluOp" (2 bits), que vem da Unidade de Controle;
-- - "opcode" (4 bits), que vem do RI (bits 15 a 12 da instrução).

-- Funcionamento:
-- - aluOp = "00" -> a ULA SOMA (busca: PC + 1 | decodificação: PC + imediato |
-- ADDI, LD e ST: Rj + imediato);
-- - aluOp = "01" -> a ULA SUBTRAI (BEQ e BNE: Ri - Rj, para gerar o sinal "zero");
-- - aluOp = "10" -> a operação depende do opcode (instruções do tipo R).

-- Opcodes do tipo R utilizados no projeto:
-- - "0000" -> ADD | "0001" -> SUB | "0010" -> AND | "0011" -> OR | "0100" -> SLT

-- Códigos de operação da ULA (aluOperation):
-- - "000" -> AND | "001" -> OR | "010" -> ADD | "110" -> SUB | "111" -> SLT

library ieee;
use ieee.std_logic_1164.all;

entity alu_control is
	port (
		aluOp : in std_logic_vector(1 downto 0); -- Entrada: tipo de operação (vindo da UC).
		opcode : in std_logic_vector(3 downto 0); -- Entrada: opcode da instrução (vindo do RI).
		aluOperation : out std_logic_vector(2 downto 0) -- Saída: código de operação da ULA.
	);
end entity alu_control;

architecture logic of alu_control is
	signal rTypeOperation : std_logic_vector(2 downto 0); -- Operação das instruções do tipo R.
begin
	-- Decodificação do opcode das instruções do tipo R para o código da ULA.
	with opcode select
		rTypeOperation <=
			"010" when "0000", -- ADD
			"110" when "0001", -- SUB
			"000" when "0010", -- AND
			"001" when "0011", -- OR
			"111" when "0100", -- SLT
			"010" when others; -- Não é do tipo R (não deve ocorrer com aluOp = "10")

	-- Seleção final do código de operação da ULA com base no "aluOp".
	with aluOp select
		aluOperation <=
			"010" when "00", -- Soma
			"110" when "01", -- Subtração
			rTypeOperation when "10", -- Definido pelo opcode (tipo R)
			"010" when others; -- Código não utilizado (soma por padrão)
end architecture logic;