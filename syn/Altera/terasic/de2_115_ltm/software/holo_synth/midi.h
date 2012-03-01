/*
 * midi.h
 *
 *  Created on: 18/04/2011
 *      Author: mib
 */

#ifndef MIDI_H_
#define MIDI_H_

#include <alt_types.h>

char synth_ctrls[64][16] = {
		 "l[0][0]", //synth_data[0]
		 "l[1][0]", //synth_data[1]
		 "l[2][0]", //synth_data[2]
		 "l[3][0]", //synth_data[3]
		 "l[0][1]", //synth_data[4]
		 "l[1][1]", //synth_data[5]
		 "l[2][1]", //synth_data[6]
		 "l[3][1]", //synth_data[7]
		// 1 -- b001
		 "l[0][2]", //synth_data[8]
		 "l[1][2]", //synth_data[9]
	     "l[2][2]", // synth_data[10]
		 "l[3][2]", //synth_data[11]
		 "l[0][3]", //synth_data[12]
		 "l[1][3]", //synth_data[13]
		 "l[2][3]", //synth_data[14]
		 "l[3][3]", //synth_data[15]
		// 2 -- b010
		 "r[0][0]", //synth_data[16]
		 "r[0][1]", //synth_data[17]
		 "r[0][2]", //synth_data[18]
		 "r[0][3]", //synth_data[19]
		 "r[1][0]", //synth_data[20]
		 "r[1][1]", //synth_data[21]
		 "r[1][2]", //synth_data[22]
		 "r[1][3]", //synth_data[23]
		// 3 -- b011
		 "r[2][0]", //synth_data[24]
		 "r[2][1]", //synth_data[25]
		 "r[2][2]", //synth_data[26]
		 "r[2][3]", //synth_data[27]
		 "r[3][0]", //synth_data[28]
		 "r[3][1]", //synth_data[29]
		 "r[3][2]", //synth_data[30]
		 "r[3][3]", //synth_data[31]
		// 4 -- b100
		 "osc_ct[1]", //synth_data[32]
		 "osc_ct[0]", //synth_data[33]
		 "osc_ft[1]", //synth_data[34]
		 "osc_ft[0]", //synth_data[35]
		 "osc_lvl[0]", //synth_data[36]
		 "osc_lvl[1]", //synth_data[37]
		 "osc_mod[0]", //synth_data[38]
		 "osc_mod[1]", //synth_data[39]
			// 5 -- b101
		 "base_ct[1]", //synth_data[40]
		 "base_ct[0]", //synth_data[41]
		 "base_ft[1]", //synth_data[42]
		 "base_ft[0]", //synth_data[43]
		 "osc_feedb[0]", //synth_data[44]
		 "osc_feedb[1]", //synth_data[45]
		 "k_scale[1]", //synth_data[46]
		 "k_scale[0]", //synth_data[47]
			// 6 -- b110
		 "o_offs[1]", //synth_data[48]
		 "o_offs[0]", //synth_data[49]
		 "pb_value", //synth_data[50]
		 "m_vol", //synth_data[51]
		 " "," "," "," "," "," "," "," "," "," "," "," "
};
char midi_buf[64][16] = {
	"r[0][0]", //midi_dat[0]
	"l[0][0]", //midi_dat[1]
	"r[0][1]", //midi_dat[2]
	"l[0][1]", //midi_dat[3]
	"r[0][2]", //midi_dat[4]
	"l[0][2]", //midi_dat[5]
	"r[0][3]", //midi_dat[6]
	"l[0][3]", //midi_dat[7]
	// 1 -- b001
	 "r[1][0]", //midi_dat[8]
	 "l[1][0]", //midi_dat[9]
	 "r[1][1]", // midi_dat[10]
	 "l[1][1]", //midi_dat[11]
	 "r[1][2]", //midi_dat[12]
	 "l[1][2]", //midi_dat[13]
	 "r[1][3]", //midi_dat[14]
	 "l[1][3]", //midi_dat[15]
	// 2 -- b010
	 "r[2][0]", //midi_dat[16]
	 "l[2][0]", //midi_dat[17]
	 "r[2][1]", //midi_dat[18]
	 "l[2][1]", //midi_dat[19]
	 "r[2][2]", //midi_dat[20]
	 "l[2][2]", //midi_dat[21]
	 "r[2][3]", //midi_dat[22]
	 "l[2][3]", //midi_dat[23]
	// 3 -- b011
	 "r[3][0]", //midi_dat[24]
	 "l[3][0]", //midi_dat[25]
	 "r[3][1]", //midi_dat[26]
	 "l[3][1]", //midi_dat[27]
	 "r[3][2]", //midi_dat[28]
	 "l[3][2]", //midi_dat[29]
	 "r[3][3]", //midi_dat[30]
	 "l[3][3]", //midi_dat[31]
	// 4 -- b100
	 "osc_ct[0]", //midi_dat[32]
	 "osc_ft[0]", //midi_dat[33]
	 "osc_lvl[0]", //midi_dat[34]
	 "osc_mod[0]", //midi_dat[35]
	 "osc_feedb[0]", //midi_dat[36]
	 "osc_kscale[0]", //midi_dat[37]
	 "osc_offset[0]", //midi_dat[38]
	 "osc_base_ct[0]", //midi_dat[39]
		// 5 -- b101
	 "osc_base_ft[0]", //midi_dat[40]
	 "pb_range", //midi_dat[41]
	 "m_vol", //midi_dat[42]
	 "osc_ct[1]", //midi_dat[32]
	 "osc_ft[1]", //midi_dat[33]
	 "osc_lvl[1]", //midi_dat[34]
	 "osc_mod[1]", //midi_dat[35]
	 "osc_feedb[1]", //midi_dat[36]
		// 6 -- b110
	 "osc_kscale[1]", //midi_dat[37]
	 "osc_offset[1]", //midi_dat[38]
	 "osc_base_ct[1]", //midi_dat[39]
	 "osc_base_ft[1]", //midi_dat[40]
	 " "," "," "," "," "," "," "," "," "," "," "," "
};

#endif /* MIDI_H_ */
