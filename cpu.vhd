-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Este arquivo contém a CPU completa: a união do caminho de dados (datapath) com a unidade
-- de controle. A unidade de controle recebe o opcode do RI e devolve os sinais de controle
-- que comandam o datapath a cada ciclo.

-- Saídas (para a placa ou para a simulação):
-- - pcOut        -> valor do PC;
-- - mdrOut       -> valor lido da memória (RDM);
-- - aluResultOut -> saída da ULA;
-- - stateLeds    -> estado atual da unidade de controle (um bit por estado).

library ieee;
use ieee.std_logic_1164.all;

use work.components_list.all;

entity cpu is
	port (
		clk, reset : in std_logic; -- Entrada(s): clock e reset.
		pcOut, mdrOut, aluResultOut : out std_logic_vector(15 downto 0); -- Saída(s): PC, RDM e ULA.
		stateLeds : out std_logic_vector(8 downto 0) -- Saída: estado da unidade de controle.
	);
end entity cpu;

architecture logic of cpu is
	-- Opcode da instrução (do datapath para a unidade de controle).
	signal opcode : std_logic_vector(3 downto 0);

	-- Sinais de controle (da unidade de controle para o datapath).
	signal pcWrite, pcWriteCond, bne : std_logic;
	signal iorD, memRead, memWrite, irWrite : std_logic;
	signal regSrc, memtoReg, regWrite : std_logic;
	signal aluSrcA : std_logic;
	signal aluSrcB, aluOp, pcSource : std_logic_vector(1 downto 0);
begin
	-- Instanciamento da unidade de controle.
	controlUnitInstance: control_unit
		port map (
			clk => clk, reset => reset, opcode => opcode,
			pcWrite => pcWrite, pcWriteCond => pcWriteCond, bne => bne,
			iorD => iorD, memRead => memRead, memWrite => memWrite, irWrite => irWrite,
			regSrc => regSrc, memtoReg => memtoReg, regWrite => regWrite,
			aluSrcA => aluSrcA, aluSrcB => aluSrcB, aluOp => aluOp, pcSource => pcSource,
			stateLeds => stateLeds
		);

	-- Instanciamento do caminho de dados.
	datapathInstance: datapath
		port map (
			clk => clk, reset => reset,
			pcWrite => pcWrite, pcWriteCond => pcWriteCond, bne => bne,
			iorD => iorD, memRead => memRead, memWrite => memWrite, irWrite => irWrite,
			regSrc => regSrc, memtoReg => memtoReg, regWrite => regWrite,
			aluSrcA => aluSrcA, aluSrcB => aluSrcB, aluOp => aluOp, pcSource => pcSource,
			opcode => opcode,
			pcOut => pcOut, mdrOut => mdrOut, aluResultOut => aluResultOut
		);
end architecture logic;