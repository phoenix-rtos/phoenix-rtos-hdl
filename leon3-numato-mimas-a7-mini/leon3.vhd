------------------------------------------------------------------------------
--  LEON3 Demonstration design
--  Copyright (C) 2016 Cobham Gaisler
------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2014, Aeroflex Gaisler
--  Copyright (C) 2015 - 2023, Cobham Gaisler
--  Copyright (C) 2023,        Frontgrade Gaisler
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; version 2.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
------------------------------------------------------------------------------

-- Modified (by Phoenix Systems, in 2023), see README.md for details

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY grlib;
USE grlib.amba.ALL;
USE grlib.stdlib.ALL;
USE grlib.devices.ALL;

LIBRARY techmap;
USE techmap.gencomp.ALL;
USE techmap.allclkgen.ALL;

LIBRARY gaisler;
USE gaisler.memctrl.ALL;
USE gaisler.leon3.ALL;
USE gaisler.uart.ALL;
USE gaisler.misc.ALL;
USE gaisler.spi.ALL;
USE gaisler.jtag.ALL;

--pragma translate_off
USE gaisler.sim.ALL;
LIBRARY unisim;
USE unisim.STARTUPE2;
--pragma translate_on

USE work.config.ALL;

USE work.all;

ENTITY leon3 IS
    GENERIC
    (
        fabtech        : integer := CFG_FABTECH;
        memtech        : integer := CFG_MEMTECH;
        padtech        : integer := CFG_PADTECH;
        clktech        : integer := CFG_CLKTECH;
        disas          : integer := CFG_DISAS;     -- Enable disassembly to console
        dbguart        : integer := CFG_DUART;     -- Print UART on console
        pclow          : integer := CFG_PCLOW;
        use_ahbram_sim : integer := 0
    );
    PORT
    (
        --System signals
        i_clk          : IN    std_ulogic;

        --Simple IO
        i_btn          : IN    std_logic_vector(3 downto 0);
        o_led          : OUT std_logic_vector(7 downto 0);

        --UART
        i_uart2_rx     : IN    std_logic;
        o_uart2_tx     : OUT std_logic;

        i_uart3_rx     : IN    std_logic;
        o_uart3_tx     : OUT std_logic;

        o_ui_clk        : OUT std_logic;
        o_clkref        : OUT std_logic;
        o_clkinmig      : OUT std_logic;
        o_i_clk         : OUT std_logic;

        -- DDR3
        ddr3_dq           : inout std_logic_vector(15 downto 0);
        ddr3_dqs_p        : inout std_logic_vector(1 downto 0);
        ddr3_dqs_n        : inout std_logic_vector(1 downto 0);
        ddr3_addr         : out   std_logic_vector(13 downto 0);
        ddr3_ba           : out   std_logic_vector(2 downto 0);
        ddr3_ras_n        : out   std_logic;
        ddr3_cas_n        : out   std_logic;
        ddr3_we_n         : out   std_logic;
        ddr3_reset_n      : inout   std_logic;
        ddr3_ck_p         : out   std_logic_vector(0 downto 0);
        ddr3_ck_n         : out   std_logic_vector(0 downto 0);
        ddr3_cke          : out   std_logic_vector(0 downto 0);
        ddr3_cs_n         : inout   std_logic_vector(0 downto 0);
        ddr3_dm           : out   std_logic_vector(1 downto 0);
        ddr3_odt          : out   std_logic_vector(0 downto 0)
    );
END leon3;

