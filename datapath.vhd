-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Este arquivo contém o caminho de dados (datapath) da CPU multiciclo, baseado no datapath
-- multiciclo de Patterson & Hennessy e adaptado às instruções do projeto. Ele apenas LIGA
-- os componentes entre si, exatamente como no diagrama do caminho de dados:

-- PC -> mux IorD -> memória -> RI / RDM -> banco de registradores -> A / B ->
-- muxes ALUSrcA / ALUSrcB -> ULA -> ALUOut -> mux PCSource -> PC

-- Todos os sinais de controle (PCWrite, IorD, MemRead, ALUOp etc.) são ENTRADAS deste
-- arquivo: quem decide o valor de cada um, a cada ciclo, é a unidade de controle.

-- Registradores internos e quando são escritos:
-- - PC     -> quando pcEn = PCWrite OR (PCWriteCond AND (Zero XOR BNE));
-- - RI     -> quando IRWrite = '1' (busca);
-- - RDM    -> quando MemRead = '1' (guarda o último valor lido da memória);
-- - A, B   -> em todo ciclo (valores lidos do banco de registradores);
-- - ALUOut -> em todo ciclo (resultado da ULA, usado no ciclo seguinte).

-- Campos da instrução (RI):
-- - [15-12] opcode | [11-9] Ri | [8-6] Rj | [5-3] Rk | [5-0] imediato | [11-0] end

library ieee;
use ieee.std_logic_1164.all;

use work.components_list.all;

entity datapath is
	port (
		clk, reset : in std_logic; -- Entrada(s): clock e reset.

		-- Sinais de controle (vindos da unidade de controle).
		pcWrite, pcWriteCond, bne : in std_logic; -- Escrita do PC e tipo de desvio.
		iorD, memRead, memWrite, irWrite : in std_logic; -- Memória e RI.
		regSrc, memtoReg, regWrite : in std_logic; -- Banco de registradores.
		aluSrcA : in std_logic; -- 1º operando da ULA.
		aluSrcB, aluOp, pcSource : in std_logic_vector(1 downto 0); -- 2º operando, operação e novo PC.

		-- Saídas para a unidade de controle e para a placa.
		opcode : out std_logic_vector(3 downto 0); -- Opcode da instrução (RI[15-12]).
		pcOut, mdrOut, aluResultOut : out std_logic_vector(15 downto 0) -- PC, RDM e saída da ULA.
	);
end entity datapath;

architecture logic of datapath is
	-- Registradores internos.
	signal pc, instruction, mdr, aRegister, bRegister, aluOut : std_logic_vector(15 downto 0);

	-- Fios do caminho de dados.
	signal nextPc : std_logic_vector(15 downto 0); -- Saída do mux PCSource.
	signal memAddress : std_logic_vector(15 downto 0); -- Saída do mux IorD.
	signal memData : std_logic_vector(15 downto 0); -- Dado lido da memória.
	signal readRegister2 : std_logic_vector(2 downto 0); -- Saída do mux RegSrc (Rk ou Ri).
	signal registerWriteData : std_logic_vector(15 downto 0); -- Saída do mux MemtoReg.
	signal readData1, readData2 : std_logic_vector(15 downto 0); -- Saídas do banco.
	signal signExtended, jumpAddress : std_logic_vector(15 downto 0); -- Saídas dos extensores.
	signal aluInputA, aluInputB : std_logic_vector(15 downto 0); -- Saídas dos muxes da ULA.
	signal aluOperation : std_logic_vector(2 downto 0); -- Saída do controle da ULA.
	signal aluResult : std_logic_vector(15 downto 0); -- Saída da ULA.
	signal zero, overflow, carryOut : std_logic; -- Sinais auxiliares da ULA.

	signal branchCondition, pcEn : std_logic; -- Lógica de escrita do PC.
