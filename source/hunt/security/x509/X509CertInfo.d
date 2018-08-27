module hunt.security.x509.X509CertInfo;

import hunt.security.x509.CertAttrSet;
import hunt.security.x509.CertificateAlgorithmId;
import hunt.security.x509.CertificateExtensions;
import hunt.security.x509.CertificateSerialNumber;
import hunt.security.x509.CertificateValidity;
import hunt.security.x509.CertificateVersion;
import hunt.security.x509.CertificateX509Key;

import hunt.security.util.DerOutputStream;

import hunt.container.Enumeration;
import hunt.io.common;
import hunt.util.exception;

// import hunt.security.x509.CertAttrSet;
// import hunt.security.x509.CertAttrSet;

/**
 * The X509CertInfo class represents X.509 certificate information.
 *
 * <P>X.509 certificates have several base data elements, including:<UL>
 *
 * <LI>The <em>Subject Name</em>, an X.500 Distinguished Name for
 *      the entity (subject) for which the certificate was issued.
 *
 * <LI>The <em>Subject Public Key</em>, the key of the subject.
 *      This is one of the most important parts of the certificate.
 *
 * <LI>The <em>Validity Period</em>, a time period (e.g. six months)
 *      within which the certificate is valid (unless revoked).
 *
 * <LI>The <em>Issuer Name</em>, an X.500 Distinguished Name for the
 *      Certificate Authority (CA) which issued the certificate.
 *
 * <LI>A <em>Serial Number</em> assigned by the CA, for use in
 *      certificate revocation and other applications.
 *
 * @author Amit Kapoor
 * @author Hemma Prafullchandra
 * @see CertAttrSet
 * @see X509CertImpl
 */
class X509CertInfo : CertAttrSet!(string, Object) {
    /**
     * Identifier for this attribute, to be used with the
     * get, set, delete methods of Certificate, x509 type.
     */
    enum string IDENT = "x509.info";
    // Certificate attribute names
    enum string NAME = "info";
    enum string DN_NAME = "dname";
    enum string VERSION = CertificateVersion.NAME;
    enum string SERIAL_NUMBER = CertificateSerialNumber.NAME;
    enum string ALGORITHM_ID = CertificateAlgorithmId.NAME;
    enum string ISSUER = "issuer";
    enum string SUBJECT = "subject";
    enum string VALIDITY = CertificateValidity.NAME;
    enum string KEY = CertificateX509Key.NAME;
    enum string ISSUER_ID = "issuerID";
    enum string SUBJECT_ID = "subjectID";
    enum string EXTENSIONS = CertificateExtensions.NAME;

    // X509.v1 data
    // protected CertificateVersion _version = new CertificateVersion();
    // protected CertificateSerialNumber   serialNum = null;
    // protected CertificateAlgorithmId    algId = null;
    // protected X500Name                  issuer = null;
    // protected X500Name                  subject = null;
    // protected CertificateValidity       interval = null;
    // protected CertificateX509Key        pubKey = null;

    // X509.v2 & v3 extensions
    // protected UniqueIdentity   issuerUniqueId = null;
    // protected UniqueIdentity  subjectUniqueId = null;

    // X509.v3 extensions
    // protected CertificateExtensions     extensions = null;

    // Attribute numbers for internal manipulation
    private enum int ATTR_VERSION = 1;
    private enum int ATTR_SERIAL = 2;
    private enum int ATTR_ALGORITHM = 3;
    private enum int ATTR_ISSUER = 4;
    private enum int ATTR_VALIDITY = 5;
    private enum int ATTR_SUBJECT = 6;
    private enum int ATTR_KEY = 7;
    private enum int ATTR_ISSUER_ID = 8;
    private enum int ATTR_SUBJECT_ID = 9;
    private enum int ATTR_EXTENSIONS = 10;

    // DER encoded CertificateInfo data
    private byte[]      rawCertInfo = null;

