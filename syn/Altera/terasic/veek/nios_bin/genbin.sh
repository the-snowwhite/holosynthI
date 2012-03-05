#!/bin/bash

cp ../VEEKsynth.sof ./

cp ../software/VEEKSynth/VEEKSynth.elf ./

sof2flash --epcs --input="VEEKsynth.sof" --output="VEEKSynth_HW.flash"

nios2-elf-objcopy -I srec -O binary "VEEKSynth_HW.flash" "VEEKSynth_HW.bin"

elf2flash --epcs --after="VEEKSynth_HW.flash" --input="VEEKSynth.elf" --output="VEEKSynth_SW.flash"

nios2-elf-objcopy -I srec -O binary "VEEKSynth_SW.flash" "VEEKSynth_SW.bin"

cat "VEEKSynth_HW.bin" "VEEKSynth_SW.bin">"VEEKSynth.bin"


