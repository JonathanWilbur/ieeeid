/**
    Provides strong types for identifiers invented by the
    $(LINK2 https://www.ieee.org/index.html,
    Institute of Electrical and Electronics Engineers (IEEE)).
    Notable among its functionality is the ExtendedUniqueIdentifier48 class,
    which is technically the same thing as a MAC address, but the term
    'MAC Address' is deprecated by the IEEE in favor of the
    'Extended Unique Identifier' (EUI-48), so this library does not use the term
    or provide any aliases for that term.

    The terms 'EUI-48' and 'EUI-64' are trademarked by the IEEE. From their
    $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui.pdf,
    Guidelines for Use Organizationally Unique Identifier (OUI) and Company ID
    (CID)),
    $(BR)
    $(P
        $(I
            "The terms EUI-48 and EUI-64 are trademarked by IEEE. Companies are
            allowed limited use of these terms for commercial purposes. Where
            such use is identification of features or capabilities specified
            within a standard or for claiming compliance to an IEEE standard
            this may be done without approval of IEEE, but other use of this
            term must be reviewed and approved by the IEEE RAC."
        )
    )

    Author: Jonathan M. Wilbur
    Copyright: Jonathan M. Wilbur
    Date: May 6th, 2017
    License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Standards:
        $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui.pdf,
            Guidelines for Use Organizationally Unique Identifier (OUI) and Company ID (CID))
        $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui48.pdf,
            Guidelines for 48-Bit Global Identifier (EUI-48))
        $(LINK2 http://standards.ieee.org/develop/regauth/tut/eui60.pdf,
            Guidelines for use of a 60-bit Extended Unique Identifier (EUI-60))
        $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui64.pdf,
            Guidelines for 64-Bit Global Identifier (EUI-64))
    Version: 0.3.0
    See_Also:
        $(LINK2 https://en.wikipedia.org/wiki/MAC_address, Wikipedia Page for MAC Address)
*/
/*
    NOTE: Reading this Wiki gives me the impression that colon delimiters denote
    bit-reversed notation, where as dash delimiters denote normal / canonical
    notation. https://en.wikipedia.org/wiki/Organizationally_unique_identifier
*/
//NOTE: The first 24-bits of an MA-S and MA-M are an OUI assigned to the IEEE RA itself.
/*
    FIXME: CIDs actually can be used to create MAC addresses, but not EUIs.
    Maybe for the sake of this library, however, you should be able to create
    EUIs with CIDs.
*/
/*
    REVIEW: There are some additional identifiers that use EUI-64 at the end of
    the EUI-64 document. Consider writing code for them as well.
*/
//REVIEW: Do I need to disable default constructors?
//NOTE: The end of the OUI / CID document clarifies the defs of the identifiers.
/*
    REVIEW: According to page 12 of the OUI document, there are 36-bit CIDs,
    but I have not found any documentation of them.
*/
//TODO: Function for turning on multicast?
//TODO: isBetweenThese(x, y) convenience function?
//TODO: Add pragma(msg, "compiling... "); messages
module ieeeid;
// pragma(lib, "ieeeid.lib");
// import std.traits : Unqual; //REVIEW: Should this be used to generalize args?

immutable private string hexDigits = "0123456789ABCDEF";

pragma(inline, true):
private
string byteToHex(ubyte value)
{
    return [hexDigits[((value & 0xF0) >> 4)], hexDigits[(value & 0x0F)]];
}

/*
    NOTE: This does not actually check that the input string is two characters,
    but it is only for private use, so it just asserts(0) if you provide more
    than two characters.
*/
pragma(inline, true):
private
ubyte hexToByte(string value)
{
    assert(value.length == 2, "hexToByte() received a non hex-pair input.");
    ubyte ret = 0x00;
    for (int i = 0; i < 16; i++)
    {
        if (value[0] == hexDigits[i]) ret |= cast(ubyte) (i << 4);
        if (value[1] == hexDigits[i]) ret |= cast(ubyte) (i);
    }
    return ret;
}

pragma(inline, true):
private
bool isHexDigit(char c)
{
    /*
        FIXME: You can improve the performance of this by testing if each char
        is between (inclusive) 0x30 - 0x39, 0x41 - 0x46, or 0x61 - 0x66 instead
        of testing all sixteen characters.
    */
    for (int i; i < 16; i++) if (c == hexDigits[i]) return true;
    return false;
}

pragma(inline, true):
private
ubyte[] hexToBytes(string hex)
{
    ubyte[] bytes;
    for (int i = 0; i < hex.length-1; i++)
    {
        if (!isHexDigit(hex[i]) || !isHexDigit(hex[i+1])) continue;
        bytes ~= hexToByte([hex[i], hex[i+1]]);
    }
    return bytes;
}

private enum IEEEIdentifierBroadcastScope : ubyte
{
    unicast = 0x00,
    multicast = 0x01
}

private enum IEEEIdentifierRegistration : ubyte
{
    global = 0x00,
    local = 0x02
}

//TODO: Test making the properties in here inline.
/// An abstract class from which all IEEE Identifiers will inherit.
abstract class IEEEIdentifier
{
    public ubyte[] _bytes; //TODO: Convert this back to private!

    /// Returns: The bytes of an IEEE Identifier.
    public @property
    ubyte[] bytes()
    {
        return this._bytes;
    }

    /**
        Returns true if the address is unicast, or false if the address is
        multicast. This is determined by reading the least significant bit of
        the first octet: if the bit is set, the address describes a multicast
        address; if the bit is cleared, the address describes a unicast address.

        Returns:
            A boolean describing whether a the address is a unicast address.
    */
    final public @property
    bool unicast()
    {
        return ((this._bytes[0] & 0x01) == IEEEIdentifierBroadcastScope.unicast);
    }

    /**
        Returns true if the address is multicast, or false if the address is
        unicast. This is determined by reading the least significant bit of
        the first octet: if the bit is set, the address describes a multicast
        address; if the bit is cleared, the address describes a unicast address.

        Returns:
            A boolean describing whether a the address is a multicast address.
    */
    final public @property
    bool multicast()
    {
        return ((this._bytes[0] & 0x01) == IEEEIdentifierBroadcastScope.multicast);
    }

