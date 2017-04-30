/**
    Prints information about an IEEE identifier. Usage: ieeeinfo [id]

    The term 'EUI-48' is trademarked by the IEEE. From their
    $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui48.pdf,
        Guidelines for 48-Bit Global Identifier (EUI-48)),
    $(BR)
    $(P
        $(I
            "The term EUI-48 is trademarked by IEEE and should be so identified. Organizations
            are allowed limited use of this term for commercial purposes. Where such use is
            identification of features or capabilities specified within a standard or for claiming
            compliance to an IEEE standard this may be done without approval of IEEE, but
            other use of this term must be reviewed and approved by the IEEE RAC."
        )
    )

    Author: Jonathan M. Wilbur
    Copyright: Jonathan M. Wilbur
    Date: April 30th, 2017
    License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Standards:
        $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui.pdf,
            Guidelines for Use Organizationally Unique Identifier (OUI) and Company ID (CID))
        $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui48.pdf,
            Guidelines for 48-Bit Global Identifier (EUI-48))
        $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui64.pdf,
            Guidelines for 64-Bit Global Identifier (EUI-64))
    Version: 0.1.0
    See_Also:
        $(LINK2 https://en.wikipedia.org/wiki/MAC_address, Wikipedia Page for MAC Address)
*/
import ieeeid;
import std.stdio : writeln;
import std.string : indexOf;
import std.ascii : hexDigits;

int main(string[] args)
{
    if (args.length < 2)
    {
        writeln("Supply an EUI-48, EUI-64, OUI-24, OUI-36, or some other IEEE Identifier.");
        return 1;
    }
    
    ubyte[] bytes;
    for(int i; i < args[1].length-1; i++)
    {
        ptrdiff_t currentNybble = hexDigits.indexOf(args[1][i]);
        debug writeln("cn: ", currentNybble);
        if (currentNybble == -1) continue;
        
        ptrdiff_t nextNybble = hexDigits.indexOf(args[1][i+1]);
        debug writeln("nn: ", nextNybble);
        if (nextNybble == -1)
        {
            continue;
        }
        else
        {
            bytes ~= (cast(ubyte) (currentNybble << 4) | cast(ubyte) nextNybble);
        }
    }
    
    debug
    {
        import std.stdio : writefln;
        writefln("Bytes: %(%02X:%)", bytes);
    }
    
    switch (bytes.length)
    {
        case (6):
        {
            EUI48 eui = new EUI48(bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5]);
            writeln("This appears to be an EUI-48. If it is actually something else, use options to specify.");
            writeln("Registration: ", (eui.global ? "global" : "local"));
            writeln("Scope: ", (eui.unicast ? "unicast" : "multicast"));
            
            return 0;
        }
        default:
        {
            writeln("Not yet implemented.");
            return 2;
        }
    }
    
}