    // The certificate attribute name to integer mapping stored here
    // private static final Map<string,Integer> map = new HashMap<string,Integer>();
    // static {
    //     map.put(VERSION, Integer.valueOf(ATTR_VERSION));
    //     map.put(SERIAL_NUMBER, Integer.valueOf(ATTR_SERIAL));
    //     map.put(ALGORITHM_ID, Integer.valueOf(ATTR_ALGORITHM));
    //     map.put(ISSUER, Integer.valueOf(ATTR_ISSUER));
    //     map.put(VALIDITY, Integer.valueOf(ATTR_VALIDITY));
    //     map.put(SUBJECT, Integer.valueOf(ATTR_SUBJECT));
    //     map.put(KEY, Integer.valueOf(ATTR_KEY));
    //     map.put(ISSUER_ID, Integer.valueOf(ATTR_ISSUER_ID));
    //     map.put(SUBJECT_ID, Integer.valueOf(ATTR_SUBJECT_ID));
    //     map.put(EXTENSIONS, Integer.valueOf(ATTR_EXTENSIONS));
    // }

    // /**
    //  * Construct an uninitialized X509CertInfo on which <a href="#decode">
    //  * decode</a> must later be called (or which may be deserialized).
    //  */
    // X509CertInfo() { }

    // /**
    //  * Unmarshals a certificate from its encoded form, parsing the
    //  * encoded bytes.  This form of constructor is used by agents which
    //  * need to examine and use certificate contents.  That is, this is
    //  * one of the more commonly used constructors.  Note that the buffer
    //  * must include only a certificate, and no "garbage" may be left at
    //  * the end.  If you need to ignore data at the end of a certificate,
    //  * use another constructor.
    //  *
    //  * @param cert the encoded bytes, with no trailing data.
    //  * @exception CertificateParsingException on parsing errors.
    //  */
    // X509CertInfo(byte[] cert) throws CertificateParsingException {
    //     try {
    //         DerValue    in = new DerValue(cert);

    //         parse(in);
    //     } catch (IOException e) {
    //         throw new CertificateParsingException(e);
    //     }
    // }

    // /**
    //  * Unmarshal a certificate from its encoded form, parsing a DER value.
    //  * This form of constructor is used by agents which need to examine
    //  * and use certificate contents.
    //  *
    //  * @param derVal the der value containing the encoded cert.
    //  * @exception CertificateParsingException on parsing errors.
    //  */
    // X509CertInfo(DerValue derVal) throws CertificateParsingException {
    //     try {
    //         parse(derVal);
    //     } catch (IOException e) {
    //         throw new CertificateParsingException(e);
    //     }
    // }

    /**
     * Appends the certificate to an output stream.
     *
     * @param stream an output stream to which the certificate is appended.
     * @exception CertificateException on encoding errors.
     * @exception IOException on other errors.
     */
    void encode(OutputStream stream)  {
        if (rawCertInfo is null) {
            DerOutputStream tmp = new DerOutputStream();
            emit(tmp);
            rawCertInfo = tmp.toByteArray();
        }
        stream.write(rawCertInfo.dup);
    }

    /**
     * Return an enumeration of names of attributes existing within this
     * attribute.
     */
    Enumeration!string getElements() {
        // AttributeNameEnumeration elements = new AttributeNameEnumeration();
        // elements.addElement(VERSION);
        // elements.addElement(SERIAL_NUMBER);
        // elements.addElement(ALGORITHM_ID);
        // elements.addElement(ISSUER);
        // elements.addElement(VALIDITY);
        // elements.addElement(SUBJECT);
        // elements.addElement(KEY);
        // elements.addElement(ISSUER_ID);
        // elements.addElement(SUBJECT_ID);
        // elements.addElement(EXTENSIONS);

        // return elements.elements();
        implementationMissing();
        return null;
    }

    /**
     * Return the name of this attribute.
     */
    string getName() {
        return(NAME);
    }

