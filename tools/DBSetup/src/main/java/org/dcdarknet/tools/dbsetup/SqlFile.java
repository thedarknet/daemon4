/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package org.dcdarknet.tools.dbsetup;

import org.dcdarknet.tools.dbsetup.DAO.PatchComplete;
import org.dcdarknet.tools.dbsetup.DAO.PatchExists;
import org.apache.commons.io.input.BOMInputStream;

import java.io.FileInputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import org.dcdarknet.tools.dbsetup.generated.FileExecutionType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;



/**
 *
 * @author demetrius
 */
public class SqlFile {
    static private Logger logger = LoggerFactory.getLogger(SqlFile.class);

    static void execute(ExecutionContext ec, boolean bIsPatch) throws ClassNotFoundException, SQLException, IOException {
        if(shouldRunFile(ec, bIsPatch)) {
            logger.info("  RUN: " + ec.getpFile().getName());
            FileInputStream fr = new FileInputStream(ec.getpFile());
            BOMInputStream bomis = new BOMInputStream(fr);
            byte buf[] = new byte[4096];
            int bytesRead = 0;
            StringBuilder sb = new StringBuilder();
            while((bytesRead=bomis.read(buf))!=-1) {
                sb.append(new String(buf, 0, bytesRead));
            }
            String fileContents = sb.toString();
            
            Connection con = ec.getContextResources().getConnection();
            if(ec.getType().equals(FileExecutionType.SQL)) {
                try (Statement stmt = con.createStatement()) {
                    stmt.execute(fileContents);
                }
                catch (SQLException e) {
                    didRunFile(ec, bIsPatch, 0);
                    throw e;
                }
            } else {
                String []strStmts = fileContents.split(";");
                for(String s : strStmts) {
                    if (s.trim().length() > 0){
                        try(Statement stmt = con.createStatement()) {
                            stmt.execute(s);
                        }
                        catch (SQLException e) {
                            didRunFile(ec, bIsPatch, 0);
                            throw e;
                        }
                    }
                }
            }
            didRunFile(ec, bIsPatch, 1);
        } else {
           logger.info(String.format(" done: %s", ec.getpFile().getName()));
        }
    }

    private static boolean shouldRunFile(ExecutionContext ec, boolean bIsPatch) throws ClassNotFoundException, SQLException {
        if (!bIsPatch) {
            return true;
        }
        return PatchExists.patchExists(ec.getDBVersionCon(), ec.getRunID(), ec.getpFile().getName());
    }
    
    private static void didRunFile(ExecutionContext ec, boolean bIsPatch, int runResult) throws ClassNotFoundException, SQLException {
        if (bIsPatch) {
            PatchComplete pc = new PatchComplete(ec.getDBVersionCon(), (int)ec.getRunID(), ec.getpFile().getName(), runResult, logger);
        } else {
           // String output = "File: " + ec.getpFile().getName() + " will be executed next\n";
           // logger.info(output);
        }
    }
}
