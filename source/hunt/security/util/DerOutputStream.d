module hunt.security.util.DerOutputStream;

import hunt.io.ByteArrayOutputStream;
import hunt.security.util.DerEncoder;
import hunt.security.util.DerValue;

import hunt.io.common;
import hunt.util.exception;

import std.datetime;
import std.bitmanip;

/**
 * Output stream marshaling DER-encoded data.  This is eventually provided
 * in the form of a byte array; there is no advance limit on the size of
 * that byte array.
 *
 * <P>At this time, this class supports only a subset of the types of
 * DER data encodings which are defined.  That subset is sufficient for
 * generating most X.509 certificates.
 *
 *
 * @author David Brownell
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 */
class DerOutputStream : ByteArrayOutputStream, DerEncoder {
    /**
     * Construct an DER output stream.
     *
     * @param size how large a buffer to preallocate.
     */
    this(int size) { super(size); }

    /**
     * Construct an DER output stream.
     */
    this() { }

    alias write = ByteArrayOutputStream.write;

    /**
     * Writes tagged, pre-marshaled data.  This calcuates and encodes
     * the length, so that the output data is the standard triple of
     * { tag, length, data } used by all DER values.
     *
     * @param tag the DER value tag for the data, such as
     *          <em>DerValue.tag_Sequence</em>
     * @param buf buffered data, which must be DER-encoded
     */
    void write(byte tag, byte[] buf) {
        write(tag);
        putLength(cast(int)buf.length);
        write(buf, 0, cast(int)buf.length);
    }

    /**
     * Writes tagged data using buffer-to-buffer copy.  As above,
     * this writes a standard DER record.  This is often used when
     * efficiently encapsulating values in sequences.
     *
     * @param tag the DER value tag for the data, such as
     *          <em>DerValue.tag_Sequence</em>
     * @param ot buffered data
     */
    void write(byte tag, DerOutputStream ot) {
        write(tag);
        putLength(ot.count);
        write(ot.buf, 0, ot.count);
    }

    /**
     * Writes implicitly tagged data using buffer-to-buffer copy.  As above,
     * this writes a standard DER record.  This is often used when
     * efficiently encapsulating implicitly tagged values.
     *
     * @param tag the DER value of the context-specific tag that replaces
     * original tag of the value in the output, such as in
     * <pre>
     *          <em> <field> [N] IMPLICIT <type></em>
     * </pre>
     * For example, <em>FooLength [1] IMPLICIT INTEGER</em>, with value=4;
     * would be encoded as "81 01 04"  whereas in explicit
     * tagging it would be encoded as "A1 03 02 01 04".
     * Notice that the tag is A1 and not 81, this is because with
     * explicit tagging the form is always constructed.
     * @param value original value being implicitly tagged
     */
    void writeImplicit(byte tag, DerOutputStream value)
    {
        write(tag);
        write(value.buf, 1, value.count-1);
    }

    /**
     * Marshals pre-encoded DER value onto the output stream.
     */
    void putDerValue(DerValue val) {
        // val.encode(this);
        implementationMissing();
    }

    /*
     * PRIMITIVES -- these are "universal" ASN.1 simple types.
     *
     *  BOOLEAN, INTEGER, BIT STRING, OCTET STRING, NULL
     *  OBJECT IDENTIFIER, SEQUENCE(OF), SET(OF)
     *  PrintableString, T61String, IA5String, UTCTime
     */

    /**
     * Marshals a DER bool on the output stream.
     */
    void putBoolean(bool val) {
        write(DerValue.tag_Boolean);
        putLength(1);
        if (val) {
            write(0xff);
        } else {
            write(0);
        }
    }

    /**
     * Marshals a DER enumerated on the output stream.
     * @param i the enumerated value.
     */
    void putEnumerated(int i) {
        write(DerValue.tag_Enumerated);
        putIntegerContents(i);
    }

    /**
     * Marshals a DER integer on the output stream.
     *
     * @param i the integer in the form of a BigInt.
     */
    // void putInteger(BigInt i) {
    //     write(DerValue.tag_Integer);
    //     byte[]    buf = i.toByteArray(); // least number  of bytes
    //     putLength(buf.length);
    //     write(buf, 0, buf.length);
    // }

