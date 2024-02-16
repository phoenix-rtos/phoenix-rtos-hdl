----------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2010 Aeroflex Gaisler
----------------------------------------------------------------------------
-- Entity:  ahbrom
-- File:    ahbrom.vhd
-- Author:  Jiri Gaisler - Gaisler Research
-- Description: AHB rom. 0/1-waitstate read
----------------------------------------------------------------------------

-- ROM content modified (by Phoenix Systems, in 2023)

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;

entity ahbrom is
  generic (
    hindex  : integer := 0;
    haddr   : integer := 0;
    hmask   : integer := 16#fff#;
    pipe    : integer := 0;
    tech    : integer := 0;
    kbytes  : integer := 1);
  port (
    rst     : in  std_ulogic;
    clk     : in  std_ulogic;
    ahbsi   : in  ahb_slv_in_type;
    ahbso   : out ahb_slv_out_type
  );
end;

architecture rtl of ahbrom is
constant abits : integer := 10;
constant bytes : integer := 560;

constant hconfig : ahb_config_type := (
  0 => ahb_device_reg ( VENDOR_GAISLER, GAISLER_AHBROM, 0, 0, 0),
  4 => ahb_membar(haddr, '1', '1', hmask), others => zero32);

signal romdata : std_logic_vector(31 downto 0);
signal addr : std_logic_vector(abits-1 downto 2);
signal hsel, hready : std_ulogic;