    /**
     * Returns the encoded certificate info.
     *
     * @exception CertificateEncodingException on encoding information errors.
     */
    byte[] getEncodedInfo() {
                implementationMissing();
        return null;

        // try {
        //     if (rawCertInfo is null) {
        //         DerOutputStream tmp = new DerOutputStream();
        //         emit(tmp);
        //         rawCertInfo = tmp.toByteArray();
        //     }
        //     return rawCertInfo.clone();
        // } catch (IOException e) {
        //     throw new CertificateEncodingException(e.toString());
        // } catch (CertificateException e) {
        //     throw new CertificateEncodingException(e.toString());
        // }
    }

    // /**
    //  * Compares two X509CertInfo objects.  This is false if the
    //  * certificates are not both X.509 certs, otherwise it
    //  * compares them as binary data.
    //  *
    //  * @param other the object being compared with this one
    //  * @return true iff the certificates are equivalent
    //  */
    // bool equals(Object other) {
    //     if (other instanceof X509CertInfo) {
    //         return equals((X509CertInfo) other);
    //     } else {
    //         return false;
    //     }
    // }

    // /**
    //  * Compares two certificates, returning false if any data
    //  * differs between the two.
    //  *
    //  * @param other the object being compared with this one
    //  * @return true iff the certificates are equivalent
    //  */
    // bool equals(X509CertInfo other) {
    //     if (this == other) {
    //         return(true);
    //     } else if (rawCertInfo is null || other.rawCertInfo is null) {
    //         return(false);
    //     } else if (rawCertInfo.length != other.rawCertInfo.length) {
    //         return(false);
    //     }
    //     for (int i = 0; i < rawCertInfo.length; i++) {
    //         if (rawCertInfo[i] != other.rawCertInfo[i]) {
    //             return(false);
    //         }
    //     }
    //     return(true);
    // }

    // /**
    //  * Calculates a hash code value for the object.  Objects
    //  * which are equal will also have the same hashcode.
    //  */
    // int hashCode() {
    //     int     retval = 0;

    //     for (int i = 1; i < rawCertInfo.length; i++) {
    //         retval += rawCertInfo[i] * i;
    //     }
    //     return(retval);
    // }

    /**
     * Returns a printable representation of the certificate.
     */
    override string toString() {
    implementationMissing();
        return "";

        // if (subject is null || pubKey is null || interval is null
        //     || issuer is null || algId is null || serialNum is null) {
        //         throw new NullPointerException("X.509 cert is incomplete");
        // }
        // StringBuilder sb = new StringBuilder();

        // sb.append("[\n");
        // sb.append("  " ~ _version.toString() ~ "\n");
        // sb.append("  Subject: " ~ subject.toString() ~ "\n");
        // sb.append("  Signature Algorithm: " ~ algId.toString() ~ "\n");
        // sb.append("  Key:  " ~ pubKey.toString() ~ "\n");
        // sb.append("  " ~ interval.toString() ~ "\n");
        // sb.append("  Issuer: " ~ issuer.toString() ~ "\n");
        // sb.append("  " ~ serialNum.toString() ~ "\n");

        // // optional v2, v3 extras
        // if (issuerUniqueId !is null) {
        //     sb.append("  Issuer Id:\n" ~ issuerUniqueId.toString() ~ "\n");
        // }
        // if (subjectUniqueId !is null) {
        //     sb.append("  Subject Id:\n" ~ subjectUniqueId.toString() ~ "\n");
        // }
        // if (extensions !is null) {
        //     Collection<Extension> allExts = extensions.getAllExtensions();
        //     Extension[] exts = allExts.toArray(new Extension[0]);
        //     sb.append("\nCertificate Extensions: " ~ exts.length);
        //     for (int i = 0; i < exts.length; i++) {
        //         sb.append("\n[" ~ (i+1) ~ "]: ");
        //         Extension ext = exts[i];
        //         try {
        //             if (OIDMap.getClass(ext.getExtensionId()) is null) {
        //                 sb.append(ext.toString());
        //                 byte[] extValue = ext.getExtensionValue();
        //                 if (extValue !is null) {
        //                     DerOutputStream stream = new DerOutputStream();
        //                     stream.putOctetString(extValue);
        //                     extValue = stream.toByteArray();
        //                     HexDumpEncoder enc = new HexDumpEncoder();
        //                     sb.append("Extension unknown: "
        //                               ~ "DER encoded OCTET string =\n"
        //                               + enc.encodeBuffer(extValue) ~ "\n");
        //                 }
        //             } else
        //                 sb.append(ext.toString()); //sub-class exists
        //         } catch (Exception e) {
        //             sb.append(", Error parsing this extension");
        //         }
        //     }
        //     Map<string,Extension> invalid = extensions.getUnparseableExtensions();
        //     if (invalid.isEmpty() == false) {
        //         sb.append("\nUnparseable certificate extensions: " ~ invalid.size());
        //         int i = 1;
        //         for (Extension ext : invalid.values()) {
        //             sb.append("\n[" ~ (i++) ~ "]: ");
        //             sb.append(ext);
        //         }
        //     }
        // }
        // sb.append("\n]");
        // return sb.toString();
    }

