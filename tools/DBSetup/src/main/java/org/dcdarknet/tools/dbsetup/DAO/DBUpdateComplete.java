/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package org.dcdarknet.tools.dbsetup.DAO;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;

/**
 *
 * @author demetrius
 */
public class DBUpdateComplete {

    public static void go(Connection con, long runID, DBUPDATE_RESULT runResult) throws SQLException {
        String startUpdate = "{ call db_update_complete(?,?) }";
        try (CallableStatement cStmt = con.prepareCall(startUpdate)) {
            cStmt.setLong(1, runID);
            cStmt.setInt(2, runResult.ordinal());
            cStmt.executeUpdate();
        }
    }

    public enum DBUPDATE_RESULT {

        FAILURE(0), SUCCESS(1);
        int Result;

        private DBUPDATE_RESULT(int Result) {
            this.Result = Result;
        }
    };
}
