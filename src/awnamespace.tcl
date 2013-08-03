package require Tcl 8.4


####  namespace for 4461/2816 params  ####
namespace eval ::aw {
    
    #################
    # common to all #
    #################
    set block_term                  65535        
    set block_size		            0x20000
    set audio_24bit_offset		    0x200
    set audio_firstblock_offset	    24
    
    set diskformat_location		    0x1d8f2
    set diskformat_size			    4
    
    set disk_max_audio_blocks	    5621
    
    set aiff_header_size            54
    set wav_header_size             44
    
    
    ############################
    # AW4416 / AW2816 specific #
    ############################
    
    set diskinfo_location           0x15800
    set diskinfo_size			    256
    set diskinfo_songcount_offset   0x14
    set diskinfo_disknum_offset     0x1b
    set diskinfo_audio_offset	    0x0a
    set diskinfo_previous_offset    0x48
    set diskinfo_offset_offset      0x4a
    
    set songblock_location		    0x55800
    set songblock_size			    0x200000
    
    set songinfo_location		    0x55800
    set songinfo_size			    80
    set songinfo_max_count		    256
    set songinfo_name_offset	    0x00
    set songinfo_name_size		    24
    set songinfo_samplerate_offset  0x44
    set songinfo_bitdepth_offset    0x45
    set songinfo_date_offset        0x40
    
    set trackinfo_offset            0x25c0
    set trackinfo_size			    32
    set trackinfo_max_count		    [expr (16 * 8)]
    set trackinfo_name_offset	    0
    set trackinfo_name_size			16
    set trackinfo_region_offset		0x14
    set trackinfo_sample_offset		0x16
    
    set regioninfo_offset			0x3800 
    set regioninfo_size				48
    set regioninfo_name_offset		0x00
    set regioninfo_name_size		8
    set regioninfo_start_offset		0x0c
    set regioninfo_total_offset		0x10
    set regioninfo_offset_offset	0x14
    set regioninfo_prev_offset		0x1c
    set regioninfo_next_offset		0x1e
    set regioninfo_map_offset		0x20
    set regioninfo_alternate_offset	0x28
    
    set mapinfo_offset				0x9b000
    set mapinfo_size				8
}


####  namespace for AW16G specific params  ####
namespace eval ::awg {
    set diskinfo_location			0x15800
    set diskinfo_size				256
    set diskinfo_songcount_offset	0x14
    set diskinfo_disknum_offset		0x23
    set diskinfo_audio_offset		0x2a
    set diskinfo_previous_offset	0x2c
    set diskinfo_offset_offset		0x2e
    
    set songblock_location			0x515800
    set songblock_size				0x17f800
    
    set songinfo_location			0x35800
    set songinfo_size				128
    set songinfo_max_count			1000
    set songinfo_name_offset		0x00
    set songinfo_name_size			24
    set songinfo_start_offset		0x0c
    set songinfo_offset_offset		0x20
    
    set trackinfo_offset			0x800
    set trackinfo_size				16
    set trackinfo_max_count			[expr (16 * 8)]
    set trackinfo_name_offset		0x00
    set trackinfo_name_size			8
    set trackinfo_region_offset		0x0c
    set trackinfo_sample_offset		0x0e
    
    set regioninfo_offset			0x3800 
    set regioninfo_size				48
    set regioninfo_name_offset		0x00
    set regioninfo_name_size		8
    set regioninfo_start_offset		0x0c
    set regioninfo_total_offset		0x10
    set regioninfo_offset_offset	0x14
    set regioninfo_prev_offset		0x1c
    set regioninfo_next_offset		0x1e
    set regioninfo_map_offset		0x20
    set regioninfo_alternate_offset	0x28
    
    set mapinfo_offset				0x9b000
    set mapinfo_size				8
}