    /**
        Returns true if the address is globally registered with the IEEE, or
        false if the address is locally registered (starts with a Company ID).
        For Company IDs (CIDs), this should always return false. For
        Organizationally Unique Identifiers (OUIs), this should always return
        true.

        Returns:
            A boolean describing whether a the address is a globally registered.
    */
    final public @property
    bool global()
    {
        return ((this._bytes[0] & 0x02) == IEEEIdentifierRegistration.global);
    }

    /**
        Returns false if the address is globally registered with the IEEE, or
        true if the address is locally registered (starts with a Company ID).
        For Company IDs (CIDs), this should always return true. For
        Organizationally Unique Identifiers (OUIs), this should always return
        false.

        Returns:
            A boolean describing whether a the address is a locally registered.
    */
    final public @property
    bool local()
    {
        return ((this._bytes[0] & 0x02) == IEEEIdentifierRegistration.local);
    }

    /**
        Returns true if the Identifier is valid, and false if the identifier is
        not valid. No valid IEEE Identifier may have all 0x00 or all 0xFF bytes.
    */
    final public @property
    bool valid()
    {
        if (this._bytes.length >= 3)
        {
            if (this._bytes[0] == 0x00 || this._bytes[0] == 0xFF)
            {
                for (int i = 1; i < this._bytes.length; i++)
                {
                    if (this._bytes[0] != this._bytes[i])
                    {
                        return true;
                    }
                }
                return false;
            }
            else
            {
                return true;
            }
        }
        else
        {
            return false;
        }
    }

    /**
        Enables comparison of any two IEEE Identifiers. This simply compares the
        bytes of each IEEE Identifier and returns true if they are all equal.

        Returns:
            A boolean describing whether both addresses are the exact same.
    */
    override
    bool opEquals(T : IEEEIdentifier)(T other)
    {
        return (this.bytes == other.bytes);
    }

    public @property
    string colonDelimitedNotation()
    {
        //REVIEW: Should this be an appender? Or should I pre-allocate space?
        string ret;
        foreach(b; this._bytes)
        {
            ret ~= (byteToHex(b) ~ ':');
        }
        return ret[0 .. $-1];
    }

    public @property
    string dashDelimitedNotation()
    {
        //REVIEW: Should this be an appender? Or should I pre-allocate space?
        string ret;
        foreach(b; this._bytes)
        {
            ret ~= (byteToHex(b) ~ '-');
        }
        return ret[0 .. $-1];
    }

}

///
alias CID = CompanyID;
/**
    An IEEE-Assigned Company ID, which is always exactly 24-bits in length.
    Though this type occupies the same 24-bit selection space that MA-L
    identifiers occupy, it may not be used for the construction of MAC (Media
    Access Control) addresses.

    From page 12 of
    $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui.pdf,
        Guidelines for Use Organizationally Unique Identifier (OUI) and Company ID (CID)):
    "The Company ID (CID) is a 24-bit globally-unique assigned number that has
    the X bit set to 1 and the M bit set to 0..."
*/
class CompanyID : IEEEIdentifier
{
    /// The length in bits of this IEEE Identifier: 24
    immutable static public int bitLength = 24;

    /**
        Constructor for a Company ID (CID), which is 24-bits long.
        Returns: A Company ID
    */
    this(ubyte[3] bytes ...)
    {
        this._bytes = [ (bytes[0] | 0x02), bytes[1], bytes[2] ];
    }

    /**
        Constructor for a Company ID (CID), which is 24-bits long. This
        constructor accepts a string input that is supposed to represent a CID.
        If an invalid string is supplied, the constructor does not throw an
        exception. It simply applies the correct number of null bytes to the
        CID. $(B The CID produced by this constructor should be checked with the
        valid() property.)

        Params:
            cid = A string that cannot be greater than 8 characters in length.
        Returns:
            A Company ID, regardless of whether or not cid actually was a CID.
            If the string was an invalid CID (such as "03:24:333"), the returned
            CID will be zeroed out. Be sure to check the returned CID with the
            valid() property.
    */
    this(string cid)
    {
        if (cid.length > 8) // 2 chars for each byte, plus 2 delimiters
        {
            this._bytes = [ 0x00, 0x00, 0x00 ];
        }
        else
        {
            ubyte[] bytes = hexToBytes(cid);
            if (bytes.length == 3 && (bytes[0] & 0x02))
            {
                this._bytes = bytes;
            }
            else
            {
                this._bytes = [ 0x00, 0x00, 0x00 ];
            }
        }
    }

    ///
    unittest
    {
        CID cid1 = new CID("12:34:56");
        assert(cid1.bytes == [ 0x12, 0x34, 0x56 ]);

        CID cid2 = new CID("12:34:56:12");
        assert(cid2.bytes == [ 0x00, 0x00, 0x00 ]);

        CID cid3 = new CID("12:34:56:1");
        assert(cid3.bytes == [ 0x00, 0x00, 0x00 ]);
    }

    invariant
    {
        assert(this._bytes.length == 3, "Invalid length encountered.");
    }

}

///
unittest
{
    CompanyID cid = new CompanyID(0x66, 0x44, 0x22);
    assert(cid.bytes == [ 0x66, 0x44, 0x22 ]);
    assert(cid.unicast == true);
    assert(cid.multicast == false);
    assert(cid.local == true);
    assert(cid.global == false);
}

///
alias MACIdentifier = MediaAccessControlIdentifier;
/// An abstract class from which Media Access Control Identifiers will inherit.
abstract class MediaAccessControlIdentifier : IEEEIdentifier
{
    // Nothing here.
}