    /**
     * Set the certificate attribute.
     *
     * @params name the name of the Certificate attribute.
     * @params val the value of the Certificate attribute.
     * @exception CertificateException on invalid attributes.
     * @exception IOException on other errors.
     */
    void set(string name, Object val) {
        implementationMissing();
        // X509AttributeName attrName = new X509AttributeName(name);

        // int attr = attributeMap(attrName.getPrefix());
        // if (attr == 0) {
        //     throw new CertificateException("Attribute name not recognized: "
        //                                    + name);
        // }
        // // set rawCertInfo to null, so that we are forced to re-encode
        // rawCertInfo = null;
        // string suffix = attrName.getSuffix();

        // switch (attr) {
        // case ATTR_VERSION:
        //     if (suffix is null) {
        //         setVersion(val);
        //     } else {
        //         _version.set(suffix, val);
        //     }
        //     break;

        // case ATTR_SERIAL:
        //     if (suffix is null) {
        //         setSerialNumber(val);
        //     } else {
        //         serialNum.set(suffix, val);
        //     }
        //     break;

        // case ATTR_ALGORITHM:
        //     if (suffix is null) {
        //         setAlgorithmId(val);
        //     } else {
        //         algId.set(suffix, val);
        //     }
        //     break;

        // case ATTR_ISSUER:
        //     setIssuer(val);
        //     break;

        // case ATTR_VALIDITY:
        //     if (suffix is null) {
        //         setValidity(val);
        //     } else {
        //         interval.set(suffix, val);
        //     }
        //     break;

        // case ATTR_SUBJECT:
        //     setSubject(val);
        //     break;

        // case ATTR_KEY:
        //     if (suffix is null) {
        //         setKey(val);
        //     } else {
        //         pubKey.set(suffix, val);
        //     }
        //     break;

        // case ATTR_ISSUER_ID:
        //     setIssuerUniqueId(val);
        //     break;

        // case ATTR_SUBJECT_ID:
        //     setSubjectUniqueId(val);
        //     break;

        // case ATTR_EXTENSIONS:
        //     if (suffix is null) {
        //         setExtensions(val);
        //     } else {
        //         if (extensions is null)
        //             extensions = new CertificateExtensions();
        //         extensions.set(suffix, val);
        //     }
        //     break;
        // }
    }