begin
	-- Lógica de escrita do PC: escrita incondicional (busca e JMP) ou condicional (BEQ/BNE).
	-- No BEQ (bne = '0') desvia se Zero = '1'; no BNE (bne = '1') desvia se Zero = '0'.
	branchCondition <= zero XOR bne;
	pcEn <= pcWrite OR (pcWriteCond AND branchCondition);

	pcRegister: register_16bits port map (clk, reset, pcEn, nextPc, pc);

	-- Mux IorD: endereço da memória = PC (instrução) ou ALUOut (dado do LD/ST).
	iorDMux: mux_2to1_16bits port map (iorD, pc, aluOut, memAddress);

	-- Memória única (instruções + dados). O dado escrito (ST) vem do registrador B (Ri).
	memoryInstance: memory
		port map (
			clk => clk, -- Clock da CPU;
			memRead => memRead, -- Habilitação de leitura;
			memWrite => memWrite, -- Habilitação de escrita;
			address => memAddress, -- Endereço (PC ou ALUOut);
			writeData => bRegister, -- Dado a gravar (Ri, no ST);
			memData => memData -- Dado lido;
		);

	-- RI: guarda a instrução lida na busca. RDM: guarda o último dado lido da memória.
	instructionRegister: register_16bits port map (clk, reset, irWrite, memData, instruction);
	mdrRegister: register_16bits port map (clk, reset, memRead, memData, mdr);

	-- Mux RegSrc: registrador de leitura 2 = Rk (tipo R) ou Ri (ST, BEQ e BNE).
	regSrcMux: mux_2to1_3bits port map (regSrc, instruction(5 downto 3), instruction(11 downto 9), readRegister2);

	-- Mux MemtoReg: dado escrito no banco = ALUOut (tipo R, ADDI) ou RDM (LD).
	memtoRegMux: mux_2to1_16bits port map (memtoReg, aluOut, mdr, registerWriteData);

	registerBankInstance: register_bank
		port map (
			clk => clk, -- Clock da CPU;
			reset => reset, -- Reset;
			regWrite => regWrite, -- Habilitação de escrita;
			readRegister1 => instruction(8 downto 6), -- Leitura 1: Rj;
			readRegister2 => readRegister2, -- Leitura 2: Rk ou Ri;
			writeRegister => instruction(11 downto 9), -- Escrita: sempre Ri;
			writeData => registerWriteData, -- Dado a escrever;
			readData1 => readData1, -- Valor de Rj;
			readData2 => readData2 -- Valor de Rk ou Ri;
		);

	-- Registradores A e B: guardam os valores lidos do banco (escritos em todo ciclo).
	aRegisterInstance: register_16bits port map (clk, reset, '1', readData1, aRegister);
	bRegisterInstance: register_16bits port map (clk, reset, '1', readData2, bRegister);

	signExtendInstance: sign_extend port map (instruction(5 downto 0), signExtended); -- Imediato.
	zeroExtendInstance: zero_extend port map (instruction(11 downto 0), jumpAddress); -- Endereço do JMP.

	-- Mux ALUSrcA: 1º operando = PC (busca e decodificação) ou A (execução).
	aluSrcAMux: mux_2to1_16bits port map (aluSrcA, pc, aRegister, aluInputA);

	-- Mux ALUSrcB: 2º operando = B, constante 1 (PC + 1) ou imediato estendido.
	aluSrcBMux: mux_3to1_16bits port map (aluSrcB, bRegister, x"0001", signExtended, aluInputB);

	aluControlInstance: alu_control port map (aluOp, instruction(15 downto 12), aluOperation);

	aluInstance: arithmetic_logic_unit
		port map (
			a => aluInputA, -- 1º operando;
			b => aluInputB, -- 2º operando;
			aluOperation => aluOperation, -- Código da operação;
			result => aluResult, -- Resultado;
			zero => zero, -- Resultado igual a zero (BEQ/BNE);
			overflow => overflow, -- Overflow (não utilizado pela CPU);
			carryOut => carryOut -- Carry-out (não utilizado pela CPU);
		);

	-- ALUOut: guarda o resultado da ULA para o ciclo seguinte (escrito em todo ciclo).
	aluOutRegister: register_16bits port map (clk, reset, '1', aluResult, aluOut);

	-- Mux PCSource: novo PC = saída da ULA (PC + 1), ALUOut (alvo do desvio) ou endereço do JMP.
	pcSourceMux: mux_3to1_16bits port map (pcSource, aluResult, aluOut, jumpAddress, nextPc);

	opcode <= instruction(15 downto 12); -- Para a unidade de controle e o controle da ULA.
	pcOut <= pc; -- Para os displays HEX0 a HEX3.
	mdrOut <= mdr; -- Para os displays HEX4 a HEX7 (SW17 = '0').
	aluResultOut <= aluResult; -- Para os displays HEX4 a HEX7 (SW17 = '1').
end architecture logic;