#
# (C) Copyright 2014-2015 Xilinx, Inc.
# Based on original code:
# (C) Copyright 2007-2014 Michal Simek
# (C) Copyright 2007-2012 PetaLogix Qld Pty Ltd
#
# Michal SIMEK <monstr@monstr.eu>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

proc generate {drv_handle} {
    foreach i [get_sw_cores device_tree] {
        set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
        if {[file exists $common_tcl_file]} {
            source $common_tcl_file
            break
        }
    }
    set proctype [get_property IP_NAME [get_cells -hier [get_sw_processor]]]
    set ip [get_cells -hier $drv_handle]
    set consoleip [get_property CONFIG.console_device [get_os]]
    set config_baud [get_property CONFIG.dt_setbaud [get_os]]

    if {[string match -nocase "$ip" "$consoleip"]} {
        #adding os console property if this is console ip
        set avail_param [list_property [get_cells -hier $drv_handle]]
        # This check is needed because BAUDRATE parameter for psuart is available from
        # 2017.1 onwards
        if {[lsearch -nocase $avail_param "CONFIG.C_BAUDRATE"] >= 0} {
            set baud [get_property CONFIG.C_BAUDRATE [get_cells -hier $drv_handle]]
        } else {
            set baud "115200"
        }
        if {$config_baud} {
            hsi::utils::set_os_parameter_value "console" "ttyPS0,$config_baud"
            if {[string match -nocase $proctype "psv_cortexa72"]} {
                set_drv_prop $drv_handle "current-speed" $config_baud int
            }
        } else {
            hsi::utils::set_os_parameter_value "console" "ttyPS0,$baud"
            if {[string match -nocase $proctype "psv_cortexa72"]} {
                set_drv_prop $drv_handle "current-speed" $baud int
            }
        }
    }
    set uboot_prop [get_property IP_NAME [get_cells -hier $drv_handle]]
    if {[string match -nocase $uboot_prop "psu_uart"] || [string match -nocase $uboot_prop "psu_sbsauart"]} {
        set_drv_prop $drv_handle "u-boot,dm-pre-reloc" "" boolean
    }
    set has_modem [get_property CONFIG.C_HAS_MODEM [get_cells -hier $drv_handle]]
    if {$has_modem == 0} {
         hsi::utils::add_new_property $drv_handle "cts-override" boolean ""
    }
}