    /**
     * Delete the certificate attribute.
     *
     * @params name the name of the Certificate attribute.
     * @exception CertificateException on invalid attributes.
     * @exception IOException on other errors.
     */
    void remove(string name) {
        implementationMissing();
        // X509AttributeName attrName = new X509AttributeName(name);

        // int attr = attributeMap(attrName.getPrefix());
        // if (attr == 0) {
        //     throw new CertificateException("Attribute name not recognized: "
        //                                    + name);
        // }
        // // set rawCertInfo to null, so that we are forced to re-encode
        // rawCertInfo = null;
        // string suffix = attrName.getSuffix();

        // switch (attr) {
        // case ATTR_VERSION:
        //     if (suffix is null) {
        //         _version = null;
        //     } else {
        //         _version.remove(suffix);
        //     }
        //     break;
        // case (ATTR_SERIAL):
        //     if (suffix is null) {
        //         serialNum = null;
        //     } else {
        //         serialNum.remove(suffix);
        //     }
        //     break;
        // case (ATTR_ALGORITHM):
        //     if (suffix is null) {
        //         algId = null;
        //     } else {
        //         algId.remove(suffix);
        //     }
        //     break;
        // case (ATTR_ISSUER):
        //     issuer = null;
        //     break;
        // case (ATTR_VALIDITY):
        //     if (suffix is null) {
        //         interval = null;
        //     } else {
        //         interval.remove(suffix);
        //     }
        //     break;
        // case (ATTR_SUBJECT):
        //     subject = null;
        //     break;
        // case (ATTR_KEY):
        //     if (suffix is null) {
        //         pubKey = null;
        //     } else {
        //         pubKey.remove(suffix);
        //     }
        //     break;
        // case (ATTR_ISSUER_ID):
        //     issuerUniqueId = null;
        //     break;
        // case (ATTR_SUBJECT_ID):
        //     subjectUniqueId = null;
        //     break;
        // case (ATTR_EXTENSIONS):
        //     if (suffix is null) {
        //         extensions = null;
        //     } else {
        //         if (extensions !is null)
        //            extensions.remove(suffix);
        //     }
        //     break;
        // }
    }

    /**
     * Get the certificate attribute.
     *
     * @params name the name of the Certificate attribute.
     *
     * @exception CertificateException on invalid attributes.
     * @exception IOException on other errors.
     */
    Object get(string name) {
        // X509AttributeName attrName = new X509AttributeName(name);

        // int attr = attributeMap(attrName.getPrefix());
        // if (attr == 0) {
        //     throw new CertificateParsingException(
        //                   "Attribute name not recognized: " ~ name);
        // }
        // string suffix = attrName.getSuffix();

        // switch (attr) { // frequently used attributes first
        // case (ATTR_EXTENSIONS):
        //     if (suffix is null) {
        //         return(extensions);
        //     } else {
        //         if (extensions is null) {
        //             return null;
        //         } else {
        //             return(extensions.get(suffix));
        //         }
        //     }
        // case (ATTR_SUBJECT):
        //     if (suffix is null) {
        //         return(subject);
        //     } else {
        //         return(getX500Name(suffix, false));
        //     }
        // case (ATTR_ISSUER):
        //     if (suffix is null) {
        //         return(issuer);
        //     } else {
        //         return(getX500Name(suffix, true));
        //     }
        // case (ATTR_KEY):
        //     if (suffix is null) {
        //         return(pubKey);
        //     } else {
        //         return(pubKey.get(suffix));
        //     }
        // case (ATTR_ALGORITHM):
        //     if (suffix is null) {
        //         return(algId);
        //     } else {
        //         return(algId.get(suffix));
        //     }
        // case (ATTR_VALIDITY):
        //     if (suffix is null) {
        //         return(interval);
        //     } else {
        //         return(interval.get(suffix));
        //     }
        // case (ATTR_VERSION):
        //     if (suffix is null) {
        //         return(_version);
        //     } else {
        //         return(_version.get(suffix));
        //     }
        // case (ATTR_SERIAL):
        //     if (suffix is null) {
        //         return(serialNum);
        //     } else {
        //         return(serialNum.get(suffix));
        //     }
        // case (ATTR_ISSUER_ID):
        //     return(issuerUniqueId);
        // case (ATTR_SUBJECT_ID):
        //     return(subjectUniqueId);
        // }
        return null;
    }

