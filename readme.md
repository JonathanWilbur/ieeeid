# IEEE Identifier D Library

* Author: Jonathan M. Wilbur
* Copyright: Jonathan M. Wilbur
* License: [Boost License 1.0](http://www.boost.org/LICENSE_1_0.txt)
* Date: April 29th, 2017
* Version: 0.0.0

**This version will not compile, because it is incomplete.
Version 1.0.0 will be fully-working and thoroughly tested and reviewed.**

This is both a library and a set of related command line tools for all things
related to IEEE Identifiers, which includes what were once referred to as 
"MAC Addresses" (should now be referred to as "Extended Unique Identifiers").

## Why use a strongly-typed IEEE Identifier? Why not just an array of bytes?

You probably could just use an array of bytes, but consider the following:

1. The two least significant bits of the first byte of an Organizationally
Unique Identifier (OUI) must be clear.
2. The second least significant bit of the first byte of a Company ID must be
set.
3. There is a pretty complicated hierarchy of IEEE Identifiers, with some
identifiers sharing numeric spaces, being convertible to one or the other, and
encompassing or being encompassed by another.
4. Strongly-typing a language correlates with fewer bugs \[citation needed\]

## Basic Usage

Every type accepts a sequence of `ubyte`s for the constructor, and every type
provides a few properties.

Example usage:

```d
// Encoding the MAC Address 1C:78:4C:77:13:16
EUI48 eui = new EUI48(0x1C, 0x78, 0x4C, 0x77, 0x13, 0x16);
assert(eui.bytes == [ 0x1C, 0x78, 0x4C, 0x77, 0x13, 0x16 ]);
assert(eui.valid == true);
assert(eui.unicast == true);
assert(eui.multicast == false);
assert(eui.global == true);
assert(eui.local == false);
```

This library prevents you from creating an invalid identifier by requiring a
fixed number of arguments in the constructor. So, for instance, you could not
compile this code:

```d
OUI24 oui = new OUI24(0x12, 0x34, 0x56, 0x78); // An OUI should be three bytes!
```

## Types Supported

* Company ID (CID)
* 24-Bit Organizationally Unique Identifier (OUI-24)
* 36-Bit Organizationally Unique Identifier (OUI-36)
* MAC Address Large Block Identifier (MA-L)
* MAC Address Medium Block Identifier (MA-M)
* MAC Address Small Block Identifier (MA-S)
* 48-Bit Extended Unique Identifier (EUI-48)
* 64-Bit Extended Unique Identifier (EUI-64)

## Compile and Install

**This version will not compile, because it is incomplete.
Version 1.0.0 will be fully-working and thoroughly tested and reviewed.**

~~As of right now, there are no build scripts, since the source is a single file,
but there will be build scripts in the future, just for the sake of consistency
across all similar projects.~~

~~For the moment, you can simply compile by changing to the `source` directory and
running `dmd -lib ieeeid.d`.~~

## See Also

* [Guidelines for Use Organizationally Unique Identifier (OUI) and Company ID (CID)](https://standards.ieee.org/develop/regauth/tut/eui.pdf)
* [Guidelines for 48-Bit Global Identifier (EUI-48)](https://standards.ieee.org/develop/regauth/tut/eui48.pdf)
* [Guidelines for 64-Bit Global Identifier (EUI-64)](https://standards.ieee.org/develop/regauth/tut/eui64.pdf)

## Contact Me

If you would like to suggest fixes or improvements on this library, please just
comment on this on GitHub. If you would like to contact me for other reasons,
please email me at [jonathan@wilbur.space](mailto:jonathan@wilbur.space). :boar: