local TYP_SECT = 0x8	-- 0b1000
local TYP_MS = 0xF		-- 0b1111
local TYP_AC = 0xC		-- 0b1100
local TYP_STAT = 0xA 	-- 0b1010
local TYP_FILT = 0x4		-- 0b0100
local TYP_MASK = 0x78	-- 0b01111000
local EOM_MASK = 0x80 	-- 0b10000000
local BLOCK_NUM_MASK = 0x0F			-- 0b00001111
local BLOCK_TTL_NUM_MASK = 0x0F	-- 0b00001111

local VALS_BOOL	= {[0] = "False", [1] = "True"}
local TYP_STR = {[TYP_SECT] = "Sector Report", [TYP_MS] = "Mode S Report", [TYP_AC] = "ATCRBS Report", [TYP_FILT] = "Blank Area Report"}

function format_time(t)
	local s = t * 3600.0 / 2^15
	return string.format("%.2d:%.2d:%f", s/(60*60), s/60%60, s%60)
end
function format_range(v)
	local r = v / 128.0
	return string.format("%f [NM]", r)
end
function format_azimuth(v)
	local r = v * 360.0 / 2^14
	return string.format("%f [deg]", r)
end

-- *** Step 1 : プロトコルの宣言 ***
jcab_proto = Proto("jcab", "JCAB SSR")
local f = jcab_proto.fields
-- *** Step 2 : フィールドの宣言 ***

f.len = ProtoField.uint16("jcab.length", "Message Length")

f.type = ProtoField.uint8("jcab.type", "Type", base.HEX, TYP_STR, TYP_MASK)

-- field definition of sector message
f.sect = ProtoField.uint32("jcab.sector", "Sector Message")
f.sect_num = ProtoField.uint8("jcab.sect_num", "Sector number")
f.sect_eom = ProtoField.uint8("jcab.sect_eom", "Sector EOM", base.HEX, VALS_BOOL, EOM_MASK)
f.sect_block_num = ProtoField.uint8("jcab.sect_block_num", "Block number", base.DEC, nil, BLOCK_NUM_MASK)
f.sect_block_total_num = ProtoField.uint8("jcab.sect_block_total_num", "Total block number", base.DEC)

-- field definition of atcrbs message
f.ac = ProtoField.bytes("jcab.ac", "ATCRBS Message")
f.ac_rr		= ProtoField.uint8("jcab.ac_rr", "Rr (Radar Reinforced)", base.HEX, {[0] = "not reinforced", [1] = "reinforced"}, 0x01)
f.ac_ott	= ProtoField.uint8("jcab.ac_ott", "OTT (radar performance monitor)", base.HEX, VALS_BOOL, 0x10)
f.ac_emg	= ProtoField.uint8("jcab.ac_emg", "EMG (emergency)", base.HEX, VALS_BOOL, 0x08)
f.ac_rof	= ProtoField.uint8("jcab.ac_rof", "ROF (radio failure)", base.HEX, VALS_BOOL, 0x04)
f.ac_hij		= ProtoField.uint8("jcab.ac_hij", "HIJ (hijack)", base.HEX, VALS_BOOL, 0x02)
f.ac_spm	= ProtoField.uint8("jcab.ac_spm", "SPM (simulated target)", base.HEX, VALS_BOOL, 0x01)
f.ac_time	= ProtoField.uint16("jcab.ac_time", "Timestamp", base.DEC)
f.ac_bhc	= ProtoField.uint8("jcab.ac_bhc", "BHC (beacon hit count)", base.DEC)
f.ac_range	= ProtoField.uint16("jcab.ac_range", "Range", base.DEC)
f.ac_azimuth	= ProtoField.uint16("jcab.ac_azimuth", "Azimuth", base.DEC)
f.ac_acode	= ProtoField.uint16("jcab.ac_acode", "Mode 3/A code", base.HEX)
f.ac_dbc		= ProtoField.uint16("jcab.ac_dbc", "DBC (discrete beacon code", base.HEX, VALS_BOOL, 0x4000)
f.ac_spi			= ProtoField.uint16("jcab.ac_spi", "SPI (special puropose indicator)", base.HEX, VALS_BOOL, 0x2000)
f.ac_va			= ProtoField.uint16("jcab.ac_va", "Va", base.HEX, {[0] = "invalid", [1] = "valid"}, 0x1000)
f.ac_code		= ProtoField.uint16("jcab.ac_code", "Mode 3/A code", base.OCT, nil, 0x0FFF)
f.ac_ccode	= ProtoField.uint16("jcab.ac_ccode", "Mode C code (Altitude)", base.HEX)
f.ac_vc			= ProtoField.uint16("jcab.ac_vc", "Vc", base.HEX, {[0] = "invalid", [1] = "valid"}, 0x4000)
f.ac_alt		= ProtoField.int16("jcab.ac_alt", "Altitude (ft)", base.DEC, nil, 0x3FFF)
f.ac_eom	= ProtoField.uint8("jcab.ac_eom", "Sector EOM", base.HEX, VALS_BOOL, EOM_MASK)
f.ac_aconf	= ProtoField.uint16("jcab.ac_aconf", "Mode 3/A confidence", base.HEX, nil, 0x0FFF)