ARCHITECTURE RTL OF leon3 IS

    CONSTANT C_default_irq_map : std_logic_vector((64*5)-1 downto 0) :=

        std_logic_vector(to_unsigned(19, 5)) &
        std_logic_vector(to_unsigned(18, 5)) &
        std_logic_vector(to_unsigned(17, 5)) &
        std_logic_vector(to_unsigned(16, 5)) &
        std_logic_vector(to_unsigned(26, 5)) &
        std_logic_vector(to_unsigned(25, 5)) &
        std_logic_vector(to_unsigned(24, 5)) &
        std_logic_vector(to_unsigned(23, 5)) &
        std_logic_vector(to_unsigned(22, 5)) &
        std_logic_vector(to_unsigned(21, 5)) &
        std_logic_vector(to_unsigned(20, 5)) &
        std_logic_vector(to_unsigned(2, 5)) &
        std_logic_vector(to_unsigned(14, 5)) &
        std_logic_vector(to_unsigned(13, 5)) &
        std_logic_vector(to_unsigned(12, 5)) &
        std_logic_vector(to_unsigned(11, 5)) &

        std_logic_vector(to_unsigned(8, 5)) &
        std_logic_vector(to_unsigned(7, 5)) &
        std_logic_vector(to_unsigned(6, 5)) &
        std_logic_vector(to_unsigned(5, 5)) &
        std_logic_vector(to_unsigned(4, 5)) &
        std_logic_vector(to_unsigned(3, 5)) &
        std_logic_vector(to_unsigned(19, 5)) &
        std_logic_vector(to_unsigned(18, 5)) &
        std_logic_vector(to_unsigned(17, 5)) &
        std_logic_vector(to_unsigned(16, 5)) &
        std_logic_vector(to_unsigned(27, 5)) &
        std_logic_vector(to_unsigned(26, 5)) &
        std_logic_vector(to_unsigned(31, 5)) &
        std_logic_vector(to_unsigned(30, 5)) &
        std_logic_vector(to_unsigned(29, 5)) &
        std_logic_vector(to_unsigned(28, 5)) &

        std_logic_vector(to_unsigned(31, 5)) &
        std_logic_vector(to_unsigned(30, 5)) &
        std_logic_vector(to_unsigned(29, 5)) &
        std_logic_vector(to_unsigned(28, 5)) &
        std_logic_vector(to_unsigned(27, 5)) &
        std_logic_vector(to_unsigned(26, 5)) &
        std_logic_vector(to_unsigned(25, 5)) &
        std_logic_vector(to_unsigned(24, 5)) &
        std_logic_vector(to_unsigned(23, 5)) &
        std_logic_vector(to_unsigned(22, 5)) &
        std_logic_vector(to_unsigned(21, 5)) &
        std_logic_vector(to_unsigned(20, 5)) &
        std_logic_vector(to_unsigned(19, 5)) &
        std_logic_vector(to_unsigned(18, 5)) &
        std_logic_vector(to_unsigned(17, 5)) &
        std_logic_vector(to_unsigned(16, 5)) &

        std_logic_vector(to_unsigned(15, 5)) &
        std_logic_vector(to_unsigned(14, 5)) &
        std_logic_vector(to_unsigned(13, 5)) &
        std_logic_vector(to_unsigned(12, 5)) &
        std_logic_vector(to_unsigned(11, 5)) &
        std_logic_vector(to_unsigned(10, 5)) &
        std_logic_vector(to_unsigned(9, 5)) &
        std_logic_vector(to_unsigned(8, 5)) &
        std_logic_vector(to_unsigned(7, 5)) &
        std_logic_vector(to_unsigned(6, 5)) &
        std_logic_vector(to_unsigned(5, 5)) &
        std_logic_vector(to_unsigned(4, 5)) &
        std_logic_vector(to_unsigned(3, 5)) &
        std_logic_vector(to_unsigned(2, 5)) &
        std_logic_vector(to_unsigned(1, 5)) &
        std_logic_vector(to_unsigned(0, 5));

    CONSTANT C_board_freq : integer := 100000;                                 -- input clock frequency in KHz
    CONSTANT C_cpu_freq   : integer := C_board_freq * CFG_CLKMUL / CFG_CLKDIV; -- CPU frequency in KHz

    SIGNAL   w_sys_clk  : std_ulogic
    -- pragma translate_off
    := '0'
    -- pragma translate_on
    ;

    SIGNAL   w_rst_n    : std_ulogic;
    SIGNAL   w_rst_raw  : std_ulogic;

    SIGNAL   w_tck      : std_ulogic;
    SIGNAL   w_tms      : std_ulogic;
    SIGNAL   w_tdi      : std_ulogic;
    SIGNAL   w_tdo      : std_ulogic;

    SIGNAL   w_btn0     : std_ulogic;

    --External UART
    SIGNAL   w_uart2_rx : std_logic;
    SIGNAL   w_uart2_tx : std_logic;
    SIGNAL   w_uart3_rx : std_logic;
    SIGNAL   w_uart3_tx : std_logic;

    -- MIG
    signal clkref, calib_done : std_logic;
    signal pll_locked         : std_ulogic;
    signal lock               : std_logic;
    signal eth_ref_clki       : std_ulogic;
    signal clkinmig           : std_logic;

    --APB (low power bus) slaves
    SIGNAL   w_apb0_slave_i  : apb_slv_in_type;
    SIGNAL   w_apb0_slave_o  : apb_slv_out_vector := (OTHERS => apb_none);

    SIGNAL   w_apb1_slave_i  : apb_slv_in_type;
    SIGNAL   w_apb1_slave_o  : apb_slv_out_vector := (OTHERS => apb_none);

    SIGNAL   w_apb2_slave_i  : apb_slv_in_type;
    SIGNAL   w_apb2_slave_o  : apb_slv_out_vector := (OTHERS => apb_none);

    SIGNAL   w_apb3_slave_i  : apb_slv_in_type;
    SIGNAL   w_apb3_slave_o  : apb_slv_out_vector := (OTHERS => apb_none);

    SIGNAL w_irqamp_apb0_slave_i : apb_slv_in_type;

    --AHB (high performance bus) slaves
    SIGNAL   w_ahb_slave_i  : ahb_slv_in_type;
    SIGNAL   w_ahb_slave_o  : ahb_slv_out_vector := (OTHERS => ahbs_none);

    --AHB (high performance bus) master(s)
    SIGNAL   w_ahb_master_i : ahb_mst_in_type;
    SIGNAL   w_ahb_master_o : ahb_mst_out_vector := (OTHERS => ahbm_none);

    --UART2
    SIGNAL   w_uart2_i  : uart_in_type;
    SIGNAL   w_uart2_o  : uart_out_type;

    --UART3
    SIGNAL   w_uart3_i  : uart_in_type;
    SIGNAL   w_uart3_o  : uart_out_type;

    --LEON3 interrupt IO
    SIGNAL   w_irq_i    : irq_in_vector( 0 to CFG_NCPU-1);
    SIGNAL   w_irq_o    : irq_out_vector(0 to CFG_NCPU-1);

    --LEON3's debug IO
    SIGNAL   w_l3dbg_i  : l3_debug_in_vector( 0 to CFG_NCPU-1);
    SIGNAL   w_l3dbg_o  : l3_debug_out_vector(0 to CFG_NCPU-1);

    --LEON3 Debug Support Unit IO
    SIGNAL   w_dsu_i    : dsu_in_type;
    SIGNAL   w_dsu_o    : dsu_out_type;

    --General purpose timer
    SIGNAL   w_gpt_i    : gptimer_in_type;

    --SPI memory controller
    signal spii : spi_in_type;
    signal spio : spi_out_type;
    signal slvsel : std_logic_vector(CFG_SPICTRL_SLVS-1 downto 0);

    ATTRIBUTE keep         : boolean;
    ATTRIBUTE syn_keep     : boolean;
    ATTRIBUTE syn_preserve : boolean;
    ATTRIBUTE syn_keep     OF w_sys_clk : SIGNAL IS true;
    ATTRIBUTE syn_preserve OF w_sys_clk : SIGNAL IS true;
    ATTRIBUTE keep         OF w_sys_clk : SIGNAL IS true;

    SIGNAL w_i_clk_rst_n   : std_logic;
    SIGNAL w_i_clk_rst_raw : std_logic;

