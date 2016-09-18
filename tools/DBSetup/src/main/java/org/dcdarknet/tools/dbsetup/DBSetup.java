package org.dcdarknet.tools.dbsetup;

import org.dcdarknet.tools.dbsetup.DAO.DBUpdateComplete;
import org.dcdarknet.tools.dbsetup.DAO.StartDBUpdateDAO;
import org.apache.commons.lang3.text.StrSubstitutor;

import javax.xml.bind.JAXBException;
import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import org.dcdarknet.tools.dbsetup.generated.FileType;
import org.dcdarknet.tools.dbsetup.generated.Project;
import org.dcdarknet.tools.dbsetup.generated.SQLFileListType;
import org.dcdarknet.tools.dbsetup.util.JaxbUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;




public class DBSetup {

    static final String usage = "DBSetup -purge verFile=Mandatory <space separated project files>\r\n"
            + "-purge is optional\r\n"
            + "verFile is properties file that must connect url, driver and optionally a username and password to connect to the database to check db versioning info\r\n"
            + "if you purge, and your migration (DBVersioning) info is in the same database you have to run DBVersioning/dbfiles.xml in the same run";
    private boolean Purge = false;
    public static final String DEFAULT_FILE_NAME = "dbfiles.xml";
    List<File> ProjectFilesToProcess = new ArrayList<>();
    private Resources DBVersionInfo = null;
    static final Logger Log = LoggerFactory.getLogger(DBSetup.class);

    public static void main(String[] args) {
        try {
            DBSetup dbsetup = new DBSetup(args);
            dbsetup.go();
        } catch (SQLException e) {
            Log.error("SQLState: " + e.getSQLState());
            Log.error("Error Code: " + e.getErrorCode());
            Log.error("Message: " + e.getMessage());

            Throwable t = e.getCause();
            while (t != null) {
                Log.error("Cause: " + t);
                t = t.getCause();
            }
            e.printStackTrace(System.out);
        } catch (Exception e) {
            Log.error(e.getMessage());
        }
    }

    private DBSetup() {
    }

    private DBSetup(String[] args) throws Exception {
        for (String sArg : args) {
            if (sArg.equals("-purge")) {
                this.setPurge(true);
            } else if (sArg.startsWith("verFile=")) {
                String DBVersionPropertiesFile = sArg.substring("verFile=".length());
                DBVersionInfo = new Resources(DBVersionPropertiesFile);
                DBVersionInfo.getConnection();
            } else if (sArg.equals("help") || sArg.equals("?")) {
                throw new Exception(usage);
            } else {
                File ProjectFile = new File(sArg);
                if (ProjectFile.exists()) {
                    Log.info("Project: " + ProjectFile.getAbsolutePath());
                    ProjectFilesToProcess.add(ProjectFile);
                } else {
                    throw new Exception("Given Project file does not exist: " +
                                        ProjectFile.getAbsolutePath());
                }
            }
        }
        if (ProjectFilesToProcess.isEmpty()) {
            Log.info("No project files provided, seeing if default project file exists: " +
                     DEFAULT_FILE_NAME);
            File ProjectFile = new File(DEFAULT_FILE_NAME);
            if (ProjectFile.exists()) {
                ProjectFilesToProcess.add(ProjectFile);
            } else {
                throw new Exception("No Projects files given and default does not exist: "
                                    + ProjectFile.getAbsolutePath());
            }
        }
        if (DBVersionInfo == null) {
            throw new Exception(usage);
        }
    }

    private void go() throws IOException, JAXBException, Exception {
        try(Connection con = this.getDBVersionInfo().getConnection()) {
            con.setAutoCommit(false);

            long runID = this.isPurge() ? -1 : (new StartDBUpdateDAO(con)).getRunID();
            String currentWorkingDir = System.getProperty("user.dir");
            StrSubstitutor env_substitute = new StrSubstitutor(System.getenv());
            try {
                Log.info("RunID is: " + runID);
                for (File currentFile : ProjectFilesToProcess) {
                    Log.info("========== Project: " + currentFile.getAbsoluteFile());
                    String newWorkingDir = currentFile.getAbsoluteFile().getParentFile().getAbsolutePath();
                    System.setProperty("user.dir", newWorkingDir);

                    Project currentProject = (Project) JaxbUtil.load("org.dcdarknet.tools.dbsetup.generated", currentFile);
                    String envFile = env_substitute.replace(currentProject.getEnv())
                                                   .replaceAll("[$][{].*[}]", "");
                    Resources ProjectResourceInfo = new Resources(envFile);

                    FileType purgeFile = currentProject.getPurgeFile();
                    if (purgeFile != null && this.isPurge()) {
                        File pFile = (new File(purgeFile.getFile())).getAbsoluteFile();
                        if (pFile.exists()) {
                            ExecutionContext ec = new ExecutionContext(con, ProjectResourceInfo,
                                                                       runID, pFile,
                                                                       purgeFile.getType());
                            SqlFile.execute(ec, false);
                        } else {
                            throw new Exception("PurgeFile does not exist: " + pFile.getAbsolutePath());
                        }
                    }

                    Log.info("---------- Patches (new only) ----------");
                    SQLFileListType patchList = currentProject.getPatches();
                    if (patchList != null && runID != -1) {
                        executeSqlFiles(con, ProjectResourceInfo,
                                        runID, patchList.getSqlFile(), true);
                    }

                    Log.info("---------- Post (always) ----------");
                    SQLFileListType postList = currentProject.getPost();
                    if (postList != null) {
                        executeSqlFiles(con, ProjectResourceInfo,
                                        runID, postList.getSqlFile(), false);
                    }
                    //reset working dir
                    System.setProperty("user.dir", currentWorkingDir);
                }
                if (runID != -1) {
                    DBUpdateComplete.go(con, runID, DBUpdateComplete.DBUPDATE_RESULT.SUCCESS);
                }
                Log.info("======================================");
                Log.info("Complete");
                Log.info("======================================");
                con.commit();
            } catch (Exception t) {
                if (this.getDBVersionInfo() != null && runID != -1) {
                    DBUpdateComplete.go(con, runID, DBUpdateComplete.DBUPDATE_RESULT.FAILURE);
                }
                con.commit();
                throw t;
            }
        }
    }

    private void executeSqlFiles(Connection versionDBCon,
                                 Resources resources,
                                 long runID,
                                 List<FileType> sqlFile,
                                 boolean doPatchCheck) throws Exception {
        for (FileType ft : sqlFile) {
            File pFile = (new File(ft.getFile())).getAbsoluteFile();
            if (pFile.exists()) {
                ExecutionContext ec = new ExecutionContext(versionDBCon, resources,
                                                           runID, pFile, ft.getType());
                SqlFile.execute(ec, doPatchCheck);
            } else {
                throw new Exception("Patch file does not exist: " + pFile.getAbsolutePath());
            }
        }
    }

    /**
     * @return the Purge mode
     */
    public boolean isPurge() {
        return Purge;
    }

    /**
     * @param set Purge mode
     */
    public void setPurge(boolean Purge) {
        this.Purge = Purge;
    }

    /**
     * @return the DBVersionInfo
     */
    public Resources getDBVersionInfo() {
        return DBVersionInfo;
    }
}
