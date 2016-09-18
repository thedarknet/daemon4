package org.dcdarknet.tools.dbsetup.util;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Reader;
import java.util.HashMap;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.bind.Unmarshaller;
import javax.xml.bind.ValidationEvent;
import javax.xml.bind.ValidationEventHandler;
import javax.xml.bind.ValidationEventLocator;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import org.w3c.dom.Node;

/**
 *
 * @author DemetriusC
 */
public class JaxbUtil {
    static private final boolean PROFILE = false;
    static public class DefaultValidationEventHandler implements ValidationEventHandler {
        /**
         * 
         * @param ve 
         * @return 
         */
        @Override
        public boolean handleEvent(ValidationEvent ve) {
            // ignore warnings
            if (ve.getSeverity() != ValidationEvent.WARNING) {
                ValidationEventLocator vel = ve.getLocator();
                System.out.println("Line:Col[" + vel.getLineNumber() +
                        ":" + vel.getColumnNumber() +
                        "]:" + ve.getMessage());
            }
            return true;
        }
    }
    /** Creates a new instance of JaxbUtil */
    public JaxbUtil() {
    }
    
    /**
     * deserialize given a file name to a JaxB object, without validation
     */
    public static Object load(String packageName, String fileName) throws IOException, JAXBException  {
        return load(packageName, new File(fileName));
    }
    
    public static Object load(String packageName, Node xmlNode) throws IOException, JAXBException  {
        final Unmarshaller u = getUnmarshaller(packageName);
        return u.unmarshal ( xmlNode );
    }
    
    public static Object load(String packageName, Reader reader) throws IOException, JAXBException  {
        final Unmarshaller u = getUnmarshaller(packageName);
        return u.unmarshal ( reader );
    }
    
    /**
     * deserialize from a File to a JaxB object, without validation
     * @param packageName
     * @param file
     * @return 
     * @throws java.io.IOException
     * @throws javax.xml.bind.JAXBException
     */
    public static Object load(String packageName, File file) throws IOException, JAXBException {
        return load(packageName, new FileInputStream(file));
    }
    
    /**
     * deserialize from an InputStream to a JaxB object, without validation
     * @param packageName
     * @param in
     * @return 
     * @throws java.io.IOException
     * @throws javax.xml.bind.JAXBException
     */
    public static Object load(String packageName, InputStream in) throws IOException, JAXBException {
        final Unmarshaller u = getUnmarshaller(packageName);
        Object retVal = u.unmarshal(in);
        return retVal;
    }
    

    /**
     * deserialize given a file name to a JaxB object, with validation and a default ValidationEventHandler
     * @param packageName
     * @param fileName
     * @param validationFile
     * @return 
     * @throws java.io.IOException
     * @throws javax.xml.bind.JAXBException
     */
    public static Object load(String packageName, String fileName, File validationFile) throws IOException, JAXBException  {
        return load(packageName, new File(fileName), validationFile);
    }
    
    /**
     * deserialize from a File to a JaxB object, with validation and a default ValidationEventHandler
     * @param packageName
     * @param file
     * @param validationFile
     * @return 
     * @throws java.io.IOException
     * @throws javax.xml.bind.JAXBException
     */
    public static Object load(String packageName, File file, File validationFile) throws IOException, JAXBException  {
        return load(packageName, new FileInputStream(file), validationFile);
    }
    
    /**
     * deserialize from an InputStream to a JaxB object, with validation and a default ValidationEventHandler
     * @param packageName
     * @param in
     * @param validationFile
     * @return 
     * @throws java.io.IOException
     * @throws javax.xml.bind.JAXBException
     */
    public static Object load(String packageName, InputStream in, File validationFile) throws IOException, JAXBException {
        return load(packageName, in, validationFile, new DefaultValidationEventHandler());
    }
    
        
    /**
     * deserialize given a file name to a JaxB object, with validation, using specified ValidationEventHandler
     * @param packageName
     * @param fileName
     * @param validationFile
     * @param veh
     * @return 
     * @throws java.io.IOException 
     * @throws javax.xml.bind.JAXBException 
     */
    public static Object load(String packageName, String fileName, File validationFile, ValidationEventHandler veh) 
    throws IOException, JAXBException  {
        return load(packageName, new File(fileName), validationFile, veh);
    }

    /**
     * deserialize from a File to a JaxB object, with validation, using specified ValidationEventHandler
     */
    public static Object load(String packageName, File file, File validationFile, ValidationEventHandler veh)
    throws IOException, JAXBException {
        return load(packageName, new FileInputStream(file), validationFile, veh);
    }

    /**
     * deserialize from an InputStream to a JaxB object, with validation, using specified ValidationEventHandler
     */
    public static Object load(String packageName, InputStream in, File validationFile, ValidationEventHandler veh)
    throws IOException, JAXBException {
        
        final Unmarshaller u = getUnmarshaller(packageName);
        SchemaFactory sf = SchemaFactory.newInstance(javax.xml.XMLConstants.W3C_XML_SCHEMA_NS_URI);
        try {
            Schema schema = sf.newSchema(validationFile);
            u.setSchema(schema);
            u.setEventHandler(veh);
        } catch (org.xml.sax.SAXException se) {
            System.out.println("Unable to validate the schema doc, due to following error.");
            se.printStackTrace();
        }
        return u.unmarshal(in);
    }
    