///
alias MAL = MediaAccessControlLargeIdentifier;
///
alias MACLargeIdentifier = MediaAccessControlLargeIdentifier;
/**
    A class describing the IEEE-assigned identifier associated with a large
    block of unique addresses. The identifier is 24-bits long, leaving the
    largest block of bits remaining from which unique addresses may be
    allocated. This block assignment is often referred to by its acronym, MA-L.

    While this address does occupy the same numerical space as the Company ID,
    it is not the same as a Company ID and may not be used as one. It may,
    however, be used as a 24-bit Organizationally Unique Identifier (OUI-24).
*/
class MediaAccessControlLargeIdentifier : MediaAccessControlIdentifier
{
    /// The length in bits of this IEEE Identifier: 24
    immutable static public int bitLength = 24;

    /**
        Constructor for a MAC Addresses Large (MA-L) Identifier
        Returns: A MA-L Identifier
    */
    this(ubyte[3] bytes ...)
    {
        this._bytes = [ (bytes[0] & 0xFC), bytes[1], bytes[2] ];
    }

    /**
        Constructor for a MA-L, which is 24-bits long. This
        constructor accepts a string input that is supposed to represent a MA-L.
        If an invalid string is supplied, the constructor does not throw an
        exception. It simply applies the correct number of null bytes to the
        MA-L. $(B The MA-L produced by this constructor should be checked with
        the valid() property.)

        Params:
            macid = A string that cannot be greater than 8 characters in length.
        Returns:
            A MA-L, regardless of whether or not macid actually was a MA-L.
            If the string was an invalid MA-L (such as "03:24:333"), the
            returned MA-L will be zeroed out. Be sure to check the returned MA-L
            with the valid() property.
    */
    this(string macid)
    {
        if (macid.length > 8) // 2 chars for each byte, plus 2 delimiters
        {
            this._bytes = [ 0x00, 0x00, 0x00 ];
        }
        else
        {
            ubyte[] bytes = hexToBytes(macid);
            if (bytes.length == 3 && !(bytes[0] & 0x02))
            {
                this._bytes = bytes;
            }
            else
            {
                this._bytes = [ 0x00, 0x00, 0x00 ];
            }
        }
    }

    ///
    unittest
    {
        MAL mal1 = new MAL("10:34:56");
        assert(mal1.bytes == [ 0x10, 0x34, 0x56 ]);

        MAL mal2 = new MAL("12:34:56:12");
        assert(mal2.bytes == [ 0x00, 0x00, 0x00 ]);

        MAL mal3 = new MAL("12:34:56:1");
        assert(mal3.bytes == [ 0x00, 0x00, 0x00 ]);
    }

    /**
        Override of the opCast operator so you can cast this as a 24-bit
        Organizationally Unique Identifier (OUI-24).
    */
    override public
    OrganizationallyUniqueIdentifier24 opCast(OrganizationallyUniqueIdentifier24)()
    {
        return new OrganizationallyUniqueIdentifier24(this.bytes);
    }

    invariant
    {
        assert(this._bytes.length == 3, "Invalid length encountered.");
        assert(!(this._bytes[0] & 0x02), "2nd LSb of 1st byte set!");
    }

}

///
unittest
{
    MACLargeIdentifier macid = new MACLargeIdentifier(0x00, 0x00, 0x00);
    assert(macid.bytes == [ 0x00, 0x00, 0x00 ]);
    assert(macid.unicast == true);
    assert(macid.multicast == false);
    assert(macid.global == true);
    assert(macid.local == false);
}

///
alias MAM = MediaAccessControlMediumIdentifier;
///
alias MACMediumIdentifier = MediaAccessControlMediumIdentifier;
/**
    A class describing the IEEE-assigned identifier associated with a medium
    block of unique addresses. The identifier is 28-bits long, leaving a
    moderately-sized block of bits remaining from which unique addresses may be
    allocated. This block assignment is often referred to by its acronym, MA-M.
*/
class MediaAccessControlMediumIdentifier : MediaAccessControlIdentifier
{
    /// The length in bits of this IEEE Identifier: 28
    immutable static public int bitLength = 28;

    /**
        Constructor for a MAC Addresses Large (MA-M) Identifier.
        Returns: A MA-M Identifier
    */
    this(ubyte[4] bytes ...)
    {
        this._bytes = [ (bytes[0] & 0xFC), bytes[1], bytes[2], (bytes[3] & 0xF0) ];
    }

    /**
        Constructor for a MA-M, which is 28-bits long. This
        constructor accepts a string input that is supposed to represent a MA-M.
        If an invalid string is supplied, the constructor does not throw an
        exception. It simply applies the correct number of null bytes to the
        MA-M. $(B The MA-M produced by this constructor should be checked with
        the valid() property.)

        Params:
            macid = A string that cannot be greater than 8 characters in length.
        Returns:
            A MA-M, regardless of whether or not macid actually was a MA-M.
            If the string was an invalid MA-L (such as "03:24:333"), the
            returned MA-M will be zeroed out. Be sure to check the returned MA-M
            with the valid() property.
    */
    this(string macid)
    {
        if (macid.length > 11) // 2 chars for each byte, plus 3 delimiters
        {
            this._bytes = [ 0x00, 0x00, 0x00, 0x00 ];
        }
        else
        {
            ubyte[] bytes = hexToBytes(macid);
            if (bytes.length == 4 && !(bytes[0] & 0x02))
            {
                this._bytes = bytes;
            }
            else
            {
                this._bytes = [ 0x00, 0x00, 0x00, 0x00 ];
            }
        }
    }

    ///
    unittest
    {
        MAM mam1 = new MAM("10:34:56:40");
        assert(mam1.bytes == [ 0x10, 0x34, 0x56, 0x40 ]);

        MAM mam2 = new MAM("12:34:12");
        assert(mam2.bytes == [ 0x00, 0x00, 0x00, 0x00 ]);

        MAM mam3 = new MAM("12:34:56:11:22");
        assert(mam3.bytes == [ 0x00, 0x00, 0x00, 0x00 ]);
    }

    invariant
    {
        assert(this._bytes.length == 4, "Invalid length encountered.");
        assert(!(this._bytes[$-1] & 0x0F), "Last four bits were not cleared!");
        assert(!(this._bytes[0] & 0x02), "2nd LSb of 1st byte set!");
    }
}

