/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package org.dcdarknet.tools.dbsetup;

import java.io.File;
import java.sql.Connection;
import org.dcdarknet.tools.dbsetup.generated.FileExecutionType;

/**
 *
 * @author demetrius
 */
public class ExecutionContext {

    private final Resources ContextResources;
    private long RunID = 0;
    private final File pFile;
    private final FileExecutionType Type;
    private final Connection VersionDBConnection;


    ExecutionContext(Connection verDBCon, Resources r, long rid, File f, FileExecutionType type) {
        ContextResources = r;
        RunID = rid;
        pFile = f;
        Type = type;
        VersionDBConnection = verDBCon;
    }

    public Connection getDBVersionCon() {return VersionDBConnection;}
    /**
     * @return the ContextResources
     */
    public Resources getContextResources() {
        return ContextResources;
    }

    /**
     * @return the RunID
     */
    public long getRunID() {
        return RunID;
    }

    /**
     * @return the pFile
     */
    public File getpFile() {
        return pFile;
    }

    /**
     * @return the Type
     */
    public FileExecutionType getType() {
        return Type;
    }
}
