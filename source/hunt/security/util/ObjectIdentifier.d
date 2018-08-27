module hunt.security.util.ObjectIdentifier;

import hunt.security.util.DerInputBuffer;
import hunt.security.util.DerInputStream;
import hunt.security.util.DerOutputStream;
import hunt.security.util.DerValue;

import hunt.util.exception;
import hunt.util.string;
import hunt.container;

import std.conv;
import std.string;
import std.bigint;

import hunt.logging;

alias BigInteger = BigInt;

/**
 * Represent an ISO Object Identifier.
 *
 * <P>Object Identifiers are arbitrary length hierarchical identifiers.
 * The individual components are numbers, and they define paths from the
 * root of an ISO-managed identifier space.  You will sometimes see a
 * string name used instead of (or in addition to) the numerical id.
 * These are synonyms for the numerical IDs, but are not widely used
 * since most sites do not know all the requisite strings, while all
 * sites can parse the numeric forms.
 *
 * <P>So for example, JavaSoft has the sole authority to assign the
 * meaning to identifiers below the 1.3.6.1.4.1.42.2.17 node in the
 * hierarchy, and other organizations can easily acquire the ability
 * to assign such unique identifiers.
 *
 * @author David Brownell
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 */

final class ObjectIdentifier
{
    /**
     * We use the DER value (no tag, no length) as the internal format
     * @serial
     */
    private byte[] encoding = null;

    private string stringForm;

    /*
     * IMPORTANT NOTES FOR CODE CHANGES (bug 4811968) IN JDK 1.7.0
     * ===========================================================
     *
     * (Almost) serialization compatibility with old versions:
     *
     * serialVersionUID is unchanged. Old field "component" is changed to
     * type Object so that "poison" (unknown object type for old versions)
     * can be put inside if there are huge components that cannot be saved
     * as integers.
     *
     * New version use the new filed "encoding" only.
     *
     * Below are all 4 cases in a serialization/deserialization process:
     *
     * 1. old -> old: Not covered here
     * 2. old -> new: There's no "encoding" field, new readObject() reads
     *    "components" and "componentLen" instead and inits correctly.
     * 3. new -> new: "encoding" field exists, new readObject() uses it
     *    (ignoring the other 2 fields) and inits correctly.
     * 4. new -> old: old readObject() only recognizes "components" and
     *    "componentLen" fields. If no huge components are involved, they
     *    are serialized as legal values and old object can init correctly.
     *    Otherwise, old object cannot recognize the form (component not int[])
     *    and throw a ClassNotFoundException at deserialization time.
     *
     * Therfore, for the first 3 cases, exact compatibility is preserved. In
     * the 4th case, non-huge OID is still supportable in old versions, while
     * huge OID is not.
     */
    // private static final long serialVersionUID = 8697030238860181294L;

    /**
     * Changed to Object
     * @serial
     */
    private Object      components   = null;          // path from root
    /**
     * @serial
     */
    private int         componentLen = -1;            // how much is used.

    // Is the components field calculated?
    private bool   componentsCalculated = false;

    // private void readObject(ObjectInputStream is)
    //        , ClassNotFoundException {
    //     is.defaultReadObject();

    //     if (encoding is null) {  // from an old version
    //         init((int[])components, componentLen);
    //     }
    // }

    // private void writeObject(ObjectOutputStream os)
    //         {
    //     if (!componentsCalculated) {
    //         int[] comps = toIntArray();
    //         if (comps !is null) {    // every one understands this
    //             components = comps;
    //             componentLen = comps.length;
    //         } else {
    //             components = HugeOidNotSupportedByOldJDK.theOne;
    //         }
    //         componentsCalculated = true;
    //     }
    //     os.defaultWriteObject();
    // }

    // static class HugeOidNotSupportedByOldJDK implements Serializable {
    //     private static final long serialVersionUID = 1L;
    //     static HugeOidNotSupportedByOldJDK theOne = new HugeOidNotSupportedByOldJDK();
    // }

