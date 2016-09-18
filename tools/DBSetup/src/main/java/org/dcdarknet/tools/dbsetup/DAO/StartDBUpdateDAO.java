/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package org.dcdarknet.tools.dbsetup.DAO;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;

/**
 *
 * @author demetrius
 */
public class StartDBUpdateDAO {
    private long RunID = Long.MIN_VALUE;

    public StartDBUpdateDAO(Connection con) throws SQLException {
        String startUpdate = "{? = call start_db_update()}";
        try (CallableStatement cStmt = con.prepareCall(startUpdate)) {
            cStmt.registerOutParameter(1, Types.INTEGER);
            cStmt.executeUpdate();
            RunID = cStmt.getInt(1);
        }
    }

    /**
     * @return the RunID
     */
    public long getRunID() {
        return RunID;
    }

}
