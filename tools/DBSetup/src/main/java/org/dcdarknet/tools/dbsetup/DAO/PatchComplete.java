package org.dcdarknet.tools.dbsetup.DAO;


import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import org.slf4j.Logger;


/*
 * Sets the result of the patch run (patchRunResultID) to 1 for success or 0 for failure.
 * This keeps track of the successes and failures for individual patch files and stored procedures,
 * while the runResultID used in the TextFileData class keeps track of the success or failure
 * of the update as a whole.
 */
public class PatchComplete {

    private boolean DidComplete;

    public PatchComplete(Connection con, int updateSequenceID, String patchFile, int patchRunResultID, Logger logger) throws SQLException {
        String callPatchFileComplete = "{call patch_file_complete(?,?,?)}";
        StringBuilder output;
        output = new StringBuilder();
        output.append("Patch: ").append(patchFile);
        try (CallableStatement caStmt = con.prepareCall(callPatchFileComplete)) {
            caStmt.setString(1, patchFile);
            caStmt.setInt(2, updateSequenceID);
            caStmt.setInt(3, patchRunResultID);
            caStmt.executeUpdate();
            this.setDidComplete(true);
            caStmt.close();
            if (patchRunResultID == 0) {
                DidComplete = false;
                output.append(" - FAILED");
            }
            else{
                output.append(" - successful");
            }
        } catch (SQLException e) {
            DidComplete = false;
            System.out.println(e.getMessage() + "  " + patchFile);
            output.append("SQL Exception - " + e.getMessage() + "  in file  " + patchFile + "\n");
            logger.error(output.toString());
            throw (e);
        }
        logger.info(output.toString());
    }

    public boolean isDidComplete() {
        return DidComplete;
    }

    public void setDidComplete(boolean DidComplete) {
        this.DidComplete = DidComplete;
    }
}
