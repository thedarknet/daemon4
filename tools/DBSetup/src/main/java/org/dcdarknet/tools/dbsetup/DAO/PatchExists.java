package org.dcdarknet.tools.dbsetup.DAO;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;

/*
 * Checks to see if the current patch or stored proc has already been run.
 * 
 */
public class PatchExists {

    public static boolean patchExists(Connection con, long runID, String patchFile) throws SQLException {
        boolean DoesExist = false;
        String callPatchExist = "{ ? = call patch_exist(?,?)}";
        try (CallableStatement cStmt = con.prepareCall(callPatchExist)) {
            cStmt.registerOutParameter(1, Types.INTEGER);
            cStmt.setLong(2, runID);
            cStmt.setString(3, patchFile);
            cStmt.executeUpdate();
            DoesExist = cStmt.getInt(1) == 0;
            cStmt.close();
        }
        return DoesExist;
    }
}