begin

  ahbso.hresp   <= "00";
  ahbso.hsplit  <= (others => '0');
  ahbso.hirq    <= (others => '0');
  ahbso.hconfig <= hconfig;
  ahbso.hindex  <= hindex;

  reg : process (clk)
  begin
    if rising_edge(clk) then
      addr <= ahbsi.haddr(abits-1 downto 2);
    end if;
  end process;

  p0 : if pipe = 0 generate
    ahbso.hrdata  <= ahbdrivedata(romdata);
    ahbso.hready  <= '1';
  end generate;

  p1 : if pipe = 1 generate
    reg2 : process (clk)
    begin
      if rising_edge(clk) then
    hsel <= ahbsi.hsel(hindex) and ahbsi.htrans(1);
    hready <= ahbsi.hready;
    ahbso.hready <=  (not rst) or (hsel and hready) or
      (ahbsi.hsel(hindex) and not ahbsi.htrans(1) and ahbsi.hready);
    ahbso.hrdata  <= ahbdrivedata(romdata);
      end if;
    end process;
  end generate;

  comb : process (addr)
  begin
    case conv_integer(addr) is
    when 16#00000# => romdata <= X"1d0c407f";
    when 16#00001# => romdata <= X"9c13a3f0";
    when 16#00002# => romdata <= X"81c02010";
    when 16#00003# => romdata <= X"9c23a040";
    when 16#00004# => romdata <= X"e03b8000";
    when 16#00005# => romdata <= X"e43ba008";
    when 16#00006# => romdata <= X"e823a010";
    when 16#00007# => romdata <= X"f03ba020";
    when 16#00008# => romdata <= X"f43ba028";
    when 16#00009# => romdata <= X"f83ba030";
    when 16#0000A# => romdata <= X"fe23a03c";
    when 16#0000B# => romdata <= X"9c03bf90";
    when 16#0000C# => romdata <= X"03200c0c";
    when 16#0000D# => romdata <= X"8610206c";
    when 16#0000E# => romdata <= X"8410600c";
    when 16#0000F# => romdata <= X"c6208000";
    when 16#00010# => romdata <= X"84106008";
    when 16#00011# => romdata <= X"86102003";
    when 16#00012# => romdata <= X"be10000f";
    when 16#00013# => romdata <= X"c6208000";
    when 16#00014# => romdata <= X"84100001";
    when 16#00015# => romdata <= X"07000000";
    when 16#00016# => romdata <= X"03108000";
    when 16#00017# => romdata <= X"8610e2a0";
    when 16#00018# => romdata <= X"8810a004";
    when 16#00019# => romdata <= X"8600e001";
    when 16#0001A# => romdata <= X"fa010000";
    when 16#0001B# => romdata <= X"808f6004";
    when 16#0001C# => romdata <= X"02bffffe";
    when 16#0001D# => romdata <= X"01000000";
    when 16#0001E# => romdata <= X"83386018";
    when 16#0001F# => romdata <= X"c2208000";
    when 16#00020# => romdata <= X"c208c000";
    when 16#00021# => romdata <= X"83286018";
    when 16#00022# => romdata <= X"80a06000";
    when 16#00023# => romdata <= X"32bffff7";
    when 16#00024# => romdata <= X"8600e001";
    when 16#00025# => romdata <= X"39200c0c";
    when 16#00026# => romdata <= X"25000000";
    when 16#00027# => romdata <= X"37000000";
    when 16#00028# => romdata <= X"2137ab6f";
    when 16#00029# => romdata <= X"b203a064";
    when 16#0002A# => romdata <= X"a414a2b0";
    when 16#0002B# => romdata <= X"a803a068";
    when 16#0002C# => romdata <= X"b003a06c";
    when 16#0002D# => romdata <= X"b616e2c0";
    when 16#0002E# => romdata <= X"ba172004";
    when 16#0002F# => romdata <= X"a01422ef";
    when 16#00030# => romdata <= X"b403a070";
    when 16#00031# => romdata <= X"23124000";
    when 16#00032# => romdata <= X"a610200a";
    when 16#00033# => romdata <= X"8403a060";
    when 16#00034# => romdata <= X"c2074000";
    when 16#00035# => romdata <= X"80886001";
    when 16#00036# => romdata <= X"02bffffe";
    when 16#00037# => romdata <= X"01000000";
    when 16#00038# => romdata <= X"c2070000";
    when 16#00039# => romdata <= X"c2288000";
    when 16#0003A# => romdata <= X"8400a001";
    when 16#0003B# => romdata <= X"80a64002";
    when 16#0003C# => romdata <= X"12bffff8";
    when 16#0003D# => romdata <= X"c203a060";
    when 16#0003E# => romdata <= X"80a04010";
    when 16#0003F# => romdata <= X"02800029";
    when 16#00040# => romdata <= X"86100012";
    when 16#00041# => romdata <= X"84100011";
    when 16#00042# => romdata <= X"8600e001";
    when 16#00043# => romdata <= X"c2074000";
    when 16#00044# => romdata <= X"80886004";
    when 16#00045# => romdata <= X"02bffffe";
    when 16#00046# => romdata <= X"01000000";
    when 16#00047# => romdata <= X"8538a018";
    when 16#00048# => romdata <= X"c4270000";
    when 16#00049# => romdata <= X"c408c000";
    when 16#0004A# => romdata <= X"8528a018";
    when 16#0004B# => romdata <= X"80a0a000";
    when 16#0004C# => romdata <= X"12bffff7";
    when 16#0004D# => romdata <= X"8600e001";
    when 16#0004E# => romdata <= X"86102000";
    when 16#0004F# => romdata <= X"c20ba060";
    when 16#00050# => romdata <= X"8200c001";
    when 16#00051# => romdata <= X"880860ff";
    when 16#00052# => romdata <= X"80a12009";
    when 16#00053# => romdata <= X"18800003";
    when 16#00054# => romdata <= X"84006057";
    when 16#00055# => romdata <= X"84006030";
    when 16#00056# => romdata <= X"c2074000";
    when 16#00057# => romdata <= X"80886004";
    when 16#00058# => romdata <= X"02bffffe";
    when 16#00059# => romdata <= X"01000000";
    when 16#0005A# => romdata <= X"8528a018";
    when 16#0005B# => romdata <= X"8538a018";
    when 16#0005C# => romdata <= X"c4270000";
    when 16#0005D# => romdata <= X"8600e001";
    when 16#0005E# => romdata <= X"80a0e004";
    when 16#0005F# => romdata <= X"12bffff1";
    when 16#00060# => romdata <= X"c20ba060";
    when 16#00061# => romdata <= X"c2074000";
    when 16#00062# => romdata <= X"80886004";
    when 16#00063# => romdata <= X"02bffffe";
    when 16#00064# => romdata <= X"01000000";
    when 16#00065# => romdata <= X"e6270000";
    when 16#00066# => romdata <= X"10bfffce";
    when 16#00067# => romdata <= X"8403a060";
    when 16#00068# => romdata <= X"84100019";
    when 16#00069# => romdata <= X"c2074000";
    when 16#0006A# => romdata <= X"80886001";
    when 16#0006B# => romdata <= X"02bffffe";
    when 16#0006C# => romdata <= X"01000000";
    when 16#0006D# => romdata <= X"c2070000";
    when 16#0006E# => romdata <= X"c2288000";
    when 16#0006F# => romdata <= X"8400a001";
    when 16#00070# => romdata <= X"80a50002";
    when 16#00071# => romdata <= X"12bffff8";
    when 16#00072# => romdata <= X"01000000";
    when 16#00073# => romdata <= X"84100014";
    when 16#00074# => romdata <= X"c2074000";
    when 16#00075# => romdata <= X"80886001";
    when 16#00076# => romdata <= X"02bffffe";
    when 16#00077# => romdata <= X"01000000";
    when 16#00078# => romdata <= X"c2070000";
    when 16#00079# => romdata <= X"c2288000";
    when 16#0007A# => romdata <= X"8400a001";
    when 16#0007B# => romdata <= X"80a60002";
    when 16#0007C# => romdata <= X"12bffff8";
    when 16#0007D# => romdata <= X"c203a064";
    when 16#0007E# => romdata <= X"88007fff";
    when 16#0007F# => romdata <= X"c823a064";
    when 16#00080# => romdata <= X"80a06000";
    when 16#00081# => romdata <= X"c603a068";
    when 16#00082# => romdata <= X"02800014";
    when 16#00083# => romdata <= X"9a100003";
    when 16#00084# => romdata <= X"84100018";
    when 16#00085# => romdata <= X"c2074000";
    when 16#00086# => romdata <= X"80886001";
    when 16#00087# => romdata <= X"02bffffe";
    when 16#00088# => romdata <= X"01000000";
    when 16#00089# => romdata <= X"c2070000";
    when 16#0008A# => romdata <= X"c2288000";
    when 16#0008B# => romdata <= X"8400a001";
    when 16#0008C# => romdata <= X"80a68002";
    when 16#0008D# => romdata <= X"12bffff8";
    when 16#0008E# => romdata <= X"c203a06c";
    when 16#0008F# => romdata <= X"c220c000";
    when 16#00090# => romdata <= X"88013fff";
    when 16#00091# => romdata <= X"8600e004";
    when 16#00092# => romdata <= X"c823a064";
    when 16#00093# => romdata <= X"80a13fff";
    when 16#00094# => romdata <= X"12bffff0";
    when 16#00095# => romdata <= X"c623a068";
    when 16#00096# => romdata <= X"8610001b";
    when 16#00097# => romdata <= X"84100011";
    when 16#00098# => romdata <= X"8600e001";
    when 16#00099# => romdata <= X"c2074000";
    when 16#0009A# => romdata <= X"80886004";
    when 16#0009B# => romdata <= X"02bffffe";
    when 16#0009C# => romdata <= X"01000000";
    when 16#0009D# => romdata <= X"8538a018";
    when 16#0009E# => romdata <= X"c4270000";
    when 16#0009F# => romdata <= X"c408c000";
    when 16#000A0# => romdata <= X"8528a018";
    when 16#000A1# => romdata <= X"80a0a000";
    when 16#000A2# => romdata <= X"32bffff7";
    when 16#000A3# => romdata <= X"8600e001";
    when 16#000A4# => romdata <= X"9fc34000";
    when 16#000A5# => romdata <= X"01000000";
    when 16#000A6# => romdata <= X"10bfff8e";
    when 16#000A7# => romdata <= X"8403a060";
    when 16#000A8# => romdata <= X"426f6f74";
    when 16#000A9# => romdata <= X"6c6f6164";
    when 16#000AA# => romdata <= X"65720a00";
    when 16#000AB# => romdata <= X"00000000";
    when 16#000AC# => romdata <= X"496e7661";
    when 16#000AD# => romdata <= X"6c696420";
    when 16#000AE# => romdata <= X"6d616769";
    when 16#000AF# => romdata <= X"633a2000";
    when 16#000B0# => romdata <= X"496d6167";
    when 16#000B1# => romdata <= X"65206c6f";
    when 16#000B2# => romdata <= X"61646564";
    when 16#000B3# => romdata <= X"0a000000";
    when 16#000B4# => romdata <= X"0a000000";
    when 16#000B5# => romdata <= X"00000000";
    when others => romdata <= (others => '-');
    end case;
  end process;
  -- pragma translate_off
  bootmsg : report_version
  generic map ("ahbrom" & tost(hindex) &
  ": 32-bit AHB ROM Module,  " & tost(bytes/4) & " words, " & tost(abits-2) & " address bits" );
  -- pragma translate_on
  end;