BEGIN

    o_ui_clk <= w_sys_clk;
    o_clkref <= clkref;
    o_clkinmig <= clkinmig;
    o_i_clk  <= i_clk;

    --Reset and Clock generation
    btn0_pad : inpad
        GENERIC MAP (tech => padtech) PORT MAP (pad => i_btn(0), o => w_btn0);

    rstgen_inst_w_sys_clk : rstgen
        GENERIC MAP (acthigh => 1)
           PORT MAP (w_btn0, w_sys_clk, lock, w_rst_n, w_rst_raw);

    lock <= calib_done and pll_locked;
    o_led(1) <= lock;
    o_led(2) <= calib_done;

    rstgen_inst_i_clk : rstgen
        GENERIC MAP (acthigh => 1)
           PORT MAP (w_btn0, i_clk, '1', w_i_clk_rst_n, w_i_clk_rst_raw);

    --AHB Controller
    ahbctrl_inst : ahbctrl
        GENERIC MAP (defmast => CFG_DEFMST, split => CFG_SPLIT, rrobin => CFG_RROBIN, ioaddr => CFG_AHBIO, ioen => 1,
                     nahbm => CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG,
                     nahbs => 9)
           PORT MAP (w_rst_n, w_sys_clk, w_ahb_master_i, w_ahb_master_o, w_ahb_slave_i, w_ahb_slave_o);


    --LEON3 processor
    leon3gen : IF CFG_LEON3 = 1 GENERATE
        cpugen : FOR i IN 0 TO CFG_NCPU-1 GENERATE
        u0 : leon3s
            GENERIC MAP (i, fabtech, memtech, CFG_NWIN, CFG_DSU, CFG_FPU, CFG_V8,
                     0, CFG_MAC, pclow, CFG_NOTAG, CFG_NWP, CFG_ICEN, CFG_IREPL, CFG_ISETS, CFG_ILINE,
                     CFG_ISETSZ, CFG_ILOCK, CFG_DCEN, CFG_DREPL, CFG_DSETS, CFG_DLINE, CFG_DSETSZ,
                     CFG_DLOCK, CFG_DSNOOP, CFG_ILRAMEN, CFG_ILRAMSZ, CFG_ILRAMADDR, CFG_DLRAMEN,
                     CFG_DLRAMSZ, CFG_DLRAMADDR, CFG_MMUEN, CFG_ITLBNUM, CFG_DTLBNUM, CFG_TLB_TYPE, CFG_TLB_REP,
                     CFG_LDDEL, disas, CFG_ITBSZ, CFG_PWD, CFG_SVT, CFG_RSTADDR,
                     CFG_NCPU-1, CFG_DFIXED, CFG_SCAN, CFG_MMU_PAGE, CFG_BP, CFG_NP_ASI, CFG_WRPSR,
                     CFG_REX, CFG_ALTWIN)
            PORT MAP (w_sys_clk, w_rst_n, w_ahb_master_i, w_ahb_master_o(i), w_ahb_slave_i, w_ahb_slave_o, w_irq_i(i), w_irq_o(i), w_l3dbg_i(i), w_l3dbg_o(i));
        END GENERATE;

        o_led0_pad : outpad
            GENERIC MAP (tech => padtech) PORT MAP (o_led(0), w_l3dbg_o(0).error);

        --LEON3 Debug Support Unit
        dsugen : IF CFG_DSU = 1 GENERATE
            dsu3_inst : dsu3
                GENERIC MAP (hindex => 2,
                             haddr  => 16#900#,
                             hmask  => 16#F00#,
                             ahbpf  => CFG_AHBPF,
                             ncpu   => CFG_NCPU,
                             tbits  => 30,
                             tech   => memtech,
                             irq    => 0,
                             kbytes => CFG_ATBSZ)
                PORT MAP (w_rst_n, w_sys_clk, w_ahb_master_i, w_ahb_slave_i, w_ahb_slave_o(2), w_l3dbg_o, w_l3dbg_i, w_dsu_i, w_dsu_o);

            --dsubre_pad : inpad generic map (tech  => padtech) port map (dsubre, w_dsu_i.break);

            w_dsu_i.enable <= '1';
        END GENERATE;
    END GENERATE;
    nodsu : IF CFG_DSU = 0 GENERATE w_ahb_slave_o(2) <= ahbs_none; w_dsu_o.tstop <= '0'; w_dsu_o.active <= '0'; END GENERATE;

    --APB Bridge 0
    apbctrl_0 : apbctrl
        GENERIC MAP (hindex => 1, haddr => CFG_APBADDR, nslaves => 16)
           PORT MAP (w_rst_n, w_sys_clk,
                     w_ahb_slave_i, w_ahb_slave_o(1),
                     w_apb0_slave_i, w_apb0_slave_o);
    --APB Bridge 1
    apbctrl_1 : apbctrl
        GENERIC MAP (hindex => 8, haddr => 16#801#, nslaves => 16)
           PORT MAP (w_rst_n, w_sys_clk,
                     w_ahb_slave_i, w_ahb_slave_o(8),
                     w_apb1_slave_i, w_apb1_slave_o);

    --APB Bridge 2
    apbctrl_2 : apbctrl
        GENERIC MAP (hindex => 6, haddr => 16#803#, nslaves => 16)
           PORT MAP (w_rst_n, w_sys_clk,
                     w_ahb_slave_i, w_ahb_slave_o(6),
                     w_apb2_slave_i, w_apb2_slave_o);

    --APB Bridge 3
    -- not used. to fixed unused register map
    apbctrl_3 : apbctrl
        GENERIC MAP (hindex => 7, haddr => 16#804#, nslaves => 16)
           PORT MAP (w_rst_n, w_sys_clk,
                     w_ahb_slave_i, w_ahb_slave_o(7),
                     w_apb3_slave_i, w_apb3_slave_o);

    ----- APB0 slaves ---
    noftmctrl : entity work.apbnone
        GENERIC MAP (pindex => 0, paddr => 16#000#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(0));

    nodlram : entity work.apbnone
        GENERIC MAP (pindex => 1, paddr => 16#010#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(1));

   -- Advanced interrupt controller IRQAMP
    irqampctrl_gen: IF CFG_IRQAMP_ENABLE /= 0 GENERATE

        irqampctrl_inst : irqamp
             GENERIC MAP (pindex => 2, paddr => 16#020#, irqmap => 3, eirq => 1)
                PORT MAP (w_rst_n, w_sys_clk,
                        w_irqamp_apb0_slave_i, w_apb0_slave_o(2),
                         w_irq_o, w_irq_i, rstmap => C_default_irq_map);

        w_irqamp_apb0_slave_i.psel <= w_apb0_slave_i.psel;
        w_irqamp_apb0_slave_i.penable <= w_apb0_slave_i.penable;
        w_irqamp_apb0_slave_i.paddr <= w_apb0_slave_i.paddr;
        w_irqamp_apb0_slave_i.pwrite <= w_apb0_slave_i.pwrite;
        w_irqamp_apb0_slave_i.pwdata <= w_apb0_slave_i.pwdata;
        w_irqamp_apb0_slave_i.testen <= w_apb0_slave_i.testen;
        w_irqamp_apb0_slave_i.testrst <= w_apb0_slave_i.testrst;
        w_irqamp_apb0_slave_i.scanen <= w_apb0_slave_i.scanen;
        w_irqamp_apb0_slave_i.testoen <= w_apb0_slave_i.testoen;
        w_irqamp_apb0_slave_i.testin <= w_apb0_slave_i.testin;

        w_irqamp_apb0_slave_i.pirq(15 downto 0)  <= w_apb0_slave_i.pirq(15 downto 0);
        w_irqamp_apb0_slave_i.pirq(31 downto 16) <= "0000000000000000";
        w_irqamp_apb0_slave_i.pirq(47 downto 32) <= w_apb2_slave_i.pirq(15 downto 0);
        w_irqamp_apb0_slave_i.pirq(63 downto 48) <= "0000000000000000";

    end generate;

    -- Basic interrupt controller IRQMP
    irqmpctrl_gen: IF CFG_IRQ3_ENABLE /= 0 GENERATE

        -- IRQMP
        irqmpctrl_inst : irqmp
            GENERIC MAP (pindex => 2, paddr => 16#020#, ncpu => CFG_NCPU)
               PORT MAP (w_rst_n, w_sys_clk,
                         w_apb0_slave_i, w_apb0_slave_o(2),
                         w_irq_o, w_irq_i);
    end generate;

    -- No interrupt controller
    noirpctrl_gen: IF ( CFG_IRQ3_ENABLE = 0 AND CFG_IRQAMP_ENABLE = 0 ) GENERATE

        x : FOR i IN 0 TO CFG_NCPU-1 GENERATE
            w_irq_i(i).irl <= "0000";
        END GENERATE;
        w_apb0_slave_o(2) <= apb_none;

    END GENERATE;

    --General Purpose Timer
    gptimergen : IF CFG_GPT_ENABLE /= 0 GENERATE
        gptimer_inst : gptimer
            GENERIC MAP (pindex => 3, paddr => 16#030#, pirq => CFG_GPT_IRQ, --CFG_GPT_IRQ = 9
                         sepirq => CFG_GPT_SEPIRQ, sbits => CFG_GPT_SW,
                         ntimers => CFG_GPT_NTIM, nbits  => CFG_GPT_TW)
               PORT MAP (w_rst_n, w_sys_clk,
                         w_apb0_slave_i, w_apb0_slave_o(3),
                         w_gpt_i, OPEN);
        w_gpt_i <= gpti_dhalt_drive(w_dsu_o.tstop);
    END GENERATE;
    nogptimer : IF CFG_GPT_ENABLE = 0 GENERATE w_apb0_slave_o(3) <= apb_none; END GENERATE;

    noGPTIMER1 : entity work.apbnone
        GENERIC MAP (pindex => 4, paddr => 16#040#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(4));

    noMEMPROT0 : entity work.apbnone
        GENERIC MAP (pindex => 5, paddr => 16#050#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(5));

    noGRCLKGATE0 : entity work.apbnone_grclkgate
        GENERIC MAP (pindex => 6, paddr => 16#060#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(6));

    noGRCLKGATE1 : entity work.apbnone_grclkgate
        GENERIC MAP (pindex => 7, paddr => 16#070#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(7));

    noGRGPREG : entity work.apbnone
        GENERIC MAP (pindex => 8, paddr => 16#080#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(8));

    noL3STAT : entity work.apbnone
        GENERIC MAP (pindex => 9, paddr => 16#090#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(9));

    noAHBSTAT : entity work.apbnone
        GENERIC MAP (pindex => 10, paddr => 16#0A0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(10));

    noILRAM : entity work.apbnone
        GENERIC MAP (pindex => 11, paddr => 16#0B0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(11));

    noGRSPWTDP : entity work.apbnone
        GENERIC MAP (pindex => 12, paddr => 16#0C0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(12));

    noGRGPRBANK : entity work.apbnone
        GENERIC MAP (pindex => 13, paddr => 16#0D0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(13));

    noGRGPREG1 : entity work.apbnone
        GENERIC MAP (pindex => 14, paddr => 16#0E0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(14));

    noAHBUARTsl : entity work.apbnone
        GENERIC MAP (pindex => 15, paddr => 16#0F0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb0_slave_i, w_apb0_slave_o(15));

    --- APB1 slaves ---
    noGRSPW2 : entity work.apbnone
        GENERIC MAP (pindex => 0, paddr => 16#000#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(0));
    noGR1553B : entity work.apbnone
        GENERIC MAP (pindex => 1, paddr => 16#010#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(1));
    noCAN0 : entity work.apbnone
        GENERIC MAP (pindex => 2, paddr => 16#020#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(2));
    noCAN1 : entity work.apbnone
        GENERIC MAP (pindex => 3, paddr => 16#030#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(3));
    noSPI2AHB : entity work.apbnone
        GENERIC MAP (pindex => 4, paddr => 16#040#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(4));
    noI2C2AHB : entity work.apbnone
        GENERIC MAP (pindex => 5, paddr => 16#050#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(5));
    noGRDMAC0 : entity work.apbnone
        GENERIC MAP (pindex => 6, paddr => 16#060#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(6));
    noGRDMAC1 : entity work.apbnone
        GENERIC MAP (pindex => 7, paddr => 16#070#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(7));
    noGRDMAC2 : entity work.apbnone
        GENERIC MAP (pindex => 8, paddr => 16#080#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(8));
    noGRDMAC3 : entity work.apbnone
        GENERIC MAP (pindex => 9, paddr => 16#090#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(9));
    noMEMPROT1 : entity work.apbnone
        GENERIC MAP (pindex => 10, paddr => 16#0A0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(10));
    noBANDGAP : entity work.apbnone
        GENERIC MAP (pindex => 11, paddr => 16#0B0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(11));
    noBO : entity work.apbnone
        GENERIC MAP (pindex => 12, paddr => 16#0C0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(12));
    noPLL : entity work.apbnone_pll
        GENERIC MAP (pindex => 13, paddr => 16#0D0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(13));
    noPWRX : entity work.apbnone
        GENERIC MAP (pindex => 14, paddr => 16#0E0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(14));
    noPWTX : entity work.apbnone
        GENERIC MAP (pindex => 15, paddr => 16#0F0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb1_slave_i, w_apb1_slave_o(15));

    --- APB2 slaves ---
    noapbuart0 : entity work.apbnone
        GENERIC MAP (pindex => 0, paddr => 16#000#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(0));

    noapbuart1 : entity work.apbnone
        GENERIC MAP (pindex => 1, paddr => 16#010#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(1));

    uart2gen : IF CFG_UART2_ENABLE /= 0 GENERATE
        uart2_rx_pad : inpad
            GENERIC MAP (tech => padtech) PORT MAP (i_uart2_rx, w_uart2_rx);
        uart2_tx_pad : outpad
            GENERIC MAP (tech => padtech) PORT MAP (o_uart2_tx, w_uart2_tx);
        uart2 : apbuart
            GENERIC MAP (pindex => 2, paddr => 16#020#, pirq => 10, console => dbguart, fifosize => CFG_UART2_FIFO)
               PORT MAP (w_rst_n, w_sys_clk,
                         w_apb2_slave_i, w_apb2_slave_o(2),
                         w_uart2_i, w_uart2_o);
        w_uart2_tx       <= w_uart2_o.txd;
        w_uart2_i.rxd    <= w_uart2_rx;
        w_uart2_i.ctsn   <= '0';
        w_uart2_i.extclk <= '0';

    END GENERATE;
    nouart2 : IF CFG_UART2_ENABLE = 0 GENERATE w_apb2_slave_o(2) <= apb_none; END GENERATE;

    uart3gen : IF CFG_UART3_ENABLE /= 0 GENERATE
        uart3_rx_pad : inpad
            GENERIC MAP (tech => padtech) PORT MAP (i_uart3_rx, w_uart3_rx);
        uart3_tx_pad : outpad
            GENERIC MAP (tech => padtech) PORT MAP (o_uart3_tx, w_uart3_tx);
        uart3 : apbuart
            GENERIC MAP (pindex => 3, paddr => 16#030#, pirq => 12, console => dbguart, fifosize => CFG_UART3_FIFO)
               PORT MAP (w_rst_n, w_sys_clk,
                         w_apb2_slave_i, w_apb2_slave_o(3),
                         w_uart3_i, w_uart3_o);
        w_uart3_tx       <= w_uart3_o.txd;
        w_uart3_i.rxd    <= w_uart3_rx;
        w_uart3_i.ctsn   <= '0';
        w_uart3_i.extclk <= '0';
    END GENERATE;
    nouart3 : IF CFG_UART3_ENABLE = 0 GENERATE w_apb2_slave_o(3) <= apb_none; END GENERATE;

    noAPBUART4 : entity work.apbnone
        GENERIC MAP (pindex => 4, paddr => 16#040#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(4));
    noAPBUART5 : entity work.apbnone
        GENERIC MAP (pindex => 5, paddr => 16#050#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(5));
    noAHBSTAT1 : entity work.apbnone
        GENERIC MAP (pindex => 6, paddr => 16#060#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(6));
    noNVRAM : entity work.apbnone
        GENERIC MAP (pindex => 7, paddr => 16#070#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(7));
    noGRADCDAC : entity work.apbnone
        GENERIC MAP (pindex => 8, paddr => 16#080#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(8));
    spi0 : spictrl
        generic map (pindex => 9, paddr => 16#090#, pirq => 13,
                   fdepth => CFG_SPICTRL_FIFO, slvselen => CFG_SPICTRL_SLVREG,
                   slvselsz => CFG_SPICTRL_SLVS, odmode => CFG_SPICTRL_ODMODE,
                   syncram => CFG_SPICTRL_SYNCRAM, ft => CFG_SPICTRL_FT)
        port map (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(9), spii, spio, slvsel);
        spii.spisel <= '1';                 -- Master only
    --noSPICTRL0 : entity work.apbnone
    --    GENERIC MAP (pindex => 9, paddr => 16#090#)
    --    PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(9));
    noSPICTRL1 : entity work.apbnone
        GENERIC MAP (pindex => 10, paddr => 16#0A0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(10));
    noUNUSED : entity work.apbnone
        GENERIC MAP (pindex => 11, paddr => 16#0B0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(11));
    noGRGPIO0 : entity work.apbnone
        GENERIC MAP (pindex => 12, paddr => 16#0C0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(12));
    noGRGPIO1 : entity work.apbnone
        GENERIC MAP (pindex => 13, paddr => 16#0D0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(13));
    noI2CMST0 : entity work.apbnone
        GENERIC MAP (pindex => 14, paddr => 16#0E0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(14));
    noI2CMST1 : entity work.apbnone
        GENERIC MAP (pindex => 15, paddr => 16#0F0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb2_slave_i, w_apb2_slave_o(15));

    --- APB3 slaves ---
    noADC0 : entity work.apbnone
        GENERIC MAP (pindex => 0, paddr => 16#000#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(0));
    noADC1 : entity work.apbnone
        GENERIC MAP (pindex => 1, paddr => 16#010#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(1));
    noADC2 : entity work.apbnone
        GENERIC MAP (pindex => 2, paddr => 16#020#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(2));
    noADC3 : entity work.apbnone
        GENERIC MAP (pindex => 3, paddr => 16#030#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(3));
    noADC4 : entity work.apbnone
        GENERIC MAP (pindex => 4, paddr => 16#040#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(4));
    noADC5 : entity work.apbnone
        GENERIC MAP (pindex => 5, paddr => 16#050#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(5));
    noADC6 : entity work.apbnone
        GENERIC MAP (pindex => 6, paddr => 16#060#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(6));
    noADC7 : entity work.apbnone
        GENERIC MAP (pindex => 7, paddr => 16#070#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(7));
    noDAC0 : entity work.apbnone
        GENERIC MAP (pindex => 8, paddr => 16#080#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(8));
    noDAC1 : entity work.apbnone
        GENERIC MAP (pindex => 9, paddr => 16#090#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(9));
    noDAC2 : entity work.apbnone
        GENERIC MAP (pindex => 10, paddr => 16#0A0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(10));
    noDAC3 : entity work.apbnone
        GENERIC MAP (pindex => 11, paddr => 16#0B0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(11));
    noDAC4 : entity work.apbnone
        GENERIC MAP (pindex => 12, paddr => 16#0C0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(12));
    noI2Cslave0 : entity work.apbnone
        GENERIC MAP (pindex => 13, paddr => 16#0D0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(13));
    noI2Cslave1 : entity work.apbnone
        GENERIC MAP (pindex => 14, paddr => 16#0E0#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(14));
    noPWM1 : entity work.apbnone
        GENERIC MAP (pindex => 15, paddr => 16#100#)
        PORT MAP (w_rst_n, w_sys_clk, w_apb3_slave_i, w_apb3_slave_o(15));

    --AHB ROM
    ahbromgen : IF CFG_AHBROMEN /= 0 GENERATE
        ahbrom_inst : ENTITY work.ahbrom
            GENERIC MAP (hindex => 4, haddr => CFG_AHBRODDR, pipe => CFG_AHBROPIP)
               PORT MAP (w_rst_n, w_sys_clk,
                         w_ahb_slave_i, w_ahb_slave_o(4));
    END GENERATE;
    noahbrom : IF CFG_AHBROMEN = 0 GENERATE w_ahb_slave_o(4) <= ahbs_none; END GENERATE;

    --CLK GEN 200 MHz, 200 MHz and 25 Mhz
    clockers0 : entity work.clockers_mig
        port map (
          rstn        => w_i_clk_rst_raw,
          clkin       => i_clk,
          mig_clkref  => clkref,
          clkm        => clkinmig,
          eth_ref     => eth_ref_clki,
          locked      => pll_locked
        );

    --AHB2MIG
    gen_mig : if (CFG_MIG_7SERIES = 1) generate
      ddrc : entity work.ahb2mig_7series
        generic map (
          hindex => 5, haddr => 16#400#, hmask => 16#F00#)
        port map(
          ddr3_dq         => ddr3_dq,
          ddr3_dqs_p      => ddr3_dqs_p,
          ddr3_dqs_n      => ddr3_dqs_n,
          ddr3_addr       => ddr3_addr,
          ddr3_ba         => ddr3_ba,
          ddr3_ras_n      => ddr3_ras_n,
          ddr3_cas_n      => ddr3_cas_n,
          ddr3_we_n       => ddr3_we_n,
          ddr3_reset_n    => ddr3_reset_n,
          ddr3_ck_p       => ddr3_ck_p,
          ddr3_ck_n       => ddr3_ck_n,
          ddr3_cke        => ddr3_cke,
          ddr3_cs_n       => ddr3_cs_n,
          ddr3_dm         => ddr3_dm,
          ddr3_odt        => ddr3_odt,
          ahbsi           => w_ahb_slave_i,
          ahbso           => w_ahb_slave_o(5),
          calib_done      => calib_done,
          rst_n_syn       => w_i_clk_rst_n,
          rst_n_async     => w_rst_raw,
          clk_amba        => w_sys_clk,
          sys_clk_i       => clkinmig,
          clk_ref_i       => clkref,
          ui_clk          => w_sys_clk,
          ui_clk_sync_rst => open
          );

    end generate gen_mig;

    --AHB RAM
    ahbramgen : IF CFG_AHBRAMEN = 1 GENERATE
--pragma translate_off
        phys : IF use_ahbram_sim = 0 GENERATE
--pragma translate_on
        ahbram0 : ahbram
            GENERIC MAP (hindex => 3, haddr => CFG_AHBRADDR, tech => CFG_MEMTECH,
                         kbytes => CFG_AHBRSZ, pipe => CFG_AHBRPIPE)
               PORT MAP (w_rst_n, w_sys_clk,
                         w_ahb_slave_i, w_ahb_slave_o(3));
--pragma translate_off
        END GENERATE;
        simram : IF use_ahbram_sim /= 0 GENERATE
            ahbram0 : ahbram_sim
            GENERIC MAP (hindex => 3, haddr => CFG_AHBRADDR, tech => CFG_MEMTECH,
                         kbytes => 1024, pipe => CFG_AHBRPIPE, fname => "ram.srec")
               PORT MAP (w_rst_n, w_sys_clk,
                         w_ahb_slave_i, w_ahb_slave_o(3));
        END GENERATE;
--pragma translate_on
    END GENERATE;
    noahbram : IF CFG_AHBRAMEN = 0 GENERATE w_ahb_slave_o(3) <= ahbs_none; END GENERATE;

    --Drive unused bus elements
    nam1 : FOR i IN (CFG_NCPU+CFG_AHB_UART+CFG_AHB_JTAG+1) TO NAHBMST-1 GENERATE
        w_ahb_master_o(i) <= ahbm_none;
    END GENERATE;


    --Boot message
-- pragma translate_off
    x : report_design
        GENERIC MAP (msg1 => "LEON3 Demonstration design for Digilent Basys3 board",
                     fabtech => tech_table(fabtech), memtech => tech_table(memtech),
                     mdel => 1);
-- pragma translate_on

END ARCHITECTURE;
