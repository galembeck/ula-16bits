-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Este arquivo contém a unidade de controle da CPU: uma máquina de estados (FSM) que, a cada
-- borda de subida do clock, muda de estado e, em cada estado, ativa os sinais que comandam
-- o datapath naquele ciclo. A transição depende do estado atual e do opcode da instrução.

-- Estados (cada um acende um LED verde na placa):
--  #  Estado          LED    O que faz
--  0  FETCH           LEDG0  RI <- Mem[PC]; PC <- PC + 1                      (todas)
--  1  DECODE          LEDG1  A <- Rj; B <- Rk ou Ri; ALUOut <- PC + imediato  (todas)
--  2  ADDRESS         LEDG2  ALUOut <- A + imediato                           (ADDI, LD, ST)
--  3  MEMORY_READ     LEDG3  RDM <- Mem[ALUOut]                               (LD)
--  4  MEMORY_WRITE    LEDG4  Mem[ALUOut] <- B                                 (ST)
--  5  EXECUTE         LEDG5  ALUOut <- A op B                                 (tipo R)
--  6  WRITE_BACK      LEDG6  Ri <- ALUOut (tipo R, ADDI) ou Ri <- RDM (LD)
--  7  BRANCH          LEDG7  A - B; se a condição for verdadeira: PC <- ALUOut (BEQ, BNE)
--  8  JUMP            LEDG8  PC <- end                                        (JMP)

-- Caminho de cada instrução (número de ciclos):
-- - Tipo R:   FETCH -> DECODE -> EXECUTE -> WRITE_BACK             (4 ciclos)
-- - ADDI:     FETCH -> DECODE -> ADDRESS -> WRITE_BACK             (4 ciclos)
-- - LD:       FETCH -> DECODE -> ADDRESS -> MEMORY_READ -> WRITE_BACK (5 ciclos)
-- - ST:       FETCH -> DECODE -> ADDRESS -> MEMORY_WRITE           (4 ciclos)
-- - BEQ, BNE: FETCH -> DECODE -> BRANCH                            (3 ciclos)
-- - JMP:      FETCH -> DECODE -> JUMP                              (3 ciclos)
-- Ao final, a máquina sempre volta para FETCH (próxima instrução).

library ieee;
use ieee.std_logic_1164.all;

entity control_unit is
	port (
		clk, reset : in std_logic; -- Entrada(s): clock e reset.
		opcode : in std_logic_vector(3 downto 0); -- Entrada: opcode da instrução (RI[15-12]).

		-- Sinais de controle (saídas para o datapath).
		pcWrite, pcWriteCond, bne : out std_logic; -- Escrita do PC e tipo de desvio.
		iorD, memRead, memWrite, irWrite : out std_logic; -- Memória e RI.
		regSrc, memtoReg, regWrite : out std_logic; -- Banco de registradores.
		aluSrcA : out std_logic; -- 1º operando da ULA.
		aluSrcB, aluOp, pcSource : out std_logic_vector(1 downto 0); -- 2º operando, operação e novo PC.

		stateLeds : out std_logic_vector(8 downto 0) -- Saída: estado atual (um bit por estado).
	);
end entity control_unit;

architecture logic of control_unit is
	-- Tipo enumerado com os 9 estados da máquina.
	type state_type is (FETCH, DECODE, ADDRESS, MEMORY_READ, MEMORY_WRITE,
	                    EXECUTE, WRITE_BACK, BRANCH, JUMP);
	signal currentState : state_type; -- Estado atual.

	-- Opcodes utilizados nas transições.
	constant OP_ADDI : std_logic_vector(3 downto 0) := "0101";
	constant OP_LD   : std_logic_vector(3 downto 0) := "0110";
	constant OP_ST   : std_logic_vector(3 downto 0) := "0111";
	constant OP_BEQ  : std_logic_vector(3 downto 0) := "1000";
	constant OP_BNE  : std_logic_vector(3 downto 0) := "1001";
	constant OP_JMP  : std_logic_vector(3 downto 0) := "1010";