///
unittest
{
    MACMediumIdentifier macid = new MACMediumIdentifier(0x00, 0x00, 0x00, 0x00);
    assert(macid.bytes == [ 0x00, 0x00, 0x00, 0x00 ]);
    assert(macid.unicast == true);
    assert(macid.multicast == false);
    assert(macid.global == true);
    assert(macid.local == false);
}

///
alias MAS = MediaAccessControlSmallIdentifier;
///
alias MACSmallIdentifier = MediaAccessControlSmallIdentifier;
/**
    A class describing the IEEE-assigned identifier associated with a small
    block of unique addresses. The identifier is 28-bits long, leaving the
    smallest block of bits remaining from which unique addresses may be
    allocated. This block assignment is often referred to by its acronym, MA-S.
*/
class MediaAccessControlSmallIdentifier : MediaAccessControlIdentifier
{
    /// The length in bits of this IEEE Identifier: 36
    immutable static public int bitLength = 36;

    /**
        Constructor for a MAC Addresses Large (MA-S) Identifier
        Returns: A MA-S Identifier
    */
    this(ubyte[5] bytes ...)
    {
        this._bytes = [ (bytes[0] & 0xFC), bytes[1], bytes[2], bytes[3], (bytes[4] & 0xF0) ];
    }

    /**
        Constructor for a MA-S, which is 36-bits long. This
        constructor accepts a string input that is supposed to represent a MA-S.
        If an invalid string is supplied, the constructor does not throw an
        exception. It simply applies the correct number of null bytes to the
        MA-S. $(B The MA-S produced by this constructor should be checked with
        the valid() property.)

        Params:
            macid = A string that cannot be greater than 8 characters in length.
        Returns:
            A MA-S, regardless of whether or not macid actually was a MA-S.
            If the string was an invalid MA-S (such as "03:24:333"), the
            returned MA-S will be zeroed out. Be sure to check the returned MA-S
            with the valid() property.
    */
    this(string macid)
    {
        if (macid.length > 14) // 2 chars for each byte, plus 4 delimiters
        {
            this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00 ];
        }
        else
        {
            ubyte[] bytes = hexToBytes(macid);
            if (bytes.length == 5 && !(bytes[0] & 0x02))
            {
                this._bytes = bytes[0 .. $-1] ~ (bytes[$-1] & 0xF0);
            }
            else
            {
                this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00 ];
            }
        }
    }

    ///
    unittest
    {
        MAS mas1 = new MAS("10:34:56:40:55");
        assert(mas1.bytes == [ 0x10, 0x34, 0x56, 0x40, 0x50 ]);

        MAS mas2 = new MAS("12:34:12");
        assert(mas2.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00 ]);

        MAS mas3 = new MAS("12:34:56:11:22:44:66:00:FF");
        assert(mas3.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    }

    /**
        Override of the opCast operator so you can cast this as a 36-bit
        Organizationally Unique Identifier (OUI-36).
    */
    override public
    OrganizationallyUniqueIdentifier36 opCast(OrganizationallyUniqueIdentifier36)()
    {
        return new OrganizationallyUniqueIdentifier36(this.bytes);
    }

    invariant
    {
        assert(this._bytes.length == 5, "Invalid length encountered.");
        assert(!(this._bytes[$-1] & 0x0F), "Last four bits were not cleared!");
        assert(!(this._bytes[0] & 0x02), "2nd LSb of 1st byte set!");
    }

}