    /**
     *  Serialize a JaxB object out to a specified file given the file name, without validation.
     */
    public static void save(String packageName, Object root, String fileName) throws IOException, JAXBException  {
        save(packageName, root, new File(fileName));
    }
    
    /**
     *  Serialize a JaxB object out to a specified file, without validation.
     */
    public static void save(String packageName, Object root, File file) throws IOException, JAXBException {
        save(packageName, root, new FileOutputStream(file));
    }
    
    /**
     *  Serialize a JaxB object out to a specified file, given an output stream, without validation.
     */
    public static void save(String packageName, Object root, OutputStream out) throws IOException, JAXBException {
        HashMap<String,Object> props = new HashMap<String,Object>();
        props.put(Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE);
        save(packageName,root,props,out);
    }
    
    /**
     *  Serialize a JaxB object out to a specified file, given an output stream and marshaller properties, without validation.
     */
    public static void save(String packageName, Object root, HashMap<String, Object> Props, OutputStream out) throws IOException, JAXBException {
        final Marshaller m = getMarshaller(packageName);
        Set<String> keys = Props.keySet();
        for(String key : keys) {
            m.setProperty(key,Props.get(key));
        }
        m.marshal( root, out );
    }
    
    /**
     *  Serialize a JaxB object out to a specified file given a file name, with validation and a default ValidationEventHandler
     */
    public static void save(String packageName, Object root, String fileName, File validationFile) throws IOException, JAXBException  {
        save(packageName, root, new File(fileName), validationFile);        
    }

    /**
     *  Serialize a JaxB object out to a specified file, with validation and a default ValidationEventHandler
     */
    public static void save(String packageName, Object root, File file, File validationFile) throws IOException, JAXBException  {
        save(packageName, root, new FileOutputStream(file), validationFile);
    }
    
    /**
     *  Serialize a JaxB object out to a specified file given an output stream, with validation and a default ValidationEventHandler
     */
    public static void save(String packageName, Object root, OutputStream out, File validationFile) throws IOException, JAXBException  {
        save(packageName, root, out, validationFile, new DefaultValidationEventHandler());
    }
    
    /**
     *  Serialize a JaxB object out to a specified file given a file name, with validation and specified ValidationEventHandler
     */
    public static void save(String packageName, Object root, String fileName, File validationFile, ValidationEventHandler veh) throws IOException, JAXBException {
        save(packageName, root, new File(fileName), validationFile, veh);
    }
    /**
     *  Serialize a JaxB object out to a specified file, with validation and specified ValidationEventHandler
     */
    public static void save(String packageName, Object root, File file, File validationFile, ValidationEventHandler veh) throws IOException, JAXBException {
        save(packageName, root, new FileOutputStream(file), validationFile, veh);
    }
    
    public static void save(String packageName, Object root, OutputStream out, File validationFile, ValidationEventHandler veh) throws IOException, JAXBException {
        save(packageName,root,out,new StreamSource(validationFile),veh);
    }
    
    public static void save(String packageName, Object root, OutputStream out, StreamSource validationStream) throws IOException, JAXBException {
        save(packageName,root,out,validationStream,new DefaultValidationEventHandler());
    }
    
    /**
     *  Serialize a JaxB object out to a specified file given an output stream, with validation and specified ValidationEventHandler
     */
    public static void save(String packageName, Object root, OutputStream out, StreamSource validationStream, ValidationEventHandler veh) throws IOException, JAXBException {
        final Marshaller m = getMarshaller(packageName);
        m.setProperty( Marshaller.JAXB_FORMATTED_OUTPUT, Boolean.TRUE );
        
        SchemaFactory sf = SchemaFactory.newInstance(javax.xml.XMLConstants.W3C_XML_SCHEMA_NS_URI);
        try {
            Schema schema = sf.newSchema(validationStream);
            m.setSchema(schema);
            m.setEventHandler(veh);
        } catch (org.xml.sax.SAXException se) {
            System.out.println("Unable to validate the schema doc, due to following error.");
            se.printStackTrace();
        }
        m.marshal(root, out);
    }
    

    static public JAXBContext initJaxBContext(String packageName) throws JAXBException {
        JAXBContext jc = JaxBContextMap.get(packageName);
        if(jc==null) {
            jc = JAXBContext.newInstance(packageName);
            JaxBContextMap.put(packageName,jc);
        }
        return jc;
    }
    
    static public Unmarshaller getUnmarshaller(String packageName) throws JAXBException {
        JAXBContext jc = initJaxBContext(packageName);
        return jc.createUnmarshaller();
    }
    
    static public Marshaller getMarshaller(String packageName) throws JAXBException {
        JAXBContext jc = initJaxBContext(packageName);
        return jc.createMarshaller();
    }
    
    //private static HashMap<String,JAXBContext> JaxBContextMap = new HashMap<String,JAXBContext>();
    private static ConcurrentHashMap<String,JAXBContext> JaxBContextMap = new ConcurrentHashMap<String,JAXBContext>();
}