begin
	-- A cada borda de subida do clock, a máquina vai para o próximo estado.
	process(clk, reset)
	begin
		if reset = '1' then
			currentState <= FETCH; -- Reset: começa buscando a instrução do endereço 0.
		elsif rising_edge(clk) then
			case currentState is
				when FETCH =>
					currentState <= DECODE;

				when DECODE =>
					case opcode is
						when "0000" | "0001" | "0010" | "0011" | "0100" =>
							currentState <= EXECUTE; -- ADD, SUB, AND, OR, SLT
						when OP_ADDI | OP_LD | OP_ST =>
							currentState <= ADDRESS; -- ADDI, LD, ST
						when OP_BEQ | OP_BNE =>
							currentState <= BRANCH; -- BEQ, BNE
						when OP_JMP =>
							currentState <= JUMP; -- JMP
						when others =>
							currentState <= FETCH; -- Opcode inválido: ignora a instrução
					end case;

				when ADDRESS =>
					if opcode = OP_LD then
						currentState <= MEMORY_READ; -- LD: lê a memória
					elsif opcode = OP_ST then
						currentState <= MEMORY_WRITE; -- ST: grava na memória
					else
						currentState <= WRITE_BACK; -- ADDI: grava o resultado em Ri
					end if;

				when MEMORY_READ =>
					currentState <= WRITE_BACK;

				when EXECUTE =>
					currentState <= WRITE_BACK;

				when others =>
					currentState <= FETCH; -- MEMORY_WRITE, WRITE_BACK, BRANCH e JUMP: fim da instrução
			end case;
		end if;
	end process;

	process(currentState, opcode)
	begin
		-- Valores padrão: nada é escrito e a ULA soma.
		pcWrite <= '0';
		pcWriteCond <= '0';
		bne <= '0';
		iorD <= '0';
		memRead <= '0';
		memWrite <= '0';
		irWrite <= '0';
		memtoReg <= '0';
		regWrite <= '0';
		aluSrcA <= '0';
		aluSrcB <= "00";
		aluOp <= "00";
		pcSource <= "00";

		case currentState is
			when FETCH => -- RI <- Mem[PC]; PC <- PC + 1
				memRead <= '1';
				irWrite <= '1';
				aluSrcA <= '0'; -- PC
				aluSrcB <= "01"; -- Constante 1
				aluOp <= "00"; -- Soma
				pcSource <= "00"; -- Saída da ULA
				pcWrite <= '1';

			when DECODE => -- ALUOut <- PC + imediato (alvo de um possível desvio)
				aluSrcA <= '0'; -- PC
				aluSrcB <= "10"; -- Imediato estendido
				aluOp <= "00"; -- Soma

			when ADDRESS => -- ALUOut <- A + imediato
				aluSrcA <= '1'; -- A
				aluSrcB <= "10"; -- Imediato estendido
				aluOp <= "00"; -- Soma

			when MEMORY_READ => -- RDM <- Mem[ALUOut]
				memRead <= '1';
				iorD <= '1'; -- Endereço = ALUOut

			when MEMORY_WRITE => -- Mem[ALUOut] <- B
				memWrite <= '1';
				iorD <= '1'; -- Endereço = ALUOut

			when EXECUTE => -- ALUOut <- A op B
				aluSrcA <= '1'; -- A
				aluSrcB <= "00"; -- B
				aluOp <= "10"; -- Definido pelo opcode

			when WRITE_BACK => -- Ri <- ALUOut ou RDM
				regWrite <= '1';
				if opcode = OP_LD then
					memtoReg <= '1'; -- LD: grava o RDM
				else
					memtoReg <= '0'; -- Tipo R e ADDI: grava o ALUOut
				end if;

			when BRANCH => -- A - B; se a condição for verdadeira: PC <- ALUOut
				aluSrcA <= '1'; -- A
				aluSrcB <= "00"; -- B
				aluOp <= "01"; -- Subtração
				pcSource <= "01"; -- ALUOut (alvo calculado na decodificação)
				pcWriteCond <= '1';
				if opcode = OP_BNE then
					bne <= '1'; -- BNE: desvia se Zero = '0'
				end if;

			when JUMP => -- PC <- end
				pcSource <= "10"; -- Endereço do JMP
				pcWrite <= '1';
		end case;
	end process;

	-- RegSrc depende apenas do opcode: ST, BEQ e BNE leem o Ri na porta 2 do banco.
	regSrc <= '1' when (opcode = OP_ST OR opcode = OP_BEQ OR opcode = OP_BNE) else '0';

	-- Saída para os LEDs verdes: um bit '1' indicando o estado atual.
	with currentState select
		stateLeds <=
			"000000001" when FETCH, -- LEDG0
			"000000010" when DECODE, -- LEDG1
			"000000100" when ADDRESS, -- LEDG2
			"000001000" when MEMORY_READ, -- LEDG3
			"000010000" when MEMORY_WRITE, -- LEDG4
			"000100000" when EXECUTE, -- LEDG5
			"001000000" when WRITE_BACK, -- LEDG6
			"010000000" when BRANCH, -- LEDG7
			"100000000" when JUMP; -- LEDG8
end architecture logic;