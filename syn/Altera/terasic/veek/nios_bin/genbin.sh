#!/bin/bash

cp ../VEEKsynth.sof ./

cp ../software/VEEKsynth/VEEKsynth.elf ./

sof2flash --epcs --input="VEEKsynth.sof" --output="VEEKsynth_HW.flash"

nios2-elf-objcopy -I srec -O binary "VEEKsynth_HW.flash" "VEEKsynth_HW.bin"

elf2flash --epcs --after="VEEKsynth_HW.flash" --input="VEEKsynth.elf" --output="VEEKsynth_SW.flash"

nios2-elf-objcopy -I srec -O binary "VEEKsynth_SW.flash" "VEEKsynth_SW.bin"

cat "VEEKsynth_HW.bin" "VEEKsynth_SW.bin">"VEEKsynth.bin"


