-- Projeto CPU 16 bits | Lab. de Arquitetura de Sistemas Computacionais

-- Testbench da CPU (apenas para simulação no ModelSim, NÃO vai para a placa).

-- O que ele faz:
-- 1. Gera o clock (período de 20 ns) e aplica o reset no início;
-- 2. A cada busca (estado FETCH), escreve no Transcript o PC e a instrução lida;
-- 3. Depois de executar o program_1.mif inteiro, confere automaticamente o valor final
--    de cada registrador e do PC, e mostra "OK" ou "ERRO" para cada um.

-- Valores esperados ao final do program_1.mif:
-- R1 = 0005 (o BEQ pulou o "ADDI R1, R0, 0") | R2 = 0000 (fim do laço do BNE)
-- R3 = 0002 | R4 = 0008 | R5 = 000D | R6 = 0001 | R7 = 000D (lido de Mem[30] pelo LD,
-- prova que o ST funcionou; se o ST falhasse, seria 00AA) | PC = 000D (JMP 13 em laço).

-- Usa nomes externos do VHDL-2008 (<<signal ...>>) para ler os registradores internos.
-- Por isso deve ser compilado com "vcom -2008".

library ieee;
use ieee.std_logic_1164.all;

entity cpu_tb is
end entity cpu_tb;

architecture test of cpu_tb is
	constant CLOCK_PERIOD : time := 20 ns;
	constant CYCLES : integer := 100; -- O programa termina em ~64 ciclos; sobra margem.

	signal clk : std_logic := '0';
	signal reset : std_logic := '1';
	signal done : boolean := false;
	signal pcOut, mdrOut, aluResultOut : std_logic_vector(15 downto 0);
	signal stateLeds : std_logic_vector(8 downto 0);

begin
	-- CPU sendo testada.
	uut: entity work.cpu
		port map (
			clk => clk, reset => reset,
			pcOut => pcOut, mdrOut => mdrOut, aluResultOut => aluResultOut,
			stateLeds => stateLeds
		);

	-- Clock: para quando "done" = true (assim o "run -all" termina sozinho).
	clk <= not clk after CLOCK_PERIOD / 2 when not done else '0';

	-- Mostra cada instrução buscada no Transcript.
	trace: process(clk)
		alias instruction is <<signal .cpu_tb.uut.datapathInstance.instruction : std_logic_vector(15 downto 0)>>;
		variable fetchAddress : std_logic_vector(15 downto 0);
	begin
		if falling_edge(clk) and reset = '0' then
			if stateLeds(0) = '1' then -- FETCH: guarda o endereço da instrução buscada.
				fetchAddress := pcOut;
			elsif stateLeds(1) = '1' then -- DECODE: o RI já tem a instrução.
				report "Endereco " & to_hstring(fetchAddress) & " | instrucao = " & to_hstring(instruction);
			end if;
		end if;
	end process;

	-- Os nomes externos (<<signal ...>>) ficam dentro dos processos porque só podem ser
	-- usados depois que a CPU (uut) já foi elaborada.
	stimulus: process
		alias r0 is <<signal .cpu_tb.uut.datapathInstance.registerBankInstance.r0 : std_logic_vector(15 downto 0)>>;
		alias r1 is <<signal .cpu_tb.uut.datapathInstance.registerBankInstance.r1 : std_logic_vector(15 downto 0)>>;
		alias r2 is <<signal .cpu_tb.uut.datapathInstance.registerBankInstance.r2 : std_logic_vector(15 downto 0)>>;
		alias r3 is <<signal .cpu_tb.uut.datapathInstance.registerBankInstance.r3 : std_logic_vector(15 downto 0)>>;
		alias r4 is <<signal .cpu_tb.uut.datapathInstance.registerBankInstance.r4 : std_logic_vector(15 downto 0)>>;
		alias r5 is <<signal .cpu_tb.uut.datapathInstance.registerBankInstance.r5 : std_logic_vector(15 downto 0)>>;
		alias r6 is <<signal .cpu_tb.uut.datapathInstance.registerBankInstance.r6 : std_logic_vector(15 downto 0)>>;
		alias r7 is <<signal .cpu_tb.uut.datapathInstance.registerBankInstance.r7 : std_logic_vector(15 downto 0)>>;
		variable errors : integer := 0;

		procedure check(name : string; actual, expected : std_logic_vector(15 downto 0)) is
		begin
			if actual = expected then
				report name & " = " & to_hstring(actual) & "  OK";
			else
				report name & " = " & to_hstring(actual) & "  ERRO (esperado " & to_hstring(expected) & ")"
					severity error;
				errors := errors + 1;
			end if;
		end procedure;
	begin
		-- Reset durante 1,5 ciclo.
		reset <= '1';
		wait for CLOCK_PERIOD * 1.5;
		reset <= '0';

		-- Executa o programa.
		for i in 1 to CYCLES loop
			wait until rising_edge(clk);
		end loop;
		wait for CLOCK_PERIOD / 4;

		report "===== Conferencia final =====";
		check("R0", r0, x"0000");
		check("R1", r1, x"0005");
		check("R2", r2, x"0000");
		check("R3", r3, x"0002");
		check("R4", r4, x"0008");
		check("R5", r5, x"000D");
		check("R6", r6, x"0001");
		check("R7", r7, x"000D");
		check("PC", pcOut, x"000D");

		if errors = 0 then
			report "===== RESULTADO: TODOS OS TESTES PASSARAM =====";
		else
			report "===== RESULTADO: " & integer'image(errors) & " ERRO(S) =====" severity error;
		end if;

		done <= true;
		wait;
	end process;
end architecture test;
