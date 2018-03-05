# EPROMmer
An EPROM programmer for the Sinclair QL (up to 27512)

This project contains the binary ROM image, source code and schematics for an EPROM programmer. The prototype was built as a pluggable extension card for a standard Sinclair QL machine. Since the software contains critical timings, it cannot be run from internal RAM and should be placed into EPROM itself or a guaranteed zero waitstate RAM expansion (not a Gold Card, since this has different timings). If in RAM, the source should be re-assembled with the variable IO_BASE pointing to the base of the 8255 PIO registers. As built, the software assumes that IO_BASE is at the start of the ROM image + $2000, which is $C2000 on a standard QL without other peripherals.

This EPROM programmer allows for programming of EPROMS from 2764 (8K) up to and including 27512 (64K) using standard or intelligent (fast) programming methods.
