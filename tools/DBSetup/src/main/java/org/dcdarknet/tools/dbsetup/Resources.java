package org.dcdarknet.tools.dbsetup;


import java.io.File;
import java.io.FileInputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/*
 * Reads in the config.properties file and gets a URL, Driver, Username, and Password
 * for use by the CreateConnection class to create a connection to the database.
 * Note: See notes in the App.java class for information on the location of the properties file.
 */
public class Resources {

    static final Logger Log = LoggerFactory.getLogger(Resources.class);
    private String Driver;
    private String Username;
    private String Password;
    private String DBConnectionURl;
    private Connection DBConnection;
    private String NamePrefix="";
    private String SchemaPrefix="";
    private String connection_init_sql="";
    

    Connection getConnection() throws ClassNotFoundException, SQLException {
        if (DBConnection == null) {
            Class.forName(this.getDriver());
            DBConnection = DriverManager.getConnection(this.getDBConnectionURl(), this.getUsername(), this.getPassword());
            if(!connection_init_sql.isEmpty()) {
                Statement s = DBConnection.createStatement();
                s.execute(connection_init_sql);
            }
        }
        return DBConnection;
    }

    public Resources(String env) throws Exception {
        // Load our argument defined environment properties file
        Properties prop = new Properties();
        File propFile = new File(env);
        String path = propFile.getAbsolutePath();
        Log.info("Properties: " + path);
        FileInputStream in = new FileInputStream(path);
        prop.load(in);
        
        DBConnectionURl = prop.getProperty("url") == null ? "" : prop.getProperty("url");
        Driver = prop.getProperty("driver") == null ? "" : prop.getProperty("driver");
        NamePrefix = prop.getProperty("iscontainerdb").equalsIgnoreCase("yes") ? "c##" : "";
        Password = prop.getProperty("password") == null ? "" : prop.getProperty("password");
        Username = prop.getProperty("username") == null ? "" : prop.getProperty("username");
        SchemaPrefix = prop.getProperty("schema_prefix") == null ? "" : prop.getProperty("schema_prefix");
        connection_init_sql = prop.getProperty("connection_init_sql") == null ? "" : prop.getProperty("connection_init_sql");
        
        // Load our local user overrides to the environment properties file
        Properties propLocal = new Properties();
        File propFileLocal = new File(env+".local");
        File pathLocal = propFileLocal.getAbsoluteFile();
        
        if (pathLocal.exists()){
            Log.info("Properties: " + pathLocal);
            FileInputStream inLocal = new FileInputStream(pathLocal);
            propLocal.load(inLocal);

            DBConnectionURl = propLocal.getProperty("url") == null ? DBConnectionURl : propLocal.getProperty("url");
            Driver = propLocal.getProperty("driver") == null ? Driver : propLocal.getProperty("driver");
            if (!(propLocal.getProperty("iscontainerdb") == null)){
                NamePrefix = propLocal.getProperty("iscontainerdb").equalsIgnoreCase("yes") ? "c##" : "";
            }
            Password = propLocal.getProperty("password") == null ? Password : propLocal.getProperty("password");
            Username = propLocal.getProperty("username") == null ? Username : propLocal.getProperty("username");
            SchemaPrefix = propLocal.getProperty("schema_prefix") == null ? SchemaPrefix: propLocal.getProperty("schema_prefix");
        }        
        Username = Username.trim();
        Password = Password.trim();
        DBConnectionURl = DBConnectionURl.trim();
        Driver = Driver.trim();
        SchemaPrefix = SchemaPrefix.trim();
        
        if (DBConnectionURl.isEmpty()) {
            throw new Exception("URL is missing from properties file.");
        }
        if (Driver.isEmpty()) {
            throw new Exception("Driver is missing from properties file.");
        }

    }

    public String getDriver() {
        return Driver;
    }

    public String getUsername() {
        return Username;
    }

    public String getPassword() {
        return Password;
    }

    /**
     * @return the DBConnectionURl
     */
    public String getDBConnectionURl() {
        return DBConnectionURl;
    }
}