    /**
     * Constructs, from a string.  This string should be of the form 1.23.56.
     * Validity check included.
     */
    this (string oid)
    {
        int ch = '.';
        ptrdiff_t start = 0;
        ptrdiff_t end = 0;

        int pos = 0;
        byte[] tmp = new byte[oid.length];
        int first = 0, second;
        int count = 0;

        try {
            string comp = null;
            do {
                size_t length = 0; // length of one section
                end = oid.indexOf(ch,start);
                if (end == -1) {
                    comp = oid[start .. $];
                    length = oid.length - start;
                } else {
                    comp = oid[start .. end];
                    length = end - start;
                }

                if (length > 9) {
                    BigInteger bignum = BigInteger(comp);
                    if (count == 0) {
                        checkFirstComponent(bignum);
                        first = bignum.toInt();
                    } else {
                        if (count == 1) {
                            checkSecondComponent(first, bignum);
                            bignum = bignum + BigInteger(40*first);
                        } else {
                            checkOtherComponent(count, bignum);
                        }
                        pos += pack7Oid(bignum, tmp, pos);
                    }
                } else {
                    int num = to!int(comp);
                    if (count == 0) {
                        checkFirstComponent(num);
                        first = num;
                    } else {
                        if (count == 1) {
                            checkSecondComponent(first, num);
                            num += 40 * first;
                        } else {
                            checkOtherComponent(count, num);
                        }
                        pos += pack7Oid(num, tmp, pos);
                    }
                }
                start = end + 1;
                count++;
            } while (end != -1);

            checkCount(count);
            encoding = tmp.dup; // new byte[pos];
            // System.arraycopy(tmp, 0, encoding, 0, pos);
            this.stringForm = oid;
        } catch (IOException ioe) { // already detected by checkXXX
            throw ioe;
        } catch (Exception e) {
            throw new IOException("ObjectIdentifier() -- Invalid format: "
                    ~ e.toString(), e);
        }
    }

    /**
     * Constructor, from an array of integers.
     * Validity check included.
     */
    this (int[] values )
    {
        checkCount(values.length);
        checkFirstComponent(values[0]);
        checkSecondComponent(values[0], values[1]);
        for (size_t i=2; i<values.length; i++)
            checkOtherComponent(i, values[i]);
        initilize(values, cast(int)values.length);
    }

    /**
     * Constructor, from an ASN.1 encoded input stream.
     * Validity check NOT included.
     * The encoding of the ID in the stream uses "DER", a BER/1 subset.
     * In this case, that means a triple { typeId, length, data }.
     *
     * <P><STRONG>NOTE:</STRONG>  When an exception is thrown, the
     * input stream has not been returned to its "initial" state.
     *
     * @param in DER-encoded data holding an object ID
     * @exception IOException indicates a decoding error
     */
    this (DerInputStream inputStream)
    {
        byte    type_id;
        int     bufferEnd;

        /*
         * Object IDs are a "universal" type, and their tag needs only
         * one byte of encoding.  Verify that the tag of this datum
         * is that of an object ID.
         *
         * Then get and check the length of the ID's encoding.  We set
         * up so that we can use inputStream.available() to check for the end of
         * this value in the data stream.
         */
        type_id = cast(byte) inputStream.getByte ();
        if (type_id != DerValue.tag_ObjectId)
            throw new IOException (
                "ObjectIdentifier() -- data isn't an object ID"
                ~ " (tag = " ~  type_id ~ ")"
                );

        int len = inputStream.getLength();
        if (len > inputStream.available()) {
            throw new IOException("ObjectIdentifier() -- length exceeds" ~
                    "data available.  Length: " ~ len.to!string() ~ ", Available: " ~
                    inputStream.available().to!string());
        }
        encoding = new byte[len];
        inputStream.getBytes(encoding);
        check(encoding);
    }

    /*
     * Constructor, from the rest of a DER input buffer;
     * the tag and length have been removed/verified
     * Validity check NOT included.
     */
    this (DerInputBuffer buf)
    {
        DerInputStream inputStream = new DerInputStream(buf);
        encoding = new byte[inputStream.available()];
        inputStream.getBytes(encoding);
        check(encoding);
    }

    private void initilize(int[] components, int length) {
        int pos = 0;
        byte[] tmp = new byte[length*5+1];  // +1 for empty input

        if (components[1] < int.max - components[0]*40)
            pos += pack7Oid(components[0]*40+components[1], tmp, pos);
        else {
            BigInteger big = BigInteger(components[1]);
            big = big + BigInteger(components[0]*40);
            pos += pack7Oid(big, tmp, pos);
        }

        for (int i=2; i<length; i++) {
            pos += pack7Oid(components[i], tmp, pos);
        }
        encoding = tmp.dup;
        // encoding = new byte[pos];
        // System.arraycopy(tmp, 0, encoding, 0, pos);
    }

