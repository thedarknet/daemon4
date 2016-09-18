#Purpose of this tool

DBSetup is the tool we use to handle migration of DDL and Data in a relational database

(currently postgres).

#How do I run it:

Be in the same directory as the first dbfiles.xml file you want to run:

dbsetup verFile=../../../database/<somedb>/env/env.dbversion.properties dbfiles.xml

If you want to 'reset' your database use ­purge and provide a dbfiles.xml that has the

<purgeFile> tag set. Then provide the dbfiles.xml in the DBVersioning directory to ensure

the migration system is initialized. This only needs to be done if you are starting from an

empty db.

dbsetup ­purge dbfiles.xml DBVersioning/dbfiles.xml

Then for each target database & schema dbsetup is run.

Parameters:

* ­purge flag to denote you want to run the <purgeFile>

* verFile location of the properties file that has connection details for the database and

schema used to track migration scripts for the target db

* last parameter is a space separated list of all Project files (see what is a project file

below) to handle via migration.

#What goes in a Project File?

Usually called dbfiles.xml.

It is the file that tells the dbsetup tool what:

* purge file to run (if ­purge is passed on the command line) denoted via ```<purgeFile>...

<purgeFile>```

* what property file to so it has connection details to the target database ```<Env>...

</Env>```

* a list of "pre" files that should be run every time before migration starts, these files are

run in the order they appear in. ```<Pre><SqlFile/></Pre>```

* Usually not used.

* a list of "patch" files to be checked to see if they have been run against the db before,

and not run them otherwise skip them. ```<Patches><SqlFile/>...</Patches>```

* This is where most of the database migrations occur.

* Only forward migrations are supported.

* A list of "post" files to be run every time after the patch files.

* Useful for running grants

* <SqlFile> this take has a file and type attribute, file is simply the location of the file

relative to the Project (dbfiles.xml). There are curruently two types of sql files supported:

* sqlParseAndExecute ­ the file will be loaded split on ';' and each split run against the

database. This is useful runing multple DDL or DML statements.

* sql ­ the file is read into member then the entire contents of the file is sent to the

database (semicolons and all). This is useful for stored procedures.

```

<Project

xmlns:xsi='http://www.w3.org/2001/XMLSchema­instance'

xsi:noNamespaceSchemaLocation='file:DBFile.xsd'>

<!­­

<purgeFile type="sql" file="utils/purge.sql"></purgeFile>

­­>

<!­­

Files enumerated in here are run on every invocation of dbsetup.

This is a good place to put files that do db clean tasks that you want run before any db

deployment

­­>

<Pre>

<SqlFile type="" file=""></SqlFile>

</Pre>

<Patches>

<!­­

These files are run in order, checked to see if they have already been run against the

target database

if they have the file is skipped, if it has not it is run

=====

This is good for DDL (create, alter, drop tables), static data DML (inserts, updates,

etc, and static data meaning data that is reference data, eg: actions, steps, the mapping

of steps to actions, etc), and stored procedures that are used to create static data eg:

instead of using direct inserts and updates.

=======

Remeber your file names MUST be unique, so if you are using a stored procedure to

insert static data, then then add the file to the patches section *before* you call it. if you

need to update that stored procedure in the future, you need to save it as a different file

name and insert that file name into the patch list again so that other patch files can use

the stored proc with the updated implementation or interface.

========

­­>

<SqlFile file="patches/request.sql" type="sqlParseAndExecute"></SqlFile>

</Patches>

<Post>

<!­­

The files are run every time dbsetup is invoked.

Runtime stored procedures make sense to put here, eg: stored procs that aren't

called by the pre or patch sections.

This section is also good for dynamic sql scripts that generate sql. As an example: A

script that grants execute of all stored procedures owned by the _owner db user to the

_user db user.

­­>

<SqlFile file="sprocs/request_complete.sql" type="sql"></SqlFile>

<SqlFile file="sprocs/request_create.sql" type="sql"></SqlFile>

</Post>

</Project>

```

#How does it work:

Non: Purge flow:

* When DBSetup starts and connects to the version database (connection details in the

property file provided by the command line parameter verFile=, referenced below as the

VersionDBConnection) and calls start_db_udate. This stored proc does 2 things:

* Does a select for update on REF_DB_PATCH_RUN_RESULTS, this is only done to

hold a lock to ensure only 1 DBSetup is running against a database at a time.

* Acquires a sequence ID (counter) and inserts the start time and the sequence id (called

a 'runId' from this point forward) into the db_updates table.

* Connects to the TargetDB via the properties file specified by <Env> tag

(TargetDBConnection).

* Run all files in the <Pre> section of the Project file (dbfiles.xml) using the

TargetDBConnection.

* For each file in the <Patches> section:

* call patch_exists providing the stored procedure the runId and the file name using the

VersionDBConnection. This stored procedure checks to see if they file has already been

run against this database. If it has not it returns 0 and inserts into db_patches the runId,

the file, and a timestamp, otherwise it returns 1.

* If 0 was returned dbsetup runs the file against the TargetDBConnection then calls

patch_file_complete using the VersionDBConnection which updates the record in

db_patches with a timestamp and whether or not the file was successfully executed.

* Runs all files in the <Post> section using the TargetDBConnection.

* Finally runs db_update_complete on the VersionDBConnection to update the recorded

insert into db_updates via start_db_update with the result (1 for success, 0 for failure) and

a timestamp.

By querying the dbversioning tables (db_updates, db_patches) we can see when dbsetup

was run against a target database, what patch files were executed in that particular run of

DBSetup, how long each file took to execute and whether it completed successfully or

not, and how long the entire dbsetup run took and whether it was successful overall.