-- field definition of mode s message
f.ms = ProtoField.bytes("jcab.ms", "Mode S Message")
f.ms_ps		= ProtoField.uint8("jcab.ms_ps", "PS (Sensor Status)", base.HEX, {[0] = "n.a.", [1] = "n.a.", [2] = "OK", [3] = "n.a."}, 0x06)
f.ms_rr		= ProtoField.uint8("jcab.ms_rr", "Rr (Radar Reinforced)", base.HEX, {[0] = "not reinforced", [1] = "reinforced"}, 0x01)
f.ms_c		= ProtoField.uint8("jcab.ms_c", "C (Combined)", base.HEX, {[0] = "not combined with ATCRBS target", [1] = "combined with ATCRBS target"}, 0x80)
f.ms_ott	= ProtoField.uint8("jcab.ms_ott", "OTT (radar performance monitor)", base.HEX, VALS_BOOL, 0x10)
f.ms_emg	= ProtoField.uint8("jcab.ms_emg", "EMG (emergency)", base.HEX, VALS_BOOL, 0x08)
f.ms_rof	= ProtoField.uint8("jcab.ms_rof", "ROF (radio failure)", base.HEX, VALS_BOOL, 0x04)
f.ms_hij		= ProtoField.uint8("jcab.ms_hij", "HIJ (hijack)", base.HEX, VALS_BOOL, 0x02)
f.ms_spm	= ProtoField.uint8("jcab.ms_spm", "SPM (simulated target)", base.HEX, VALS_BOOL, 0x01)
f.ms_time	= ProtoField.uint16("jcab.ms_time", "Timestamp", base.DEC)
f.ms_bds10	= ProtoField.uint16("jcab.ms_bds10", "BDS1,0", base.HEX)
f.ms_ca4	= ProtoField.uint8("jcab.ms_ca4", "CA4", base.HEX, nil, 0x40)
f.ms_ca3	= ProtoField.uint8("jcab.ms_ca3", "CA3", base.HEX, nil, 0x20)
f.ms_ca2	= ProtoField.uint8("jcab.ms_ca2", "CA2", base.HEX, nil, 0x10)
f.ms_ca1	= ProtoField.uint8("jcab.ms_ca1", "CA1", base.HEX, nil, 0x08)
f.ms_range	= ProtoField.uint16("jcab.ms_range", "Range", base.DEC)
f.ms_azimuth	= ProtoField.uint16("jcab.ms_azimuth", "Azimuth", base.DEC)
f.ms_acode	= ProtoField.uint16("jcab.ms_acode", "Mode 3/A code", base.HEX)
f.ms_dbc		= ProtoField.uint16("jcab.ms_dbc", "DBC (discrete beacon code", base.HEX, VALS_BOOL, 0x4000)
f.ms_ma		= ProtoField.uint16("jcab.ms_ma", "MA (Mode 3/A code reply)", base.HEX, VALS_BOOL, 0x2000)
f.ms_va			= ProtoField.uint16("jcab.ms_va", "Va (Mode 3/A code validity)", base.HEX, {[0] = "invalid", [1] = "valid"}, 0x1000)
f.ms_code		= ProtoField.uint16("jcab.ms_code", "Mode 3/A code", base.OCT, nil, 0x0FFF)
f.ms_alt	= ProtoField.uint16("jcab.ms_alt", "Mode C code (Altitude)", base.HEX)
f.ms_vc			= ProtoField.uint16("jcab.ms_vc", "Vc (Mode C code Validity)", base.HEX, {[0] = "invalid", [1] = "valid"}, 0x4000)
f.ms_alt		= ProtoField.int16("jcab.ms_alt", "Altitude (ft)", base.DEC, nil, 0x3FFF)
f.ms_adrr	= ProtoField.uint32("jcab.ms_addr", "Mode S Address", base.HEX)
f.ms_vr			= ProtoField.uint16("jcab.ms_vr", "Vr (RA Info Validity)", base.HEX, {[0] = "invalid", [1] = "valid"}, 0x4000)
f.ms_da		= ProtoField.uint16("jcab.ms_da", "DA (Duplicated Address)", base.HEX, VALS_BOOL, 0x2000)
f.ms_vs			= ProtoField.uint16("jcab.ms_vs", "Vs (Mode S Address Validity)", base.HEX, {[0] = "invalid", [1] = "valid"}, 0x1000)
f.ms_addr_hi	= ProtoField.uint16("jcab.ms_addr_hi", "Mode S Address (bit 23..12)", base.HEX, nil, 0x0FFF)
local VALS_FS	= {
	[0]="no alert, no spi, target airborne", 
	[1]="no alert, no spi, target on ground", 
	[2]="alert, no spi, target airborne", 
	[3]="alert, no spi, target on ground", 
	[4]="alert, spi, target airborne/on ground", 
	[5]="no alert, spi, target airborne/on ground", 
	[6]="unused", 
	[7]="n.a.", 
}
f.ms_fs			= ProtoField.uint16("jcab.ms_fs", "FS (Flight Status)", base.HEX, VALS_FS, 0x1000)
f.ms_addr_lo	= ProtoField.uint16("jcab.ms_addr_lo", "Mode S Address (bit 11..0)", base.HEX, nil, 0x0FFF)
f.ms_bds30	= ProtoField.uint64("jcab.ms_bds30", "BDS3,0", base.HEX)
f.ms_ara		= ProtoField.uint8("jcab.ms_ara", "ARA", base.HEX, nil, 0x7F)
f.ms_rac		= ProtoField.uint8("jcab.ms_rac", "RAC", base.HEX, nil, 0xF0)
f.ms_rat		= ProtoField.uint8("jcab.ms_rat", "RAT", base.HEX, nil, 0x08)
f.ms_mte		= ProtoField.uint8("jcab.ms_mte", "MTE", base.HEX, nil, 0x04)
f.ms_tti		= ProtoField.uint8("jcab.ms_tti", "TTI", base.HEX, nil, 0x03)
f.ms_tid_hi	= ProtoField.uint16("jcab.ms_tid_hi", "TID (bit 23..12)", base.HEX, nil, 0x0FFF)
f.ms_tid_lo	= ProtoField.uint16("jcab.ms_tid_lo", "TID (bit 11..0)", base.HEX, nil, 0x0FFF)
f.ms_eom	= ProtoField.uint8("jcab.ms_eom", "Sector EOM", base.HEX, VALS_BOOL, EOM_MASK)