    /**
     * Marshals a DER integer on the output stream.
     * @param i the integer in the form of an Integer.
     */
    // void putInteger(Integer i) {
    //     putInteger(i.intValue());
    // }

    /**
     * Marshals a DER integer on the output stream.
     * @param i the integer.
     */
    void putInteger(int i) {
        write(DerValue.tag_Integer);
        putIntegerContents(i);
    }

    private void putIntegerContents(int i) {

        byte[] bytes = new byte[4];
        int start = 0;

        // Obtain the four bytes of the int

        bytes[3] = cast(byte) (i & 0xff);
        bytes[2] = cast(byte)((i & 0xff00) >>> 8);
        bytes[1] = cast(byte)((i & 0xff0000) >>> 16);
        bytes[0] = cast(byte)((i & 0xff000000) >>> 24);

        // Reduce them to the least number of bytes needed to
        // represent this int

        if (bytes[0] == cast(byte)0xff) {

            // Eliminate redundant 0xff

            for (int j = 0; j < 3; j++) {
                if ((bytes[j] == cast(byte)0xff) &&
                    ((bytes[j+1] & 0x80) == 0x80))
                    start++;
                else
                    break;
             }
         } else if (bytes[0] == 0x00) {

             // Eliminate redundant 0x00

            for (int j = 0; j < 3; j++) {
                if ((bytes[j] == 0x00) &&
                    ((bytes[j+1] & 0x80) == 0))
                    start++;
                else
                    break;
            }
        }

        putLength(4 - start);
        for (int k = start; k < 4; k++)
            write(bytes[k]);
    }

    /**
     * Marshals a DER bit string on the output stream. The bit
     * string must be byte-aligned.
     *
     * @param bits the bit string, MSB first
     */
    void putBitString(byte[] bits) {
        write(DerValue.tag_BitString);
        putLength(cast(int)bits.length + 1);
        write(0);               // all of last octet is used
        write(bits);
    }

    /**
     * Marshals a DER bit string on the output stream.
     * The bit strings need not be byte-aligned.
     *
     * @param bits the bit string, MSB first
     */
    void putUnalignedBitString(BitArray ba) {
        implementationMissing();
        // byte[] bits = ba.toByteArray();

        // write(DerValue.tag_BitString);
        // putLength(bits.length + 1);
        // write(bits.length*8 - ba.length()); // excess bits in last octet
        // write(bits);
    }

    /**
     * Marshals a truncated DER bit string on the output stream.
     * The bit strings need not be byte-aligned.
     *
     * @param bits the bit string, MSB first
     */
    // void putTruncatedUnalignedBitString(BitArray ba) {
    //     putUnalignedBitString(ba.truncate());
    // }

    /**
     * DER-encodes an ASN.1 OCTET STRING value on the output stream.
     *
     * @param octets the octet string
     */
    void putOctetString(byte[] octets) {
        write(DerValue.tag_OctetString, octets);
    }

    /**
     * Marshals a DER "null" value on the output stream.  These are
     * often used to indicate optional values which have been omitted.
     */
    void putNull() {
        write(DerValue.tag_Null);
        putLength(0);
    }

    /**
     * Marshals an object identifier (OID) on the output stream.
     * Corresponds to the ASN.1 "OBJECT IDENTIFIER" construct.
     */
    // void putOID(ObjectIdentifier oid) {
    //     oid.encode(this);
    // }

    /**
     * Marshals a sequence on the output stream.  This supports both
     * the ASN.1 "SEQUENCE" (zero to N values) and "SEQUENCE OF"
     * (one to N values) constructs.
     */
    // void putSequence(DerValue[] seq) {
    //     DerOutputStream bytes = new DerOutputStream();
    //     int i;

    //     for (i = 0; i < seq.length; i++)
    //         seq[i].encode(bytes);

    //     write(DerValue.tag_Sequence, bytes);
    // }

