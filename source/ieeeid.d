/**
    Provides strong types for identifiers invented by the
    $(LINK2 https://www.ieee.org/index.html, Institute of Electrical and Electronics Engineers (IEEE)).
    Most notable among its functionality is the ExtendedUniqueIdentifier48 class,
    which is technically the same thing as a MAC address, but the term
    'MAC Address' is deprecated by the IEEE in favor of the
    'Extended Unique Identifier' (EUI-48), so this library does not use the term
    or provide any aliases for that term.

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
//NOTE: The first 24-bits of an MA-S and MA-M are an OUI assigned to the IEEE RA itself.
module ieeeid;
import std.traits : Unqual;
import std.format : sformat;

// static assert(0, "ieeeid.d is not thoroughly unit-tested or reviewed, so refused to compile.");

private enum ExtendedUniqueIdentifierBroadcastScope : ubyte
{
    unicast = 0x00,
    multicast = 0x01
}

private enum ExtendedUniqueIdentifierRegistration : ubyte
{
    global = 0x00,
    local = 0x02
}

//TODO: Test making the properties in here inline.
/// An abstract class from which all IEEE Identifiers will inherit.
abstract class IEEEIdentifier
{
    private ubyte[] _bytes;

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
        return ((this._bytes[0] & 0x01) == ExtendedUniqueIdentifierBroadcastScope.unicast);
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
        return ((this._bytes[0] & 0x01) == ExtendedUniqueIdentifierBroadcastScope.multicast);
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
        return ((this._bytes[0] & 0x02) == ExtendedUniqueIdentifierRegistration.global);
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
        return ((this._bytes[0] & 0x02) == ExtendedUniqueIdentifierRegistration.local);
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

}

///
alias CID = CompanyID;
/**
    An IEEE-Assigned Company ID, which is always exactly 24-bits in length.
    Though this type occupies the same 24-bit selection space that MA-L
    identifiers occupy, it may not be used for the construction of MAC (Media
    Access Control) addresses.
*/
class CompanyID : IEEEIdentifier
{
    /// The length in bits of this IEEE Identifier: 24
    immutable static public int bitLength = 24;