-- field definition of status message
f.stat = ProtoField.bytes("jcab.stat", "Status Message")
local VALS_ALARM	= {[0] = "Normal(0)", [1] = "Alarm"}
local VALS_OPE	= {[0] = "Maintainance(0)", [1] = "Operation"}
f.stat_rpm1	= ProtoField.uint16("jcab.stat_rpm1", "RPM #1", base.HEX, VALS_ALARM, 0x0400)
f.stat_rpm2	= ProtoField.uint16("jcab.stat_rpm1", "RPM #2", base.HEX, VALS_ALARM, 0x0200)
f.stat_ant_main	= ProtoField.uint16("jcab.stat_ant_main", "Antenna Main", base.HEX, VALS_OPE, 0x0100)
f.stat_ant_sub	= ProtoField.uint16("jcab.stat_ant_sub", "Antenna Sub", base.HEX, VALS_OPE, 0x0080)
f.stat_ssrcha	= ProtoField.uint16("jcab.stat_ssrcha", "SSR Ch-A", base.HEX, VALS_OPE, 0x0040)
f.stat_ssrchb	= ProtoField.uint16("jcab.stat_ssrchb", "SSR Ch-B", base.HEX, VALS_OPE, 0x0020)
f.stat_enccha	= ProtoField.uint16("jcab.stat_enccha", "Encoder Ch-A", base.HEX, VALS_OPE, 0x0010)
f.stat_encchb	= ProtoField.uint16("jcab.stat_encchb", "Encoder Ch-B", base.HEX, VALS_OPE, 0x0008)
f.stat_spm	= ProtoField.uint16("jcab.stat_spm", "SPM (simulated target)", base.HEX, VALS_OPE, 0x0001)
f.stat_time	= ProtoField.uint16("jcab.stat_time", "Timestamp", base.DEC)
f.stat_psr	= ProtoField.uint16("jcab.stat_psr", "PSR System Down", base.HEX, VALS_BOOL, 0x4000)
f.stat_ssr	= ProtoField.uint16("jcab.stat_ssr", "SSR System Down", base.HEX, VALS_BOOL, 0x1000)
f.stat_mnm	= ProtoField.uint16("jcab.stat_mnm", "MNM (Message Number Monitor)", base.HEX, {[0]="Not overload", [1]="Overload"}, 0x0800)
f.stat_bof	= ProtoField.uint16("jcab.stat_bof", "BOF (Buffer Overflow)", base.HEX, VALS_BOOL, 0x0400)
f.stat_psrblank	= ProtoField.uint16("jcab.stat_psrblank", "PSR Blank Area", base.HEX, nil, 0x01E0)
f.stat_ssrblank	= ProtoField.uint16("jcab.stat_ssrblank", "SSR Blank Area", base.HEX, nil, 0x001E)
f.stat_eom	= ProtoField.uint16("jcab.stat_eom", "EOM", base.HEX, VALS_BOOL, 0x8000)
f.stat_siteid	= ProtoField.uint16("jcab.stat_siteid", "Radar Site ID", base.DEC, nil, 0x007E)
f.stat_north	= ProtoField.uint16("jcab.stat_north", "North", base.HEX, VALS_BOOL, 0x0001)