///
unittest
{
    MACSmallIdentifier macid = new MACSmallIdentifier(0x00, 0x00, 0x00, 0x00, 0x00);
    assert(macid.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    assert(macid.unicast == true);
    assert(macid.multicast == false);
    assert(macid.global == true);
    assert(macid.local == false);
}

/*
    REVIEW: Do OUIs need to check the X bit?
    As a result of these MAC address uses of EUI-48 and EUI-64, all OUI assignments made
    by the IEEE RA have M and X bits equal to zero. Consequently, an EUI-48 or EUI-64 is
    used without modification as a universally unique MAC address.
*/
///
alias OUI = OrganizationallyUniqueIdentifier;
/// An abstract class from which both the OUI-24 and OUI-36 will inherit
abstract class OrganizationallyUniqueIdentifier : IEEEIdentifier
{
    // Nothing here.
}

///
alias OUI24 = OrganizationallyUniqueIdentifier24;
/**
    A class for the 24-bit Organizationally Unique Identifier (OUI-24) as
    assigned by the IEEE. Note that, though this is the same size as a Company
    ID (CID), it is not the same thing. Thus, there is no casting permitted
    between this instances of this class and instances of CompanyID.
*/
class OrganizationallyUniqueIdentifier24 : OrganizationallyUniqueIdentifier
{
    /// The length in bits of this IEEE Identifier: 24
    immutable static public int bitLength = 24;

    /**
        Constructor for a 24-Bit Organizationally Unique Identifier (OUI-24)
        Returns: A 24-Bit Organizationally Unique Identifier (OUI-24)
    */
    this(ubyte[3] bytes ...)
    {
        this._bytes = [ (bytes[0] & 0xFC), bytes[1], bytes[2] ];
    }

    /**
        An override of the opCast method so you can convert this to a
        MediaAccessControlLargeIdentifier.
    */
    override public
    MediaAccessControlLargeIdentifier opCast(MediaAccessControlLargeIdentifier)()
    {
        return new MediaAccessControlLargeIdentifier(this.bytes);
    }

    invariant
    {
        assert(this._bytes.length == 3, "Invalid length encountered.");
        assert(!(this._bytes[0] & 0x02), "2nd LSb of 1st byte set!");
    }

}

///
unittest
{
    OUI24 oui = new OUI24(0x00, 0x00, 0x00);
    assert(oui.bytes == [ 0x00, 0x00, 0x00 ]);
    assert(oui.unicast == true);
    assert(oui.multicast == false);
    assert(oui.global == true);
    assert(oui.local == false);
}

///
alias OUI36 = OrganizationallyUniqueIdentifier36;
/**
    A class for the 36-bit Organizationally Unique Identifier (OUI-36) as
    assigned by the IEEE.
*/
class OrganizationallyUniqueIdentifier36 : OrganizationallyUniqueIdentifier
{
    /// The length in bits of this IEEE Identifier: 36
    immutable static public int bitLength = 36;

    /**
        Constructor for a 36-Bit Organizationally Unique Identifier (OUI-36)
        Returns: A 36-Bit Organizationally Unique Identifier (OUI-36)
    */
    this(ubyte[5] bytes ...)
    {
        this._bytes = [ (bytes[0] & 0xFC), bytes[1], bytes[2], bytes[3], (bytes[4] & 0xF0) ];
    }

    /**
        An override of the opCast method so you can convert this to a
        MediaAccessControlSmallIdentifier.
    */
    override public
    MediaAccessControlSmallIdentifier opCast(MediaAccessControlSmallIdentifier)()
    {
        return new MediaAccessControlSmallIdentifier(this.bytes);
    }

    invariant
    {
        assert(this._bytes.length == 5, "Invalid length encountered.");
        assert(!(this._bytes[$-1] & 0x0F), "Last four bits were not cleared!");
        assert(!(this._bytes[0] & 0x02), "2nd LSb of 1st byte set!");
    }
}

///
unittest
{
    OUI36 oui = new OUI36(0x00, 0x00, 0x00, 0x00, 0x00);
    assert(oui.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    assert(oui.unicast == true);
    assert(oui.multicast == false);
    assert(oui.global == true);
    assert(oui.local == false);
}

///
alias CDI = ContextDependentIdentifier;
/// An abstract class from which both the CDI-32 and CDI-40 will inherit.
abstract class ContextDependentIdentifier : IEEEIdentifier
{
    // Nothing here.
}

///
alias CDI32 = ContextDependentIdentifier32;
/**
    A 32-Bit Context Dependent Identifier.
*/
class ContextDependentIdentifier32 : ContextDependentIdentifier
{
    /**
        Constructor for a 32-Bit Context Dependent Identifier
        Returns: A 32-Bit Context Dependent Identifier
    */
    this(ubyte[4] bytes ...)
    {
        this._bytes = bytes;
    }

    /**
        Constructor for a 32-Bit Context Dependent Identifier
        Returns: A 32-Bit Context Dependent Identifier
    */
    this(OUI oui, ubyte[1] extension ...)
    {
        this._bytes = (oui.bytes ~ extension);
    }

    /**
        Constructor for a CDI-32, which is 32-bits long. This constructor
        accepts a string input that is supposed to represent a CDI-32. If an
        invalid string is supplied, the constructor does not throw an exception.
        It simply applies the correct number of null bytes to the CDI-32.
        $(B The CDI-32 produced by this constructor should be checked with the
        valid() property.)

        Params:
            cdi = A string that cannot be greater than 8 characters in length.
        Returns:
            A CDI-32, regardless of whether or not macid actually was a CDI-32.
            If the string was an invalid CDI-32 (such as "03:24:333"), the
            returned CDI-32 will be zeroed out. Be sure to check the returned
            CDI-32 with the valid() property.
    */
    this(string cdi)
    {
        if (cdi.length > 11) // 2 chars for each byte, plus 2 delimiters
        {
            this._bytes = [ 0x00, 0x00, 0x00, 0x00 ];
        }
        else
        {
            ubyte[] bytes = hexToBytes(cdi);
            if (bytes.length == 4 && !(bytes[0] & 0x02))
            {
                this._bytes = bytes;
            }
            else
            {
                this._bytes = [ 0x00, 0x00, 0x00, 0x00 ];
            }
        }
    }

    ///
    unittest
    {
        CDI32 cdi1 = new CDI32("10:34:56:78");
        assert(cdi1.bytes == [ 0x10, 0x34, 0x56, 0x78 ]);

        CDI32 cdi2 = new CDI32("1~2:3:3%");
        assert(cdi2.bytes == [ 0x00, 0x00, 0x00, 0x00 ]);

        CDI32 cdi3 = new CDI32("12:34:56:11:22");
        assert(cdi3.bytes == [ 0x00, 0x00, 0x00, 0x00 ]);
    }

    invariant
    {
        assert(this._bytes.length == 4, "Invalid length encountered.");
        assert(!(this._bytes[0] & 0x02), "2nd LSb of 1st byte set!");
    }

}

///
alias CDI40 = ContextDependentIdentifier40;
/**
    A 40-Bit Context Dependent Identifier.
*/
class ContextDependentIdentifier40 : ContextDependentIdentifier
{
    /**
        Constructor for a 40-Bit Context Dependent Identifier
        Returns: A 40-Bit Context Dependent Identifier
    */
    this(ubyte[5] bytes ...)
    {
        this._bytes = bytes;
    }

    /**
        Constructor for a 40-Bit Context Dependent Identifier
        Returns: A 40-Bit Context Dependent Identifier
    */
    this(OUI24 oui, ubyte[2] extension ...)
    {
        this._bytes = (oui.bytes ~ extension);
    }

    /**
        Constructor for a 40-Bit Context Dependent Identifier
        Returns: A 40-Bit Context Dependent Identifier
    */
    this(OUI36 oui, ubyte[1] extension ...)
    in
    {
        assert(!(oui.bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }
    body
    {
        this._bytes = (oui.bytes[0 .. $-1] ~ ((extension[0] & 0x0F) | oui.bytes[$-1]));
    }

    /**
        Constructor for a CDI-40, which is 40-bits long. This constructor
        accepts a string input that is supposed to represent a CDI-32. If an
        invalid string is supplied, the constructor does not throw an exception.
        It simply applies the correct number of null bytes to the CDI-32.
        $(B The CDI-32 produced by this constructor should be checked with the
        valid() property.)

        Params:
            cdi = A string that cannot be greater than 8 characters in length.
        Returns:
            A CDI-32, regardless of whether or not macid actually was a CDI-32.
            If the string was an invalid CDI-32 (such as "03:24:333"), the
            returned CDI-32 will be zeroed out. Be sure to check the returned
            CDI-32 with the valid() property.
    */
    this(string cdi)
    {
        if (cdi.length > 14) // 2 chars for each byte, plus 4 delimiters
        {
            this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00 ];
        }
        else
        {
            ubyte[] bytes = hexToBytes(cdi);
            if (bytes.length == 5 && !(bytes[0] & 0x02))
            {
                this._bytes = bytes;
            }
            else
            {
                this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00 ];
            }
        }
    }

    ///
    unittest
    {
        CDI40 cdi1 = new CDI40("10:34:56:78:90");
        assert(cdi1.bytes == [ 0x10, 0x34, 0x56, 0x78, 0x90 ]);

        CDI40 cdi2 = new CDI40("1~2:3:3%");
        assert(cdi2.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00 ]);

        CDI40 cdi3 = new CDI40("12:34:56:11:22");
        assert(cdi3.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    }

    invariant
    {
        assert(this._bytes.length == 5, "Invalid length encountered.");
        assert(!(this._bytes[0] & 0x02), "2nd LSb of 1st byte set!");
    }
}

///
alias EUI = ExtendedUniqueIdentifier;
/// An abstract class from which both the EUI-48 and EUI-64 will inherit
abstract class ExtendedUniqueIdentifier : IEEEIdentifier
{
    // Nothing here.
}

//REVIEW: Can this class be constructed with a CompanyID?
///
alias EUI48 = ExtendedUniqueIdentifier48;
/**
    A 48-Bit Extended Unique Identifier (EUI-48). This is the same thing as a
    Media Access Control (MAC) Address, but the term "MAC Address" is
    deprecated by the IEEE, so this library does not use this term in any way.

    This class can be cast to a 64-Bit Extended Unique Identifier (EUI-64).
*/
class ExtendedUniqueIdentifier48 : ExtendedUniqueIdentifier
{
    /// The length in bits of this IEEE Identifier: 48
    immutable static public int bitLength = 48;

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(ubyte[6] fullbytes ...)
    {
        /*
            NOTE: For some reason, I have to append bytes to this._bytes. If I
            do not do this, it sets this._bytes to what appears to be either the
            first or last six bytes of a memory address.
        */
        this._bytes ~= fullbytes;
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(OUI24 oui, ubyte[3] extension ...)
    {
        this._bytes = (oui.bytes ~ extension);
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(OUI36 oui, ubyte[2] extension ...)
    in
    {
        assert(!(oui.bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }
    body
    {
        this._bytes =
            oui.bytes[0 .. 4] ~
            ((oui.bytes[4] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1];
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(MACLargeIdentifier macid, ubyte[3] extension ...)
    {
        this._bytes = (macid.bytes ~ extension);
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(MACMediumIdentifier macid, ubyte[3] extension ...)
    in
    {
        assert(!(macid.bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }
    body
    {
        this._bytes =
            macid.bytes[0 .. 3] ~
            ((macid.bytes[3] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(MACSmallIdentifier macid, ubyte[2] extension ...)
    in
    {
        assert(!(macid.bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }
    body
    {
        this._bytes =
            macid.bytes[0 .. 4] ~
            ((macid.bytes[4] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1];
    }

    /**
        If a CID is used to create MAC addresses, the X bit becomes the U/L bit
        (i.e., EUI-48 used as a MAC address or an EUI-64 used as an address)
    */
    //TODO: this(CID cid, ubyte[3] extension ...)

    /**
        Constructor for an EUI-48, which is 48-bits long. This constructor
        accepts a string input that is supposed to represent a EUI-48. If an
        invalid string is supplied, the constructor does not throw an exception.
        It simply applies the correct number of null bytes to the EUI-48.
        $(B The EUI produced by this constructor should be checked with the
        valid() property.)

        Params:
            eui = A string that cannot be greater than 17 characters in length.
        Returns:
            A EUI-48, regardless of whether or not macid actually was a EUI-48.
            If the string was an invalid EUI-48 (such as "03:24:333"), the
            returned EUI-48 will be zeroed out. Be sure to check the returned
            EUI-48 with the valid() property.
    */
    this(string eui)
    {
        if (eui.length > 17) // 2 chars for each byte, plus 2 delimiters
        {
            this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        }
        else
        {
            ubyte[] bytes = hexToBytes(eui);
            if (bytes.length == 6 && !(bytes[0] & 0x02))
            {
                this._bytes = bytes;
            }
            else
            {
                this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
            }
        }
    }

    ///
    unittest
    {
        EUI48 eui1 = new EUI48("10:34:56:78:90:14");
        assert(eui1.bytes == [ 0x10, 0x34, 0x56, 0x78, 0x90, 0x14 ]);

        EUI48 eui2 = new EUI48("1~2:3:3%");
        assert(eui2.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);

        EUI48 eui3 = new EUI48("12:34:56:11");
        assert(eui3.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    }

    /**
        An override of the opCast method so you can convert this to a
        MediaAccessControlSmallIdentifier.
    */
    override public
    EUI64 opCast(EUI48)()
    {
        //REVIEW: Is there any reason to prefer 0xFF,0xFF to 0xFF,0xFE?
        return new EUI64(this.bytes[0 .. 4] ~ [ 0xFF, 0xFF ] ~ this.bytes[0 .. $]);
    }

    invariant
    {
        assert(this._bytes.length == 6, "Invalid length encountered.");
    }

}

///
unittest
{
    EUI48 eui = new EUI48(0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
    assert(eui.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    assert(eui.unicast == true);
    assert(eui.multicast == false);
    assert(eui.global == true);
    assert(eui.local == false);
}

///
alias EUI60 = ExtendedUniqueIdentifier60;
/**
    The use of the EUI-60 identifier is deprecated. Since EUI-60 identifiers
    form a portion of the World Wide Names (WWNs) value defined within multiple
    disk-related standards, there is no plan to eliminate the use of these
    EUI-60 values in the foreseeable future. The term deprecated does not imply
    a demise of EUI-60 identifiers, but implies the EUI-64
    (as opposed to EUI-60) identifiers should be used in future applications
    requiring the use of unique per-hardware instance identifiers.

    Note that the EUI-60 can only be generated with an OUI-24.
*/
class ExtendedUniqueIdentifier60 : ExtendedUniqueIdentifier
{
    /// The length in bits of this IEEE Identifier: 60
    immutable static public int bitLength = 60;

    /**
        Constructor for a 60-Bit Extended Unique Identifier (EUI-60)
        Returns: A 60-Bit Extended Unique Identifier (EUI-60)
    */
    this(ubyte[8] bytes ...)
    {
        /*
            NOTE: For some reason, I have to append bytes to this._bytes. If I
            do not do this, it sets this._bytes to what appears to be either the
            first or last six bytes of a memory address.
        */
        this._bytes ~= (bytes[0 .. $-1] ~ (bytes[$-1] & 0xF0));
    }

    /**
        Constructor for a 60-Bit Extended Unique Identifier (EUI-60)
        Returns: A 60-Bit Extended Unique Identifier (EUI-60)
    */
    this(OUI24 oui, ubyte[5] extension ...)
    {
        this._bytes = (oui.bytes ~ (extension[0 .. 4] ~ (extension[4] & 0xF0)));
    }

    /**
        Constructor for an EUI-60, which is 60-bits long. This constructor
        accepts a string input that is supposed to represent a EUI-60. If an
        invalid string is supplied, the constructor does not throw an exception.
        It simply applies the correct number of null bytes to the EUI-60.
        $(B The EUI produced by this constructor should be checked with the
        valid() property.)

        Params:
            eui = A string that cannot be greater than 23 characters in length.
        Returns:
            A EUI-60, regardless of whether or not macid actually was a EUI-60.
            If the string was an invalid EUI-60 (such as "03:24:333"), the
            returned EUI-60 will be zeroed out. Be sure to check the returned
            EUI-60 with the valid() property.
    */
    this(string eui)
    {
        //REVIEW: Should there really be these tight length restrictions?
        if (eui.length > 23) // 2 chars for each byte, plus 7 delimiters
        {
            this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        }
        else
        {
            ubyte[] bytes = hexToBytes(eui);
            if (bytes.length == 8 && !(bytes[0] & 0x02))
            {
                this._bytes = bytes[0 .. $-1] ~ (bytes[$-1] & 0xF0);
            }
            else
            {
                this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
            }
        }
    }

    ///
    unittest
    {
        EUI60 eui1 = new EUI60("10:34:56:78:90:14:80:84");
        assert(eui1.bytes == [ 0x10, 0x34, 0x56, 0x78, 0x90, 0x14, 0x80, 0x80 ]);

        EUI60 eui2 = new EUI60("1~2:3:3%");
        assert(eui2.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);

        EUI60 eui3 = new EUI60("12:34:56:11");
        assert(eui3.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    }

    invariant
    {
        assert(!(this._bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }

}

///
unittest
{
    EUI60 oui = new EUI60(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
    assert(oui.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    assert(oui.unicast == true);
    assert(oui.multicast == false);
    assert(oui.global == true);
    assert(oui.local == false);
}

///
alias EUI64 = ExtendedUniqueIdentifier64;
/**
    A 64-Bit Extended Unique Identifier (EUI-64). This class can be created by
    casting from a 48-Bit Extended Unique Identifier, but a 48-Bit Extended
    Unique Identifier cannot be created from this class. (The cast is
    $(I irreversable), in other words.)
*/
class ExtendedUniqueIdentifier64 : ExtendedUniqueIdentifier
{
    /// The length in bits of this IEEE Identifier: 64
    immutable static public int bitLength = 64;

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 48-Bit Extended Unique Identifier (EUI-64)
    */
    this(ubyte[8] bytes ...)
    {
        /*
            NOTE: For some reason, I have to append bytes to this._bytes. If I
            do not do this, it sets this._bytes to what appears to be either the
            first or last six bytes of a memory address.
        */
        this._bytes ~= bytes;
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
    */
    this(OUI24 oui, ubyte[5] extension ...)
    {
        this._bytes = (oui.bytes ~ extension);
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
    */
    this(OUI36 oui, ubyte[4] extension ...)
    in
    {
        assert(!(oui.bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }
    body
    {
        this._bytes =
            oui.bytes[0 .. 4] ~
            ((oui.bytes[4] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
    */
    this(MACLargeIdentifier macid, ubyte[5] extension ...)
    {
        this._bytes = (macid.bytes ~ extension);
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
    */
    this(MACMediumIdentifier macid, ubyte[5] extension ...)
    in
    {
        assert(!(macid.bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }
    body
    {
        this._bytes =
            macid.bytes[0 .. 3] ~
            ((macid.bytes[3] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
    */
    this(MACSmallIdentifier macid, ubyte[4] extension ...)
    in
    {
        assert(!(macid.bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }
    body
    {
        this._bytes =
            macid.bytes[0 .. 4] ~
            ((macid.bytes[4] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }

    /**
        Constructor for an EUI-64, which is 64-bits long. This constructor
        accepts a string input that is supposed to represent a EUI-64. If an
        invalid string is supplied, the constructor does not throw an exception.
        It simply applies the correct number of null bytes to the EUI-64.
        $(B The EUI produced by this constructor should be checked with the
        valid() property.)

        Params:
            eui = A string that cannot be greater than 23 characters in length.
        Returns:
            A EUI-64, regardless of whether or not macid actually was a EUI-60.
            If the string was an invalid EUI-64 (such as "03:24:333"), the
            returned EUI-64 will be zeroed out. Be sure to check the returned
            EUI-64 with the valid() property.
    */
    this(string eui)
    {
        if (eui.length > 23) // 2 chars for each byte, plus 2 delimiters
        {
            this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        }
        else
        {
            ubyte[] bytes = hexToBytes(eui);
            if (bytes.length == 8 && !(bytes[0] & 0x02))
            {
                this._bytes = bytes;
            }
            else
            {
                this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
            }
        }
    }

    ///
    unittest
    {
        EUI64 eui1 = new EUI64("10:34:56:78:90:14:80:84");
        assert(eui1.bytes == [ 0x10, 0x34, 0x56, 0x78, 0x90, 0x14, 0x80, 0x84 ]);

        EUI64 eui2 = new EUI64("1~2:3:3%");
        assert(eui2.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);

        EUI64 eui3 = new EUI64("10:34:56:11");
        assert(eui3.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    }

    invariant
    {
        assert(this._bytes.length == 8, "Invalid length encountered.");
    }

}

///
unittest
{
    EUI64 oui = new EUI64(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
    assert(oui.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    assert(oui.unicast == true);
    assert(oui.multicast == false);
    assert(oui.global == true);
    assert(oui.local == false);
}

///
alias MEUI64 = ModifiedExtendedUniqueIdentifier64;
/**
    The Modified Extended Unique Identifier. This differs from the EUI-64 only
    by the global/local bit being inverted. This is used by IPv6.
*/
class ModifiedExtendedUniqueIdentifier64 : ExtendedUniqueIdentifier
{
    /// The length in bits of this IEEE Identifier: 64
    immutable static public int bitLength = 64;

    /**
        Constructor for a 64-Bit Modified Extended Unique Identifier (MEUI-64)
        Returns: A 48-Bit Modified Extended Unique Identifier (MEUI-64)
    */
    this(ubyte[8] bytes ...)
    {
        /*
            NOTE: For some reason, I have to append bytes to this._bytes. If I
            do not do this, it sets this._bytes to what appears to be either the
            first or last six bytes of a memory address.
        */
        this._bytes ~= bytes;
    }

    /**
        Constructor for a 64-Bit Modified Extended Unique Identifier (MEUI-64)
        Returns: A 64-Bit Modified Extended Unique Identifier (MEUI-64)
    */
    this(OUI24 oui, ubyte[5] extension ...)
    {
        this._bytes = (oui.bytes ~ extension);
    }

    /**
        Constructor for a 64-Bit Modified Extended Unique Identifier (MEUI-64)
        Returns: A 64-Bit Modified Extended Unique Identifier (MEUI-64)
    */
    this(OUI36 oui, ubyte[4] extension ...)
    in
    {
        assert(!(oui.bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }
    body
    {
        this._bytes =
            oui.bytes[0 .. 4] ~
            ((oui.bytes[4] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }

    /**
        Constructor for a 64-Bit Modified Extended Unique Identifier (MEUI-64)
        Returns: A 64-Bit Modified Extended Unique Identifier (MEUI-64)
    */
    this(MACLargeIdentifier macid, ubyte[5] extension ...)
    {
        this._bytes = (macid.bytes ~ extension);
    }

    /**
        Constructor for a 64-Bit Modified Extended Unique Identifier (MEUI-64)
        Returns: A 64-Bit Modified Extended Unique Identifier (MEUI-64)
    */
    this(MACMediumIdentifier macid, ubyte[5] extension ...)
    in
    {
        assert(!(macid.bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }
    body
    {
        this._bytes =
            macid.bytes[0 .. 3] ~
            ((macid.bytes[3] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }

    /**
        Constructor for a 64-Bit Modified Extended Unique Identifier (MEUI-64)
        Returns: A 64-Bit Modified Extended Unique Identifier (MEUI-64)
    */
    this(MACSmallIdentifier macid, ubyte[4] extension ...)
    in
    {
        assert(!(macid.bytes[$-1] & 0x0F), "Last four bits were not cleared!");
    }
    body
    {
        this._bytes =
            macid.bytes[0 .. 4] ~
            ((macid.bytes[4] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }

    /**
        Constructor for an MEUI-64, which is 64-bits long. This constructor
        accepts a string input that is supposed to represent a MEUI-64. If an
        invalid string is supplied, the constructor does not throw an exception.
        It simply applies the correct number of null bytes to the MEUI-64.
        $(B The EUI produced by this constructor should be checked with the
        valid() property.)

        Params:
            meui = A string that cannot be greater than 23 characters in length.
        Returns:
            A MEUI-64, regardless of whether or not macid actually was a
            MEUI-64. If the string was an invalid MEUI-64 (such as "03:24:333"),
            the returned MEUI-64 will be zeroed out. Be sure to check the
            returned MEUI-64 with the valid() property.
    */
    this(string meui)
    {
        if (meui.length > 23) // 2 chars for each byte, plus 7 delimiters
        {
            this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
        }
        else
        {
            ubyte[] bytes = hexToBytes(meui);
            if (bytes.length == 8 && (bytes[0] & 0x02))
            {
                this._bytes = bytes;
            }
            else
            {
                this._bytes = [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
            }
        }
    }

    ///
    unittest
    {
        MEUI64 eui1 = new MEUI64("12:34:56:78:90:14:80:84");
        assert(eui1.bytes == [ 0x12, 0x34, 0x56, 0x78, 0x90, 0x14, 0x80, 0x84 ]);

        MEUI64 eui2 = new MEUI64("10:34:56:78:90:14:80:84");
        assert(eui2.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);

        MEUI64 eui3 = new MEUI64("1~2:3:3%");
        assert(eui3.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);

        MEUI64 eui4 = new MEUI64("12:34:56:11");
        assert(eui4.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    }

    invariant
    {
        assert(this._bytes.length == 8, "Invalid length encountered.");
        //REVIEW: Do I need to check that the 2nd LSb is set or clear?
    }

}

///
unittest
{
    EUI64 oui = new EUI64(0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
    assert(oui.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    assert(oui.unicast == true);
    assert(oui.multicast == false);
    assert(oui.global == true);
    assert(oui.local == false);
}


//TODO: static assert T.bitLength is correct for all T
