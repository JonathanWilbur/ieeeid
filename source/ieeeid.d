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
    Date: April 28th, 2017
    License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Standards:
        $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui.pdf,
            Guidelines for Use Organizationally Unique Identifier (OUI) and Company ID (CID))
        $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui48.pdf,
            Guidelines for 48-Bit Global Identifier (EUI-48))
        $(LINK2 https://standards.ieee.org/develop/regauth/tut/eui64.pdf,
            Guidelines for 64-Bit Global Identifier (EUI-64))
    Version: 0.0.0
    See_Also:
        $(LINK2 https://en.wikipedia.org/wiki/MAC_address, Wikipedia Page for MAC Address)
*/

//NOTE: The first 24-bits of an MA-S and MA-M are an OUI assigned to the IEEE RA itself.
/*
    TODO: Get a code review on how to condense the heavily duplicated code in
    ExtendedUniqueIdentifier classes. Also abstract the bitLength and byteLength
    fields, if possible.
*/
/*
    REVIEW: Should constructors throw an exception if the M/X bits are set
    incorrectly, or should they just silently change them?
*/
module ieeeid;
import std.traits : Unqual;
import std.format : sformat;

version (unittest)
{
    import std.exception;
}

static assert(0, "ieeeid.d is not thoroughly unit-tested or reviewed, so refused to compile.");

/// A generic exception thrown from invalid IEEE identifiers.
public class IEEEIdentifierException : Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

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

/// An abstract class from which all IEEE Identifiers will inherit.
abstract class IEEEIdentifier
{

    private ubyte[] _bytes;

    /**
        Returns the bytes of an IEEE Identifier.
        Returns: The bytes of an IEEE Identifier.
    */
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
    bool isUnicast()
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
    bool isMulticast()
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
    bool isGloballyRegistered()
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
    bool isLocallyRegistered()
    {
        return ((this._bytes[0] & 0x02) == ExtendedUniqueIdentifierRegistration.local);
    }
    
    // abstract public @property bool isValid();
    // abstract public @property bool isInvalid();
    
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
    /// The length in bytes of this IEEE Identifier: 3
    immutable static public int byteLength = 3;

    /**
        Constructor for a Company ID (CID), which is 24-bits long.
        Params:
            byte1 = the first byte
            byte2 = the second byte
            byte3 = the third byte
        Returns: A Company ID
        Throws:
            IEEEIdentifierException if the second least significant bit of the
                first octet is cleared
    */
    this(ubyte byte1, ubyte byte2, ubyte byte3)
    {
        if (bytes[0] & 0x02)
            throw new IEEEIdentifierException
            ("An IEEE Company ID must have the second LSb of the first set.");

        this._bytes = ([byte1] ~ byte2 ~ byte3);
    }
}

///
unittest
{
    CompanyID cid = new CompanyID(0x66, 0x44, 0x22);
    assert(cid.bytes == [ 0x66, 0x44, 0x22 ]);
    assert(cid.isUnicast == false);
    assert(cid.isMulticast == true);
    assert(cid.isLocallyRegistered == true);
    assert(cid.isGloballyRegistered == false);
}

/// Throws exception because the 2nd LSb of the first byte must be 0 for a CID.
unittest
{
    assertThrown!IEEEIdentifierException(new CompanyID(0x00, 0x00, 0x00));
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
    /// The length in bits of this IEEE Identifier: 3
    immutable static public int byteLength = 3;

    /**
        Constructor for a MAC Addresses Large (MA-L) Identifier,
        which is 24-bits long.
        Params:
            byte1 = the first byte
            byte2 = the second byte
            byte3 = the third byte
        Returns: A MA-L Identifier
        Throws:
            IEEEIdentifierException if the second least significant bit of the
                first octet is set
    */
    this(ubyte byte1, ubyte byte2, ubyte byte3)
    {
        if (!(byte1 & 0x02))
            throw new IEEEIdentifierException
            ("An IEEE MA-L must have the second LSb of the first clear.");

        this._bytes = ([byte1] ~ byte2 ~ byte3);
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
    assert(macid.isUnicast == true);
    assert(macid.isMulitcast == false);
    assert(macid.isGloballyRegistered == true);
    assert(macid.isLocallyRegistered == false);
}

/// Throws exception because the 2nd LSb of the first byte must be 1 for a MA-L.
unittest
{
    assertThrown!IEEEIdentifierException(new MACLargeIdentifier(0x02, 0x00, 0x00));
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
    /// The length in bits of this IEEE Identifier: 4
    immutable static public int byteLength = 4;

    /**
        Constructor for a MAC Addresses Large (MA-M) Identifier,
        which is 28-bits long.
        Params:
            byte1 = the first byte
            byte2 = the second byte
            byte3 = the third byte
            byte4 = the fourth byte
        Returns: A MA-M Identifier
        Throws:
            IEEEIdentifierException if the second least significant bit of the
                first octet is set, which would indicate a Company ID + 4 bits.
    */
    this(ubyte byte1, ubyte byte2, ubyte byte3, ubyte byte4)
    {
        if (!(byte1 & 0x02))
            throw new IEEEIdentifierException
            ("An IEEE MA-M must have the second LSb of the first clear.");

        this._bytes = ([byte1] ~ byte2 ~ byte3 ~ byte4);
    }
}

///
unittest
{
    MACMediumIdentifier macid = new MACMediumIdentifier(0x00, 0x00, 0x00, 0x00);
    assert(macid.bytes == [ 0x00, 0x00, 0x00 ]);
    assert(macid.isUnicast == true);
    assert(macid.isMulitcast == false);
    assert(macid.isGloballyRegistered == true);
    assert(macid.isLocallyRegistered == false);
}

/// Throws exception because the 2nd LSb of the first byte must be 1 for a MA-M.
unittest
{
    assertThrown!IEEEIdentifierException
        (new MACMediumIdentifier(0x02, 0x00, 0x00, 0x00));
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
    /// The length in bits of this IEEE Identifier: 5
    immutable static public int byteLength = 5;

    /**
        Constructor for a MAC Addresses Large (MA-S) Identifier,
        which is 36-bits long.
        Params:
            byte1 = the first byte
            byte2 = the second byte
            byte3 = the third byte
            byte4 = the fourth byte
            byte5 = the fifth byte
        Returns: A MA-S Identifier
        Throws:
            IEEEIdentifierException if the second least significant bit of the
                first octet is set, which would indicate a Company ID + 12 bits.
    */
    this(ubyte byte1, ubyte byte2, ubyte byte3, ubyte byte4, ubyte byte5)
    {
        if (!(byte1 & 0x02))
            throw new IEEEIdentifierException
            ("An IEEE MA-M must have the second LSb of the first clear.");

        this._bytes = ([byte1] ~ byte2 ~ byte3 ~ byte4 ~ byte5);
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
    assert(macid.bytes == [ 0x00, 0x00, 0x00 ]);
    assert(macid.isUnicast == true);
    assert(macid.isMulitcast == false);
    assert(macid.isGloballyRegistered == true);
    assert(macid.isLocallyRegistered == false);
}

/// Throws exception because the 2nd LSb of the first byte must be 1 for a MA-S.
unittest
{
    assertThrown!IEEEIdentifierException
        (new MACSmallIdentifier(0x02, 0x00, 0x00, 0x00, 0x00));
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
    /// The length in bytes of this IEEE Identifier: 3
    immutable static public int byteLength = 3;

    /**
        Constructor for a 24-Bit Organizationally Unique Identifier (OUI-24)
        Params:
            byte1 = the first byte
            byte2 = the second byte
            byte3 = the third byte
        Returns: A 24-Bit Organizationally Unique Identifier (OUI-24) 
        Throws:
            IEEEIdentifierException if the second least significant bit of the
                first octet is set, which would indicate a Company ID + 12 bits.
    */
    this (ubyte byte1, ubyte byte2, ubyte byte3)
    {
        if (!(byte1 & 0x02))
            throw new IEEEIdentifierException
            ("An IEEE OUI-24 must have the second LSb of the first clear.");

            this._bytes = ([byte1] ~ byte2 ~ byte3);
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
    assert(oui.isUnicast == true);
    assert(oui.isMulticast == false);
    assert(oui.isGloballyRegistered == true);
    assert(oui.isLocallyRegistered == false);
}

/// Throws exception because the 2nd LSb of the first byte must be 0 for an OUI.
unittest
{
    assertThrown!IEEEIdentifierException(new OUI24(0x02, 0x44, 0xFD));
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
    /// The length in bytes of this IEEE Identifier: 5
    immutable static public int byteLength = 5;

    /**
        Constructor for a 36-Bit Organizationally Unique Identifier (OUI-36)
        Params:
            bytes = An array of unsigned bytes representing the bytes of the OUI
        Returns: A 36-Bit Organizationally Unique Identifier (OUI-36) 
        Throws:
            IEEEIdentifierException if an incorrect number of bytes is supplied.
    */
    this (ubyte[] bytes ...)
    {
        if (bytes.length != this.byteLength)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes = bytes;
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
    /// The length in bytes of this IEEE Identifier: 6
    immutable static public int byteLength = 6;

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Params:
            bytes = An array of unsigned bytes representing the bytes of the EUI
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
        Throws:
            IEEEIdentifierException if bytes is not exactly six bytes.
    */
    this (ubyte[] bytes ...)
    {
        if (bytes.length != this.byteLength)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes = bytes;
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Params:
            oui = A 24-bit Organizationally Unique Identifier
            bytes = An array of unsigned bytes representing the extension
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
        Throws:
            IEEEIdentifierException if extension is not exactly three bytes
    */
    this(OUI24 oui, ubyte[] extension ...)
    {
        if (extension.length != 3)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes = (oui.bytes ~ extension);
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Params:
            oui = A 36-bit Organizationally Unique Identifier
            bytes = An array of unsigned bytes representing the extension
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
        Throws:
            IEEEIdentifierException if extension is not exactly two bytes
    */
    this(OUI36 oui, ubyte[] extension ...)
    //TODO: Contract that verifies that trailing bits of oui are zeroes
    {
        if (extension.length != 2)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes =
            oui.bytes[0 .. 4] ~
            ((oui.bytes[4] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1];
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Params:
            macid = A MA-L Identifier
            bytes = An array of unsigned bytes representing the extension
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
        Throws:
            IEEEIdentifierException if extension is not exactly two bytes
    */
    this(MACLargeIdentifier macid, ubyte[] extension ...)
    {
        if (extension.length != 3)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes = (macid.bytes ~ extension);
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Params:
            macid = A MA-M Identifier
            bytes = An array of unsigned bytes representing the extension
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
        Throws:
            IEEEIdentifierException if extension is not exactly three bytes
    */
    this(MACMediumIdentifier macid, ubyte[] extension ...)
    {
        if (extension.length != 3)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes =
            macid.bytes[0 .. 3] ~
            ((macid.bytes[3] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }

    /**
        Constructor for a 48-Bit Extended Unique Identifier (EUI-48)
        Params:
            macid = A MA-S Identifier
            bytes = An array of unsigned bytes representing the extension
        Returns: A 48-Bit Extended Unique Identifier (EUI-48)
        Throws:
            IEEEIdentifierException if extension is not exactly two bytes
    */
    this(MACSmallIdentifier macid, ubyte[] extension ...)
    {
        if (extension.length != 2)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes =
            macid.bytes[0 .. 4] ~
            ((macid.bytes[4] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1];
    }

}

//NOTE: This class cannot be constructed with a CompanyID.
alias EUI64 = ExtendedUniqueIdentifier64;
class ExtendedUniqueIdentifier64 : ExtendedUniqueIdentifier
{
    /// The length in bits of this IEEE Identifier: 64
    immutable static public int bitLength = 64;
    /// The length in bits of this IEEE Identifier: 8
    immutable static public int byteLength = 8;

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Params:
            bytes = An array of unsigned bytes representing the bytes of the EUI
        Returns: A 48-Bit Extended Unique Identifier (EUI-64)
        Throws:
            IEEEIdentifierException if bytes is not exactly eight bytes.
    */
    this (ubyte[] bytes ...)
    {
        if (bytes.length != this.byteLength)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes = bytes;
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Params:
            oui = A 24-bit Organizationally Unique Identifier
            bytes = An array of unsigned bytes representing the extension
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
        Throws:
            IEEEIdentifierException if extension is not exactly five bytes
    */
    this(OUI24 oui, ubyte[] extension ...)
    {
        if (extension.length != 5)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes = (oui.bytes ~ extension);
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Params:
            oui = A 36-bit Organizationally Unique Identifier
            bytes = An array of unsigned bytes representing the extension
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
        Throws:
            IEEEIdentifierException if extension is not exactly five bytes
    */
    this(OUI36 oui, ubyte[] extension ...)
    //TODO: Contract that verifies that trailing bits of oui are zeroes
    {
        if (extension.length != 4)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes =
            oui.bytes[0 .. 4] ~
            ((oui.bytes[4] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Params:
            macid = A MA-L Identifier
            bytes = An array of unsigned bytes representing the extension
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
        Throws:
            IEEEIdentifierException if extension is not exactly three bytes
    */
    this(MACLargeIdentifier macid, ubyte[] extension ...)
    {
        if (extension.length != 3)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes = (macid.bytes ~ extension);
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Params:
            macid = A MA-M Identifier
            bytes = An array of unsigned bytes representing the extension
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
        Throws:
            IEEEIdentifierException if extension is not exactly three bytes
    */
    this(MACMediumIdentifier macid, ubyte[] extension ...)
    {
        if (extension.length != 3)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes =
            macid.bytes[0 .. 3] ~
            ((macid.bytes[3] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }

    /**
        Constructor for a 64-Bit Extended Unique Identifier (EUI-64)
        Params:
            macid = A MA-S Identifier
            bytes = An array of unsigned bytes representing the extension
        Returns: A 64-Bit Extended Unique Identifier (EUI-64)
        Throws:
            IEEEIdentifierException if extension is not exactly two bytes
    */
    this(MACSmallIdentifier macid, ubyte[] extension ...)
    {
        if (extension.length != 2)
            throw new IEEEIdentifierException
            ("Incorrect number of bytes for this kind of IEEE Identifier.");

        this._bytes =
            macid.bytes[0 .. 4] ~
            ((macid.bytes[4] & 0xF0) | (extension[0] & 0x0F)) ~
            extension[1 .. $];
    }
}


//TODO: isCompanyID(ubyte[] ...) and isOUI(ubyte[] ...)