    /**
     * This method is kept for compatibility reasons. The new implementation
     * does the check and conversion. All around the JDK, the method is called
     * in static blocks to initialize pre-defined ObjectIdentifieies. No
     * obvious performance hurt will be made after this change.
     *
     * Old doc: Create a new ObjectIdentifier for internal use. The values are
     * neither checked nor cloned.
     */
    static ObjectIdentifier newInternal(int[] values) {
        try {
            return new ObjectIdentifier(values);
        } catch (IOException ex) {
            throw new RuntimeException(ex);
            // Should not happen, internal calls always uses legal values.
        }
    }

    /*
     * n.b. the only interface is DerOutputStream.putOID()
     */
    void encode (DerOutputStream ot)
    {
        ot.write (DerValue.tag_ObjectId, encoding);
    }

    /**
     * @deprecated Use equals((Object)oid)
     */
    // @Deprecated
    // bool equals(ObjectIdentifier other) {
    //     return equals((Object)other);
    // }

    /**
     * Compares this identifier with another, for equality.
     *
     * @return true iff the names are identical.
     */
    override bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        
        ObjectIdentifier other = cast(ObjectIdentifier)obj;
        if(other is null)
            return false;
        return encoding == other.encoding;
    }

    override size_t toHash() @trusted const nothrow {
        return hashOf(encoding);
    }

    /**
     * Private helper method for serialization. To be compatible with old
     * versions of JDK.
     * @return components in an int array, if all the components are less than
     *         int.max. Otherwise, null.
     */
    private int[] toIntArray() {
        size_t length = encoding.length;
        int[] result = new int[20];
        int which = 0;
        size_t fromPos = 0;
        for (size_t i = 0; i < length; i++) {
            if ((encoding[i] & 0x80) == 0) {
                // one section [fromPos..i]
                if (i - fromPos + 1 > 4) {
                    implementationMissing();
                    BigInteger big ; //= BigInteger(pack(encoding, fromPos, i-fromPos+1, 7, 8));
                    if (fromPos == 0) {
                        result[which++] = 2;
                        BigInteger second = big - BigInteger(80);
                        if (second > BigInteger(int.max)) {
                            return null;
                        } else {
                            result[which++] = second.toInt();
                        }
                    } else {
                        if (big > BigInteger(int.max)) {
                            return null;
                        } else {
                            result[which++] = big.toInt();
                        }
                    }
                } else {
                    int retval = 0;
                    for (size_t j = fromPos; j <= i; j++) {
                        retval <<= 7;
                        byte tmp = encoding[j];
                        retval |= (tmp & 0x07f);
                    }
                    if (fromPos == 0) {
                        if (retval < 80) {
                            result[which++] = retval / 40;
                            result[which++] = retval % 40;
                        } else {
                            result[which++] = 2;
                            result[which++] = retval - 80;
                        }
                    } else {
                        result[which++] = retval;
                    }
                }
                fromPos = i+1;
            }
            if (which >= result.length) {
                result = result[0..which + 10].dup; // Arrays.copyOf(result, which + 10);
            }
        }
        return  result[0..which].dup; //Arrays.copyOf(result, which);
    }

    /**
     * Returns a string form of the object ID.  The format is the
     * conventional "dot" notation for such IDs, without any
     * user-friendly descriptive strings, since those strings
     * will not be understood everywhere.
     */
    override
    string toString() {
        string s = stringForm;
        if (s is null) {
            size_t length = encoding.length;
            StringBuffer sb = new StringBuffer(length * 4);

            size_t fromPos = 0;
            for (size_t i = 0; i < length; i++) {
                if ((encoding[i] & 0x80) == 0) {
                    // one section [fromPos..i]
                    if (fromPos != 0) {  // not the first segment
                        sb.append('.');
                    }
                    if (i - fromPos + 1 > 4) { // maybe big integer
                        implementationMissing();
                        BigInteger big ; // = new BigInteger(pack(encoding, fromPos, i-fromPos+1, 7, 8));
                        if (fromPos == 0) {
                            // first section encoded with more than 4 bytes,
                            // must be 2.something
                            sb.append("2.");
                            sb.append(format("%d", big - BigInteger(80)));
                        } else {
                            sb.append(format("%d", big));
                        }
                    } else { // small integer
                        int retval = 0;
                        for (size_t j = fromPos; j <= i; j++) {
                            retval <<= 7;
                            byte tmp = encoding[j];
                            retval |= (tmp & 0x07f);
                        }
                        if (fromPos == 0) {
                            if (retval < 80) {
                                sb.append(retval/40);
                                sb.append('.');
                                sb.append(retval%40);
                            } else {
                                sb.append("2.");
                                sb.append(retval - 80);
                            }
                        } else {
                            sb.append(retval);
                        }
                    }
                    fromPos = i+1;
                }
            }
            s = sb.toString();
            stringForm = s;
        }
        return s;
    }

    /**
     * Repack all bits from input to output. On the both sides, only a portion
     * (from the least significant bit) of the 8 bits in a byte is used. This
     * number is defined as the number of useful bits (NUB) for the array. All the
     * used bits from the input byte array and repacked into the output in the
     * exactly same order. The output bits are aligned so that the final bit of
     * the input (the least significant bit in the last byte), when repacked as
     * the final bit of the output, is still at the least significant position.
     * Zeroes will be padded on the left side of the first output byte if
     * necessary. All unused bits in the output are also zeroed.
     *
     * For example: if the input is 01001100 with NUB 8, the output which
     * has a NUB 6 will look like:
     *      00000001 00001100
     * The first 2 bits of the output bytes are unused bits. The other bits
     * turn out to be 000001 001100. While the 8 bits on the right are from
     * the input, the left 4 zeroes are padded to fill the 6 bits space.
     *
     * @param in        the input byte array
     * @param ioffset   start point inside <code>in</code>
     * @param ilength   number of bytes to repack
     * @param iw        NUB for input
     * @param ow        NUB for output
     * @return          the repacked bytes
     */
    private static byte[] pack(byte[] data, size_t ioffset, size_t ilength, int iw, int ow) {
        assert (iw > 0 && iw <= 8, "input NUB must be between 1 and 8");
        assert (ow > 0 && ow <= 8, "output NUB must be between 1 and 8");

        if (iw == ow) {
            return data.dup;
        }

        size_t bits = ilength * iw;    // number of all used bits
        byte[] ot = new byte[(bits+ow-1)/ow];

        // starting from the 0th bit in the input
        size_t ipos = 0;

        // the number of padding 0's needed in the output, skip them
        size_t opos = (bits+ow-1)/ow*ow-bits;

        while(ipos < bits) {
            size_t count = iw - ipos%iw;   // unpacked bits in current input byte
            if (count > ow - opos%ow) { // free space available in output byte
                count = ow - opos%ow;   // choose the smaller number
            }
            // and move them!
            ot[opos/ow] |=                         // paste!
                (((data[ioffset+ipos/iw]+256)         // locate the byte (+256 so that it's never negative)
                    >> (iw-ipos%iw-count))          // move to the end of a byte
                        & ((1 << (count))-1))       // zero out all other bits
                            << (ow-opos%ow-count);  // move to the output position
            ipos += count;  // advance
            opos += count;  // advance
        }
        return ot;
    }

    /**
     * Repack from NUB 8 to a NUB 7 OID sub-identifier, remove all
     * unnecessary 0 headings, set the first bit of all non-tail
     * output bytes to 1 (as ITU-T Rec. X.690 8.19.2 says), and
     * paste it into an existing byte array.
     * @param ot the existing array to be pasted into
     * @param ooffset the starting position to paste
     * @return the number of bytes pasted
     */
    private static int pack7Oid(byte[] data, int ioffset, size_t ilength, byte[] ot, int ooffset) {
        byte[] pack = pack(data, ioffset, ilength, 8, 7);
        size_t packLenth = pack.length;
        size_t firstNonZero = packLenth-1;   // paste at least one byte        
        for (int i= cast(int)packLenth-2; i>=0; i--) {
            // tracef("i=%d, len=%d", i, packLenth);
            if (pack[i] != 0) {
                firstNonZero = i;
            }
            pack[i] |= 0x80;
        }
        // System.arraycopy(pack, firstNonZero, ot, ooffset, packLenth-firstNonZero);
        size_t len = packLenth-firstNonZero;
        ot[ooffset .. ooffset+len] = pack[firstNonZero .. firstNonZero+len];
        return cast(int)(packLenth-firstNonZero);
    }

    /**
     * Repack from NUB 7 to NUB 8, remove all unnecessary 0
     * headings, and paste it into an existing byte array.
     * @param ot the existing array to be pasted into
     * @param ooffset the starting position to paste
     * @return the number of bytes pasted
     */
    private static int pack8(byte[] data, int ioffset, int ilength, byte[] ot, int ooffset) {
        byte[] pack = pack(data, ioffset, ilength, 7, 8);
        size_t firstNonZero = pack.length-1;   // paste at least one byte
        for (int i=cast(int)pack.length-2; i>=0; i--) {
            if (pack[i] != 0) {
                firstNonZero = i;
            }
        }
        // System.arraycopy(pack, firstNonZero, ot, ooffset, pack.length-firstNonZero);
        size_t len = pack.length-firstNonZero;
        ot[ooffset .. ooffset+len] = pack[firstNonZero .. firstNonZero+len];
        return cast(int)(pack.length-firstNonZero);
    }

    /**
     * Pack the int into a OID sub-identifier DER encoding
     */
    private static int pack7Oid(int input, byte[] ot, int ooffset) {
        byte[] b = new byte[4];
        b[0] = cast(byte)(input >> 24);
        b[1] = cast(byte)(input >> 16);
        b[2] = cast(byte)(input >> 8);
        b[3] = cast(byte)(input);
        return pack7Oid(b, 0, 4, ot, ooffset);
    }

    /**
     * Pack the BigInteger into a OID subidentifier DER encoding
     */
    private static int pack7Oid(BigInteger input, byte[] ot, int ooffset) {
        implementationMissing();
        byte[] b = null; // input.toByteArray();
        return pack7Oid(b, 0, b.length, ot, ooffset);
    }

    /**
     * Private methods to check validity of OID. They must be --
     * 1. at least 2 components
     * 2. all components must be non-negative
     * 3. the first must be 0, 1 or 2
     * 4. if the first is 0 or 1, the second must be <40
     */

    /**
     * Check the DER encoding. Since DER encoding defines that the integer bits
     * are unsigned, so there's no need to check the MSB.
     */
    private static void check(byte[] encoding) {
        size_t length = encoding.length;
        if (length < 1 ||      // too short
                (encoding[length - 1] & 0x80) != 0) {  // not ended
            throw new IOException("ObjectIdentifier() -- " ~
                    "Invalid DER encoding, not ended");
        }
        for (size_t i=0; i<length; i++) {
            // 0x80 at the beginning of a subidentifier
            if (encoding[i] == cast(byte)0x80 &&
                    (i==0 || (encoding[i-1] & 0x80) == 0)) {
                throw new IOException("ObjectIdentifier() -- " ~
                        "Invalid DER encoding, useless extra octet detected");
            }
        }
    }
    private static void checkCount(size_t count) {
        if (count < 2) {
            throw new IOException("ObjectIdentifier() -- " ~
                    "Must be at least two oid components ");
        }
    }
    private static void checkFirstComponent(size_t first) {
        if (first < 0 || first > 2) {
            throw new IOException("ObjectIdentifier() -- " ~
                    "First oid component is invalid ");
        }
    }
    private static void checkFirstComponent(BigInteger first) {
        implementationMissing();
        // if (first.signum() == -1 ||
        //         first > BigInteger(2)) {
        //     throw new IOException("ObjectIdentifier() -- " ~
        //             "First oid component is invalid ");
        // }
    }
    private static void checkSecondComponent(size_t first, int second) {
        if (second < 0 || first != 2 && second > 39) {
            throw new IOException("ObjectIdentifier() -- " ~
                    "Second oid component is invalid ");
        }
    }
    private static void checkSecondComponent(size_t first, BigInteger second) {

        implementationMissing();
        // if (second.signum() == -1 ||
        //         first != 2 &&
        //         second > BigInteger(39)) {
        //     throw new IOException("ObjectIdentifier() -- " ~
        //             "Second oid component is invalid ");
        // }
    }
    private static void checkOtherComponent(size_t i, int num) {
        if (num < 0) {
            throw new IOException("ObjectIdentifier() -- " ~
                    "oid component #" ~ (i+1).to!string() ~ " must be non-negative ");
        }
    }
    private static void checkOtherComponent(size_t i, BigInteger num) {

        implementationMissing();
        // if (num.signum() == -1) {
        //     throw new IOException("ObjectIdentifier() -- " ~
        //             "oid component #" ~ (i+1).to!string() ~ " must be non-negative ");
        // }
    }
}