    /**
     * Marshals the contents of a set on the output stream without
     * ordering the elements.  Ok for BER encoding, but not for DER
     * encoding.
     *
     * For DER encoding, use orderedPutSet() or orderedPutSetOf().
     */
    // void putSet(DerValue[] set) {
    //     DerOutputStream bytes = new DerOutputStream();
    //     int i;

    //     for (i = 0; i < set.length; i++)
    //         set[i].encode(bytes);

    //     write(DerValue.tag_Set, bytes);
    // }

    /**
     * Marshals the contents of a set on the output stream.  Sets
     * are semantically unordered, but DER requires that encodings of
     * set elements be sorted into ascending lexicographical order
     * before being output.  Hence sets with the same tags and
     * elements have the same DER encoding.
     *
     * This method supports the ASN.1 "SET OF" construct, but not
     * "SET", which uses a different order.
     */
    // void putOrderedSetOf(byte tag, DerEncoder[] set) {
    //     putOrderedSet(tag, set, lexOrder);
    // }

    /**
     * Marshals the contents of a set on the output stream.  Sets
     * are semantically unordered, but DER requires that encodings of
     * set elements be sorted into ascending tag order
     * before being output.  Hence sets with the same tags and
     * elements have the same DER encoding.
     *
     * This method supports the ASN.1 "SET" construct, but not
     * "SET OF", which uses a different order.
     */
    // void putOrderedSet(byte tag, DerEncoder[] set) {
    //     putOrderedSet(tag, set, tagOrder);
    // }

    /**
     *  Lexicographical order comparison on byte arrays, for ordering
     *  elements of a SET OF objects in DER encoding.
     */
    // private static ByteArrayLexOrder lexOrder = new ByteArrayLexOrder();

    /**
     *  Tag order comparison on byte arrays, for ordering elements of
     *  SET objects in DER encoding.
     */
    // private static ByteArrayTagOrder tagOrder = new ByteArrayTagOrder();

    /**
     * Marshals a the contents of a set on the output stream with the
     * encodings of its sorted in increasing order.
     *
     * @param order the order to use when sorting encodings of components.
     */
    // private void putOrderedSet(byte tag, DerEncoder[] set,
    //                            Comparator<byte[]> order) {
    //     DerOutputStream[] streams = new DerOutputStream[set.length];

    //     for (int i = 0; i < set.length; i++) {
    //         streams[i] = new DerOutputStream();
    //         set[i].derEncode(streams[i]);
    //     }

    //     // order the element encodings
    //     byte[][] bufs = new byte[streams.length][];
    //     for (int i = 0; i < streams.length; i++) {
    //         bufs[i] = streams[i].toByteArray();
    //     }
    //     Arrays.<byte[]>sort(bufs, order);

    //     DerOutputStream bytes = new DerOutputStream();
    //     for (int i = 0; i < streams.length; i++) {
    //         bytes.write(bufs[i]);
    //     }
    //     write(tag, bytes);

    // }

    /**
     * Marshals a string as a DER encoded UTF8String.
     */
    void putUTF8String(string s) {
        writeString(s, DerValue.tag_UTF8String, "UTF8");
    }

    /**
     * Marshals a string as a DER encoded PrintableString.
     */
    void putPrintableString(string s) {
        writeString(s, DerValue.tag_PrintableString, "ASCII");
    }

    /**
     * Marshals a string as a DER encoded T61String.
     */
    void putT61String(string s) {
        /*
         * Works for characters that are defined in both ASCII and
         * T61.
         */
        writeString(s, DerValue.tag_T61String, "ISO-8859-1");
    }

    /**
     * Marshals a string as a DER encoded IA5String.
     */
    void putIA5String(string s) {
        writeString(s, DerValue.tag_IA5String, "ASCII");
    }

    /**
     * Marshals a string as a DER encoded BMPString.
     */
    void putBMPString(string s) {
        writeString(s, DerValue.tag_BMPString, "UnicodeBigUnmarked");
    }

