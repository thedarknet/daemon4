package main

import (
	"bytes"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"path"
)

type Migrate struct {
	db          *sql.DB
	txn         *sql.Tx
	Root        string
	PatchSchema string   `json:"patch_schema"`
	PatchTable  string   `json:"patch_table"`
	Patches     []string `json:"patches"`
	AlwaysRun   []string `json:"alwaysrun"`
	Post        []string `json:"post"`
}

type CurrentPatch struct {
	Name string
	Hash string
}

// Load unmarshales a migration spec from a json file
func Load(db *sql.DB, fileName string) (*Migrate, error) {
	f, err := ioutil.ReadFile(fileName)
	if err != nil {
		return nil, err
	}

	m := Migrate{db: db, Root: path.Dir(fileName)}
	err = json.Unmarshal(f, &m)
	if err != nil {
		return nil, err
	}

	return &m, nil
}

// Clear removes all objects in the database belonging to a user
func (m *Migrate) Clear(user string) error {
	query := fmt.Sprintf("DROP OWNED BY %s CASCADE", user)
	_, err := m.db.Exec(query)
	return err
}

// Migrate applies all patches that have not yet been applied as well
// as runs all scripts in the alwaysrun section of the migration definition
func (m *Migrate) Migrate() (migrateErr error) {
	// ensure schema is set up for patching
	err := m.ensurePatchTable()
	if err != nil {
		return err
	}

	// load any patches that exist
	curPatches, err := m.loadCurrentPatches()
	if err != nil {
		return err
	}

	// since Postgres supports transactional DDL, use it!
	m.txn, err = m.db.Begin()
	if err != nil {
		return err
	}
	defer func() {
		if migrateErr == nil {
			m.txn.Commit()
		} else {
			m.txn.Rollback()
		}
	}()

	// apply patches
	for _, patch := range m.Patches {
		patchContents, err := ioutil.ReadFile(path.Join(m.Root, patch))
		if err != nil {
			return err
		}

		hashBytes := sha256.Sum256(patchContents)
		hash := hex.EncodeToString(hashBytes[:])
		applied := false
		// check if patch has already been applied
		for _, appliedPatch := range curPatches {
			if appliedPatch.Name == patch {
				applied = true
				if appliedPatch.Hash != hash {
					return fmt.Errorf("%s has already been applied with a different hash", patch)
				}
				break
			}
		}

		// Patches are only applied once
		if applied {
			log.Printf("Patch already applied: %s", patch)
			continue
		}

		// Apply patch
		log.Printf("Applying: %s", patch)
		err = m.applyPatch(patchContents, patch, hash)
		if err != nil {
			return err
		}
	}

	// Apply all auto-run files
	for _, ar := range m.AlwaysRun {
		log.Printf("Running: %s", ar)
		contents, err := ioutil.ReadFile(path.Join(m.Root, ar))
		if err != nil {
			return err
		}

		err = m.apply(contents)
		if err != nil {
			return err
		}
	}

	// Apply all post files
	for _, ar := range m.Post {
		log.Printf("Running: %s", ar)
		contents, err := ioutil.ReadFile(path.Join(m.Root, ar))
		if err != nil {
			return err
		}

		err = m.apply(contents)
		if err != nil {
			return err
		}
	}

	return nil
}

// ensurePatchTable ensure that the schema and patch tables exist
func (m *Migrate) ensurePatchTable() error {
	// ensure schema exists
	schemaQuery := fmt.Sprintf("CREATE SCHEMA IF NOT EXISTS %s", m.PatchSchema)
	_, err := m.db.Exec(schemaQuery)
	if err != nil {
		return err
	}

	// ensure patch table exists
	tableQuery := fmt.Sprintf(
		`CREATE TABLE IF NOT EXISTS %s.%s (
	patch_name TEXT NOT NULL
  , applied TIMESTAMP NOT NULL
  , hash TEXT NOT NULL
)`, m.PatchSchema, m.PatchTable)

	_, err = m.db.Exec(tableQuery)
	return err
}

// loadCurrentPatches loads the list of current patches applied and their hashes
// to ensure no patch modifications have been made
func (m *Migrate) loadCurrentPatches() ([]CurrentPatch, error) {
	query := fmt.Sprintf("SELECT patch_name, hash FROM %s.%s", m.PatchSchema, m.PatchTable)
	rows, err := m.db.Query(query)
	if err != nil {
		return nil, err
	}

	patches := make([]CurrentPatch, 0)
	for rows.Next() {
		c := CurrentPatch{}
		err = rows.Scan(&c.Name, &c.Hash)
		if err != nil {
			return nil, err
		}
		patches = append(patches, c)
	}
	return patches, nil
}

// applyPatch applies a file and records it in the version table
func (m *Migrate) applyPatch(data []byte, name string, hash string) error {
	err := m.apply(data)
	if err != nil {
		return err
	}

	query := fmt.Sprintf("INSERT INTO %s.%s (patch_name, applied, hash) VALUES ($1, NOW(), $2)", m.PatchSchema, m.PatchTable)
	_, err = m.txn.Exec(query, name, hash)
	return err
}

// apply writes all queries from a byte array to the database
func (m *Migrate) apply(data []byte) error {
	// trim utf-9 BOM *sigh*
	trimmed := bytes.Trim(data, "\xef\xbb\xbf")

	_, err := m.txn.Exec(string(trimmed))
	return err
}