    // /*
    //  * Get the Issuer or Subject name
    //  */
    // private Object getX500Name(string name, bool getIssuer)
    //     {
    //     if (name.equalsIgnoreCase(X509CertInfo.DN_NAME)) {
    //         return getIssuer ? issuer : subject;
    //     } else if (name.equalsIgnoreCase("x500principal")) {
    //         return getIssuer ? issuer.asX500Principal()
    //                          : subject.asX500Principal();
    //     } else {
    //         throw new IOException("Attribute name not recognized.");
    //     }
    // }

    // /*
    //  * This routine unmarshals the certificate information.
    //  */
    // private void parse(DerValue val)
    // throws CertificateParsingException, IOException {
    //     DerInputStream  in;
    //     DerValue        tmp;

    //     if (val.tag != DerValue.tag_Sequence) {
    //         throw new CertificateParsingException("signed fields invalid");
    //     }
    //     rawCertInfo = val.toByteArray();

    //     in = val.data;

    //     // Version
    //     tmp = in.getDerValue();
    //     if (tmp.isContextSpecific((byte)0)) {
    //         _version = new CertificateVersion(tmp);
    //         tmp = in.getDerValue();
    //     }

    //     // Serial number ... an integer
    //     serialNum = new CertificateSerialNumber(tmp);

    //     // Algorithm Identifier
    //     algId = new CertificateAlgorithmId(in);

    //     // Issuer name
    //     issuer = new X500Name(in);
    //     if (issuer.isEmpty()) {
    //         throw new CertificateParsingException(
    //             "Empty issuer DN not allowed in X509Certificates");
    //     }

    //     // validity:  SEQUENCE { start date, end date }
    //     interval = new CertificateValidity(in);

    //     // subject name
    //     subject = new X500Name(in);
    //     if ((_version.compare(CertificateVersion.V1) == 0) &&
    //             subject.isEmpty()) {
    //         throw new CertificateParsingException(
    //                   "Empty subject DN not allowed in v1 certificate");
    //     }

    //     // key
    //     pubKey = new CertificateX509Key(in);

    //     // If more data available, make sure version is not v1.
    //     if (in.available() != 0) {
    //         if (_version.compare(CertificateVersion.V1) == 0) {
    //             throw new CertificateParsingException(
    //                       "no more data allowed for version 1 certificate");
    //         }
    //     } else {
    //         return;
    //     }

    //     // Get the issuerUniqueId if present
    //     tmp = in.getDerValue();
    //     if (tmp.isContextSpecific((byte)1)) {
    //         issuerUniqueId = new UniqueIdentity(tmp);
    //         if (in.available() == 0)
    //             return;
    //         tmp = in.getDerValue();
    //     }

    //     // Get the subjectUniqueId if present.
    //     if (tmp.isContextSpecific((byte)2)) {
    //         subjectUniqueId = new UniqueIdentity(tmp);
    //         if (in.available() == 0)
    //             return;
    //         tmp = in.getDerValue();
    //     }

    //     // Get the extensions.
    //     if (_version.compare(CertificateVersion.V3) != 0) {
    //         throw new CertificateParsingException(
    //                   "Extensions not allowed in v2 certificate");
    //     }
    //     if (tmp.isConstructed() && tmp.isContextSpecific((byte)3)) {
    //         extensions = new CertificateExtensions(tmp.data);
    //     }

    //     // verify X.509 V3 Certificate
    //     verifyCert(subject, extensions);

    // }

    // /*
    //  * Verify if X.509 V3 Certificate is compliant with RFC 3280.
    //  */
    // private void verifyCert(X500Name subject,
    //     CertificateExtensions extensions)
    //     throws CertificateParsingException, IOException {

    //     // if SubjectName is empty, check for SubjectAlternativeNameExtension
    //     if (subject.isEmpty()) {
    //         if (extensions is null) {
    //             throw new CertificateParsingException("X.509 Certificate is " ~
    //                     "incomplete: subject field is empty, and certificate " ~
    //                     "has no extensions");
    //         }
    //         SubjectAlternativeNameExtension subjectAltNameExt = null;
    //         SubjectAlternativeNameExtension extValue = null;
    //         GeneralNames names = null;
    //         try {
    //             subjectAltNameExt = (SubjectAlternativeNameExtension)
    //                     extensions.get(SubjectAlternativeNameExtension.NAME);
    //             names = subjectAltNameExt.get(
    //                     SubjectAlternativeNameExtension.SUBJECT_NAME);
    //         } catch (IOException e) {
    //             throw new CertificateParsingException("X.509 Certificate is " ~
    //                     "incomplete: subject field is empty, and " ~
    //                     "SubjectAlternativeName extension is absent");
    //         }