    /**
     * Marshals a string as a DER encoded GeneralString.
     */
    void putGeneralString(string s) {
        writeString(s, DerValue.tag_GeneralString, "ASCII");
    }

    /**
     * Private helper routine for writing DER encoded string values.
     * @param s the string to write
     * @param stringTag one of the DER string tags that indicate which
     * encoding should be used to write the string out.
     * @param enc the name of the encoder that should be used corresponding
     * to the above tag.
     */
    private void writeString(string s, byte stringTag, string enc)
        {
implementationMissing();
        // byte[] data = s.getBytes(enc);
        // write(stringTag);
        // putLength(data.length);
        // write(data);
    }

    /**
     * Marshals a DER UTC time/date value.
     *
     * <P>YYMMDDhhmmss{Z|+hhmm|-hhmm} ... emits only using Zulu time
     * and with seconds (even if seconds=0) as per RFC 3280.
     */
    void putUTCTime(Date d) {
        putTime(d, DerValue.tag_UtcTime);
    }

    /**
     * Marshals a DER Generalized Time/date value.
     *
     * <P>YYYYMMDDhhmmss{Z|+hhmm|-hhmm} ... emits only using Zulu time
     * and with seconds (even if seconds=0) as per RFC 3280.
     */
    void putGeneralizedTime(Date d) {
        putTime(d, DerValue.tag_GeneralizedTime);
    }

    /**
     * Private helper routine for marshalling a DER UTC/Generalized
     * time/date value. If the tag specified is not that for UTC Time
     * then it defaults to Generalized Time.
     * @param d the date to be marshalled
     * @param tag the tag for UTC Time or Generalized Time
     */
    private void putTime(Date d, byte tag) {
        implementationMissing();

        /*
         * Format the date.
         */

        // TimeZone tz = TimeZone.getTimeZone("GMT");
        // string pattern = null;

        // if (tag == DerValue.tag_UtcTime) {
        //     pattern = "yyMMddHHmmss'Z'";
        // } else {
        //     tag = DerValue.tag_GeneralizedTime;
        //     pattern = "yyyyMMddHHmmss'Z'";
        // }

        // SimpleDateFormat sdf = new SimpleDateFormat(pattern, Locale.US);
        // sdf.setTimeZone(tz);
        // byte[] time = (sdf.format(d)).getBytes("ISO-8859-1");

        // /*
        //  * Write the formatted date.
        //  */

        // write(tag);
        // putLength(cast(int)time.length);
        // write(time);
    }

    /**
     * Put the encoding of the length in the stream.
     *
     * @params len the length of the attribute.
     * @exception IOException on writing errors.
     */
    void putLength(int len) {
        if (len < 128) {
            write(cast(byte)len);

        } else if (len < (1 << 8)) {
            write(cast(byte)0x081);
            write(cast(byte)len);

        } else if (len < (1 << 16)) {
            write(cast(byte)0x082);
            write(cast(byte)(len >> 8));
            write(cast(byte)len);

        } else if (len < (1 << 24)) {
            write(cast(byte)0x083);
            write(cast(byte)(len >> 16));
            write(cast(byte)(len >> 8));
            write(cast(byte)len);

        } else {
            write(cast(byte)0x084);
            write(cast(byte)(len >> 24));
            write(cast(byte)(len >> 16));
            write(cast(byte)(len >> 8));
            write(cast(byte)len);
        }
    }

    /**
     * Put the tag of the attribute in the stream.
     *
     * @params class the tag class type, one of UNIVERSAL, CONTEXT,
     *                            APPLICATION or PRIVATE
     * @params form if true, the value is constructed, otherwise it is
     * primitive.
     * @params val the tag value
     */
    void putTag(byte tagClass, bool form, byte val) {
        byte tag = cast(byte)(tagClass | val);
        if (form) {
            tag |= cast(byte)0x20;
        }
        write(tag);
    }

    /**
     *  Write the current contents of this <code>DerOutputStream</code>
     *  to an <code>OutputStream</code>.
     *
     *  @exception IOException on output error.
     */
    void derEncode(OutputStream ot) {
        ot.write(toByteArray());
    }
}