-- field definition of blank area message
f.filt = ProtoField.bytes("jcab.filt", "Blank Area Message")
f.filt_blanknum	= ProtoField.uint16("jcab.filt_blanknum", "Blank Number", base.DEC, nil, 0x18)
f.filt_time			= ProtoField.uint16("jcab.filt_time", "Timestamp", base.DEC)
f.filt_startrange	= ProtoField.uint16("jcab.filt_startrange", "Start Range", base.DEC, nil, 0x7FFF)
f.filt_startazimuth	= ProtoField.uint16("jcab.filt_startazimuth", "Start Azimuth", base.DEC, nil, 0x3FFF)
f.filt_endrange	= ProtoField.uint16("jcab.filt_endrange", "End Range", base.DEC, nil, 0x7FFF)
f.filt_endazimuth	= ProtoField.uint16("jcab.filt_endazimuth", "End Azimuth", base.DEC, nil, 0x3FFF)
f.filt_eom	= ProtoField.uint16("jcab.filt_eom", "EOM", base.HEX, VALS_BOOL, 0x8000)

-- dissector
function jcab_proto.dissector(buffer,pinfo,tree)
	local subtree = tree:add (jcab_proto, buffer(), "JCAB SSR Target Message ("..buffer:len()..")")
	
	local total_len = buffer:len()
	local base_addr = 0
	local expected_len = buffer(0,2):uint()
	subtree:add(f.len, buffer(0,2))
	base_addr = base_addr + 2
	
	if (expected_len < total_len) then
		-- message too long
	elseif (expected_len > total_len) then
		-- message too short
	end
	
	while (base_addr < total_len or base_addr < expected_len) do
		local msg_type = bit.rshift(buffer(base_addr,1):uint(), 3)
		if (msg_type == TYP_SECT) then
			-- sector message
			local sect_buf = buffer(base_addr,4)
			base_addr = base_addr + 4
			local sect_tree = subtree:add (f.sect, sect_buf, "Sector Message (num="..sect_buf(1,1):uint()..")")
			sect_tree:add(f.type, sect_buf(0,1))
			sect_tree:add(f.sect_num, sect_buf(1,1))
			sect_tree:add(f.sect_eom, sect_buf(2,1))
			sect_tree:add(f.sect_block_num, sect_buf(2,1))
			sect_tree:add(f.sect_block_total_num, sect_buf(3,1))
		elseif (msg_type == TYP_MS) then
			-- mode s message
			local subbuf = buffer(base_addr, 18)
			base_addr = base_addr + 18
			local ms_tree = subtree:add (f.ms, subbuf)
			ms_tree:add(f.type, subbuf(0,1))
			ms_tree:add(f.ms_ps, subbuf(0,1))
			ms_tree:add(f.ms_rr, subbuf(0,1))
			ms_tree:add(f.ms_ott, subbuf(1,1))
			ms_tree:add(f.ms_emg, subbuf(1,1))
			ms_tree:add(f.ms_rof, subbuf(1,1))
			ms_tree:add(f.ms_hij, subbuf(1,1))
			ms_tree:add(f.ms_spm, subbuf(1,1))
			ms_tree:add(f.ms_time, subbuf(2,2)):append_text(" ("..format_time(subbuf(2,2):uint())..")")
			local bds10_tree = ms_tree:add(f.ms_bds10, subbuf(4,2))
			bds10_tree:add(f.ms_ca4, subbuf(5,1))
			bds10_tree:add(f.ms_ca3, subbuf(5,1))
			bds10_tree:add(f.ms_ca2, subbuf(5,1))
			bds10_tree:add(f.ms_ca1, subbuf(5,1))
			ms_tree:add(f.ms_range, subbuf(6,2)):append_text(" ("..format_range(subbuf(6,2):uint())..")")
			ms_tree:add(f.ms_azimuth, subbuf(8,2)):append_text(" ("..format_azimuth(subbuf(8,2):uint())..")")
			local acode_tree = ms_tree:add(f.ms_acode, subbuf(10,2))
			acode_tree:add(f.ms_dbc, subbuf(10,2))
			acode_tree:add(f.ms_ma, subbuf(10,2))
			acode_tree:add(f.ms_va, subbuf(10,2))
			acode_tree:add(f.ms_code, subbuf(10,2))
			local ccode_tree = ms_tree:add(f.ms_ccode, subbuf(12,2))
			ccode_tree:add(f.ms_vc, subbuf(12,2))
			ccode_tree:add(f.ms_alt, subbuf(12,2))
			ms_tree:add(f.ms_eom, subbuf(14,2))
			ms_tree:add(f.ms_aconf, subbuf(14,2))
			-- mode s addr
			local addr_buf = subbuf(14,4)
			local addr_str = string.format("%#3X%3X", bit32.band(addr_buf(0,2):uint(), 0xFFF), bit32.band(addr_buf(2,2):uint(), 0xFFF))
			local addr_tree = ms_tree:add(f.ms_adrr, addr_buf):append_text(" ("..addr_str..")")
			addr_tree:add(f.ms_vr, addr_buf(0,2))
			addr_tree:add(f.ms_da, addr_buf(0,2))
			addr_tree:add(f.ms_vs, addr_buf(0,2))
			addr_tree:add(f.ms_fs, addr_buf(2,2))
			addr_tree:add(f.ms_addr_hi, addr_buf(0,2))
			addr_tree:add(f.ms_addr_lo, addr_buf(2,2))
			-- datalink
			if  not (bit32.band(addr_buf(0,1):uint(), 0x40) == 0) then -- if Vr!=0
				local bds30_buf = subbuf(18,8)
				base_addr = base_addr + 4 -- 4 more bytes for bds30
				local bds30_tree = ms_tree:add(f.ms_bds30, subbuf())
				bds30_tree:add(f.ms_ara, subbuf(0,2))
				bds30_tree:add(f.ms_rac, subbuf(2,2))
				bds30_tree:add(f.ms_rat, subbuf(2,2))
				bds30_tree:add(f.ms_mte, subbuf(2,2))
				bds30_tree:add(f.ms_tti, subbuf(2,2))
				bds30_tree:add(f.ms_tid_hi, subbuf(4,2))
				bds30_tree:add(f.ms_tid_lo, subbuf(6,2))
				bds30_tree:add(f.ms_eom, subbuf(6,1))
			else
				addr_tree:add(f.ms_eom, addr_buf(2,1))
			end
		elseif (msg_type == TYP_AC) then
			-- mode a/c message
			local subbuf = buffer(base_addr, 16)
			base_addr = base_addr + 16
			local ac_tree = subtree:add (f.ac, subbuf)
			ac_tree:add(f.type, subbuf(0,1))
			ac_tree:add(f.ac_rr, subbuf(0,1))
			ac_tree:add(f.ac_ott, subbuf(1,1))
			ac_tree:add(f.ac_emg, subbuf(1,1))
			ac_tree:add(f.ac_rof, subbuf(1,1))
			ac_tree:add(f.ac_hij, subbuf(1,1))
			ac_tree:add(f.ac_spm, subbuf(1,1))
			ac_tree:add(f.ac_time, subbuf(2,2)):append_text(" ("..format_time(subbuf(2,2):uint())..")")
			ac_tree:add(f.ac_bhc, subbuf(5,1))
			ac_tree:add(f.ac_range, subbuf(6,2)):append_text(" ("..format_range(subbuf(6,2):uint())..")")
			ac_tree:add(f.ac_azimuth, subbuf(8,2)):append_text(" ("..format_azimuth(subbuf(8,2):uint())..")")
			local acode_tree = ac_tree:add(f.ac_acode, subbuf(10,2))
			acode_tree:add(f.ac_dbc, subbuf(10,2))
			acode_tree:add(f.ac_spi, subbuf(10,2))
			acode_tree:add(f.ac_va, subbuf(10,2))
			acode_tree:add(f.ac_code, subbuf(10,2))
			local ccode_tree = ac_tree:add(f.ac_ccode, subbuf(12,2))
			ccode_tree:add(f.ac_vc, subbuf(12,2))
			ccode_tree:add(f.ac_alt, subbuf(12,2))
			ac_tree:add(f.ac_eom, subbuf(14,2))
			ac_tree:add(f.ac_aconf, subbuf(14,2))
		elseif (msg_type == TYP_STAT) then
			-- status message
			local subbuf = buffer(base_addr, 8)
			base_addr = base_addr + 8
			local stat_tree = subtree:add (f.stat, subbuf)
			stat_tree:add(f.type, subbuf(0,1))
			stat_tree:add(f.stat_rpm1, subbuf(0,2))
			stat_tree:add(f.stat_rpm2, subbuf(0,2))
			stat_tree:add(f.stat_ant_main, subbuf(0,2))
			stat_tree:add(f.stat_ant_sub, subbuf(0,2))
			stat_tree:add(f.stat_ssrcha, subbuf(0,2))
			stat_tree:add(f.stat_ssrchb, subbuf(0,2))
			stat_tree:add(f.stat_enccha, subbuf(0,2))
			stat_tree:add(f.stat_encchb, subbuf(0,2))
			stat_tree:add(f.stat_spm, subbuf(0,2))
			stat_tree:add(f.stat_time, subbuf(2,2))
			stat_tree:add(f.stat_psr, subbuf(4,2))
			stat_tree:add(f.stat_ssr, subbuf(4,2))
			stat_tree:add(f.stat_mnm, subbuf(4,2))
			stat_tree:add(f.stat_bof, subbuf(4,2))
			stat_tree:add(f.stat_psrblank, subbuf(4,2))
			stat_tree:add(f.stat_ssrblank, subbuf(4,2))
			stat_tree:add(f.stat_eom, subbuf(6,2))
			stat_tree:add(f.stat_siteid, subbuf(6,2))
			stat_tree:add(f.stat_north, subbuf(6,2))

		elseif (msg_type == TYP_FILT) then
			-- filter message
			local subbuf = buffer(base_addr, 12)
			base_addr = base_addr + 12
			local filt_tree = subtree:add (f.filt, subbuf)
			filt_tree:add(f.type, subbuf(0,1))
			filt_tree:add(f.filt_blanknum, subbuf(1,1))
			filt_tree:add(f.filt_time, subbuf(2,2)):append_text(" ("..format_time(subbuf(2,2):uint())..")")
			filt_tree:add(f.filt_startrange, subbuf(4,2)):append_text(" ("..format_range(subbuf(4,2):uint())..")")
			filt_tree:add(f.filt_startazimuth, subbuf(6,2)):append_text(" ("..format_azimuth(subbuf(6,2):uint())..")")
			filt_tree:add(f.filt_endrange, subbuf(8,2)):append_text(" ("..format_range(subbuf(8,2):uint())..")")
			filt_tree:add(f.filt_eom, subbuf(10,2))
			filt_tree:add(f.filt_endazimuth, subbuf(10,2)):append_text(" ("..format_azimuth(bit32.band(subbuf(10,2):uint(), 0x3FFF))..")")
		else
			-- undecodable
		end
	end
	
end
-- *** Step 5 :プロトコルの登録 ***
DissectorTable.get("udp.port"):add(22222, jcab_proto) 