    /**
        Constructor for a Company ID (CID), which is 24-bits long.
        Returns: A Company ID
    */
    this(ubyte byte1, ubyte byte2, ubyte byte3)
    {
        this._bytes = ([byte1 | 0x02] ~ byte2 ~ byte3);
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
    this(ubyte byte1, ubyte byte2, ubyte byte3)
    {
        this._bytes = ([byte1 & 0xFC] ~ byte2 ~ byte3);
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
    this(ubyte byte1, ubyte byte2, ubyte byte3, ubyte byte4)
    {
        this._bytes = ([byte1 & 0xFC] ~ byte2 ~ byte3 ~ (byte4 & 0xF0));
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
    this(ubyte byte1, ubyte byte2, ubyte byte3, ubyte byte4, ubyte byte5)
    {
        this._bytes = ([byte1 & 0xFC] ~ byte2 ~ byte3 ~ byte4 ~ byte5);
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
    this (ubyte byte1, ubyte byte2, ubyte byte3)
    {
        this._bytes = ([byte1 & 0xFC] ~ byte2 ~ byte3);
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
    this(ubyte byte1, ubyte byte2, ubyte byte3, ubyte byte4, ubyte byte5)
    {
        this._bytes = ([byte1 & 0xFC] ~ byte2 ~ byte3 ~ byte4 ~ (byte5 & 0xF0));
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
alias EUI = ExtendedUniqueIdentifier;
/// An abstract class from which both the EUI-48 and EUI-64 will inherit
abstract class ExtendedUniqueIdentifier : IEEEIdentifier
{
    // Nothing here.
}

//NOTE: This class cannot be constructed with a CompanyID.
/*REVIEW:
    Is it better to have a variadic constructor that throws exceptions if the
    correct length of the variadic array is not supplied, or to have a fixed
    number of arguments in the constructor--potentially leading to RangeErrors
    by forcing the user to draw elements from an array?
*/
alias EUI48 = ExtendedUniqueIdentifier48;
class ExtendedUniqueIdentifier48 : ExtendedUniqueIdentifier
{
    /// The length in bits of this IEEE Identifier: 48
    immutable static public int bitLength = 48;

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(ubyte byte1, ubyte byte2, ubyte byte3, ubyte byte4, ubyte byte5, ubyte byte6)
    {
        this._bytes = ([byte1] ~ byte2 ~ byte3 ~ byte4 ~ byte5 ~ byte6);
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(OUI24 oui, ubyte byte4, ubyte byte5, ubyte byte6)
    {
        this._bytes = (oui.bytes ~ byte4 ~ byte5 ~ byte6);
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(OUI36 oui, ubyte nybble5, ubyte byte6)
    //TODO: Contract that verifies that trailing bits of oui are zeroes
    {
        this._bytes =
            oui.bytes[0 .. 4] ~
            ((oui.bytes[4] & 0xF0) | (nybble5 & 0x0F)) ~
            byte6;
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(MACLargeIdentifier macid, ubyte byte4, ubyte byte5, ubyte byte6)
    {
        this._bytes = (macid.bytes ~ byte4 ~ byte5 ~ byte6);
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(MACMediumIdentifier macid, ubyte nybble4, ubyte byte5, ubyte byte6)
    {
        this._bytes =
            macid.bytes[0 .. 3] ~
            ((macid.bytes[3] & 0xF0) | (nybble4 & 0x0F)) ~
            byte5 ~ 
            byte6;
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
    */
    this(MACSmallIdentifier macid, ubyte nybble5, ubyte byte6)
    {
        this._bytes =
            macid.bytes[0 .. 4] ~
            ((macid.bytes[4] & 0xF0) | (nybble5 & 0x0F)) ~
            byte6;
    }

}

///
unittest
{
    EUI48 oui = new EUI48(0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
    assert(oui.bytes == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]);
    assert(oui.unicast == true);
    assert(oui.multicast == false);
    assert(oui.global == true);
    assert(oui.local == false);
}

//NOTE: This class cannot be constructed with a CompanyID.
alias EUI64 = ExtendedUniqueIdentifier64;
class ExtendedUniqueIdentifier64 : ExtendedUniqueIdentifier
{
    /// The length in bits of this IEEE Identifier: 64
    immutable static public int bitLength = 64;

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 48-Bit Extended Unique Identifier (EUI-64)
    */
    this
    (
        ubyte byte1,
        ubyte byte2,
        ubyte byte3,
        ubyte byte4,
        ubyte byte5,
        ubyte byte6,
        ubyte byte7,
        ubyte byte8
    )
    {
        this._bytes = ([byte1] ~ byte2 ~ byte3 ~ byte4 ~ byte5 ~ byte6 ~ byte7 ~ byte8);
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
    */
    this(OUI24 oui, ubyte byte4, ubyte byte5, ubyte byte6, ubyte byte7, ubyte byte8)
    {
        this._bytes = (oui.bytes ~ byte4 ~ byte5 ~ byte6 ~ byte7 ~ byte8);
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
    */
    this(OUI36 oui, ubyte nybble5, ubyte byte6, ubyte byte7, ubyte byte8)
    //TODO: Contract that verifies that trailing bits of oui are zeroes
    {
        this._bytes =
            oui.bytes[0 .. 4] ~
            ((oui.bytes[4] & 0xF0) | (nybble5 & 0x0F)) ~
            byte6 ~
            byte7 ~
            byte8;
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
    */
    this(MACLargeIdentifier macid, ubyte byte4, ubyte byte5, ubyte byte6, ubyte byte7, ubyte byte8)
    {
        this._bytes = (macid.bytes ~ byte4 ~ byte5 ~ byte6 ~ byte7 ~ byte8);
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
    */
    this(MACMediumIdentifier macid, ubyte nybble4, ubyte byte5, ubyte byte6, ubyte byte7, ubyte byte8)
    {
        this._bytes =
            macid.bytes[0 .. 3] ~
            ((macid.bytes[3] & 0xF0) | (nybble4 & 0x0F)) ~
            byte5 ~ byte6 ~ byte7 ~ byte8;
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
    */
    this(MACSmallIdentifier macid, ubyte nybble5, ubyte byte6, ubyte byte7, ubyte byte8)
    {
        this._bytes =
            macid.bytes[0 .. 4] ~
            ((macid.bytes[4] & 0xF0) | (nybble5 & 0x0F)) ~
            byte6 ~ byte7 ~ byte8;
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
