LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY grlib;
USE grlib.amba.ALL;
USE grlib.devices.ALL;
LIBRARY gaisler;
USE gaisler.misc.ALL;

entity apbnone_pll is
  generic (
    pindex   : integer := 0;
    paddr    : integer := 0;
    pmask    : integer := 16#fff#
    );

  port (
    rst    : in  std_ulogic;
    clk    : in  std_ulogic;
    apbi   : in  apb_slv_in_type;
    apbo   : out apb_slv_out_type
    );
end;

ARCHITECTURE rtl OF apbnone_pll IS

    CONSTANT REVISION : INTEGER := 1;

    CONSTANT PCONFIG : apb_config_type := (
        0 => ahb_device_reg (VENDOR_GAISLER, GAISLER_GPREG, 0, REVISION, 0),
        1 => apb_iobar(paddr, pmask)
    );
    TYPE registers IS RECORD
    reg : std_logic_vector(31 DOWNTO 0);
END RECORD;

SIGNAL r, rin : registers;

BEGIN
    comb : PROCESS (rst, r, apbi)
        VARIABLE readdata : std_logic_vector(31 DOWNTO 0);
        VARIABLE v : registers;
    BEGIN
        v := r;
        -- read register
        readdata := X"00000001";
        --readdata := (OTHERS => '0');
        --CASE apbi.paddr(4 DOWNTO 2) IS
        --    WHEN "000" => readdata := r.reg(31 DOWNTO 0);
        --    WHEN OTHERS => NULL;
        --END CASE;
        -- write registers
        IF (apbi.psel(pindex) AND apbi.penable AND apbi.pwrite) = '1' THEN
            CASE apbi.paddr(4 DOWNTO 2) IS
                WHEN "000" => v.reg := apbi.pwdata;
                WHEN OTHERS => NULL;
            END CASE;
        END IF;
        -- system reset
        IF rst = '0' THEN
            v.reg := (OTHERS => '0');
        END IF;
        rin <= v;
        apbo.prdata <= readdata; -- drive apb read bus
    END PROCESS;

    apbo.pirq <= (OTHERS => '0');
    apbo.pindex <= pindex;
    apbo.pconfig <= PCONFIG;
    -- No IRQ
    -- VHDL generic
    -- Config constant
    -- registers
    regs : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            r <= rin;
        END IF;
    END PROCESS;
    -- boot message
    -- pragma translate_off
    bootmsg : report_version
        GENERIC MAP("apb_example" & tost(pindex) & ": Example core rev " & tost(REVISION));
        -- pragma translate_on
END;