    //         // SubjectAlternativeName extension is empty or not marked critical
    //         if (names is null || names.isEmpty()) {
    //             throw new CertificateParsingException("X.509 Certificate is " ~
    //                     "incomplete: subject field is empty, and " ~
    //                     "SubjectAlternativeName extension is empty");
    //         } else if (subjectAltNameExt.isCritical() == false) {
    //             throw new CertificateParsingException("X.509 Certificate is " ~
    //                     "incomplete: SubjectAlternativeName extension MUST " ~
    //                     "be marked critical when subject field is empty");
    //         }
    //     }
    // }

    /*
     * Marshal the contents of a "raw" certificate into a DER sequence.
     */
    private void emit(DerOutputStream stream) {
        DerOutputStream tmp = new DerOutputStream();

        // // version number, iff not V1
        // _version.encode(tmp);

        // // Encode serial number, issuer signing algorithm, issuer name
        // // and validity
        // serialNum.encode(tmp);
        // algId.encode(tmp);

        // if ((_version.compare(CertificateVersion.V1) == 0) &&
        //     (issuer.toString() is null))
        //     throw new CertificateParsingException(
        //               "Null issuer DN not allowed in v1 certificate");

        // issuer.encode(tmp);
        // interval.encode(tmp);

        // // Encode subject (principal) and associated key
        // if ((_version.compare(CertificateVersion.V1) == 0) &&
        //     (subject.toString() is null))
        //     throw new CertificateParsingException(
        //               "Null subject DN not allowed in v1 certificate");
        // subject.encode(tmp);
        // pubKey.encode(tmp);

        // // Encode issuerUniqueId & subjectUniqueId.
        // if (issuerUniqueId !is null) {
        //     issuerUniqueId.encode(tmp, DerValue.createTag(DerValue.TAG_CONTEXT,
        //                                                   false,(byte)1));
        // }
        // if (subjectUniqueId !is null) {
        //     subjectUniqueId.encode(tmp, DerValue.createTag(DerValue.TAG_CONTEXT,
        //                                                    false,(byte)2));
        // }

        // // Write all the extensions.
        // if (extensions !is null) {
        //     extensions.encode(tmp);
        // }

        // // Wrap the data; encoding of the "raw" cert is now complete.
        // stream.write(DerValue.tag_Sequence, tmp);

                implementationMissing();

    }

    // /**
    //  * Returns the integer attribute number for the passed attribute name.
    //  */
    // private int attributeMap(string name) {
    //     Integer num = map.get(name);
    //     if (num is null) {
    //         return 0;
    //     }
    //     return num.intValue();
    // }

    // /**
    //  * Set the version number of the certificate.
    //  *
    //  * @params val the Object class value for the Extensions
    //  * @exception CertificateException on invalid data.
    //  */
    // private void setVersion(Object val) throws CertificateException {
    //     if (!(val instanceof CertificateVersion)) {
    //         throw new CertificateException("Version class type invalid.");
    //     }
    //     _version = (CertificateVersion)val;
    // }

    // /**
    //  * Set the serial number of the certificate.
    //  *
    //  * @params val the Object class value for the CertificateSerialNumber
    //  * @exception CertificateException on invalid data.
    //  */
    // private void setSerialNumber(Object val) throws CertificateException {
    //     if (!(val instanceof CertificateSerialNumber)) {
    //         throw new CertificateException("SerialNumber class type invalid.");
    //     }
    //     serialNum = (CertificateSerialNumber)val;
    // }

    // /**
    //  * Set the algorithm id of the certificate.
    //  *
    //  * @params val the Object class value for the AlgorithmId
    //  * @exception CertificateException on invalid data.
    //  */
    // private void setAlgorithmId(Object val) throws CertificateException {
    //     if (!(val instanceof CertificateAlgorithmId)) {
    //         throw new CertificateException(
    //                          "AlgorithmId class type invalid.");
    //     }
    //     algId = (CertificateAlgorithmId)val;
    // }

    // /**
    //  * Set the issuer name of the certificate.
    //  *
    //  * @params val the Object class value for the issuer
    //  * @exception CertificateException on invalid data.
    //  */
    // private void setIssuer(Object val) throws CertificateException {
    //     if (!(val instanceof X500Name)) {
    //         throw new CertificateException(
    //                          "Issuer class type invalid.");
    //     }
    //     issuer = (X500Name)val;
    // }

    // /**
    //  * Set the validity interval of the certificate.
    //  *
    //  * @params val the Object class value for the CertificateValidity
    //  * @exception CertificateException on invalid data.
    //  */
    // private void setValidity(Object val) throws CertificateException {
    //     if (!(val instanceof CertificateValidity)) {
    //         throw new CertificateException(
    //                          "CertificateValidity class type invalid.");
    //     }
    //     interval = (CertificateValidity)val;
    // }

    // /**
    //  * Set the subject name of the certificate.
    //  *
    //  * @params val the Object class value for the Subject
    //  * @exception CertificateException on invalid data.
    //  */
    // private void setSubject(Object val) throws CertificateException {
    //     if (!(val instanceof X500Name)) {
    //         throw new CertificateException(
    //                          "Subject class type invalid.");
    //     }
    //     subject = (X500Name)val;
    // }

    // /**
    //  * Set the key in the certificate.
    //  *
    //  * @params val the Object class value for the PublicKey
    //  * @exception CertificateException on invalid data.
    //  */
    // private void setKey(Object val) throws CertificateException {
    //     if (!(val instanceof CertificateX509Key)) {
    //         throw new CertificateException(
    //                          "Key class type invalid.");
    //     }
    //     pubKey = (CertificateX509Key)val;
    // }

    // /**
    //  * Set the Issuer Unique Identity in the certificate.
    //  *
    //  * @params val the Object class value for the IssuerUniqueId
    //  * @exception CertificateException
    //  */
    // private void setIssuerUniqueId(Object val) throws CertificateException {
    //     if (_version.compare(CertificateVersion.V2) < 0) {
    //         throw new CertificateException("Invalid version");
    //     }
    //     if (!(val instanceof UniqueIdentity)) {
    //         throw new CertificateException(
    //                          "IssuerUniqueId class type invalid.");
    //     }
    //     issuerUniqueId = (UniqueIdentity)val;
    // }

    // /**
    //  * Set the Subject Unique Identity in the certificate.
    //  *
    //  * @params val the Object class value for the SubjectUniqueId
    //  * @exception CertificateException
    //  */
    // private void setSubjectUniqueId(Object val) throws CertificateException {
    //     if (_version.compare(CertificateVersion.V2) < 0) {
    //         throw new CertificateException("Invalid version");
    //     }
    //     if (!(val instanceof UniqueIdentity)) {
    //         throw new CertificateException(
    //                          "SubjectUniqueId class type invalid.");
    //     }
    //     subjectUniqueId = (UniqueIdentity)val;
    // }

    // /**
    //  * Set the extensions in the certificate.
    //  *
    //  * @params val the Object class value for the Extensions
    //  * @exception CertificateException
    //  */
    // private void setExtensions(Object val) throws CertificateException {
    //     if (_version.compare(CertificateVersion.V3) < 0) {
    //         throw new CertificateException("Invalid version");
    //     }
    //     if (!(val instanceof CertificateExtensions)) {
    //       throw new CertificateException(
    //                          "Extensions class type invalid.");
    //     }
    //     extensions = (CertificateExtensions)val;
    // }
}
