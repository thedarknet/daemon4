package data

import (
	"database/sql"
	"encoding/hex"
	"time"
)

type serviceDB struct {
	db *sql.DB
}

// NewServiceDB creates a new store backed by Postgres
func NewServiceDB(conn string) (Database, error) {
	var err error
	s := &serviceDB{}

	s.db, err = sql.Open("postgres", conn)
	if err != nil {
		return nil, err
	}
	return s, nil
}

// Ping
func (s *serviceDB) Ping(triggerError bool) (int, DBError) {
	row := s.db.QueryRow("SELECT ping FROM badge.ping($1)", triggerError)

	var output int
	err := row.Scan(&output)
	if err != nil {
		return 0, newError(err)
	}
	return output, nil
}

func (s *serviceDB) Register(registrationCode string, accountID int64, displayName string) (int, DBError) {
	row := s.db.QueryRow("SELECT register FROM badge.register($1,$2,$3)", accountID, registrationCode, displayName)
	var output int
	err := row.Scan(&output)
	if err != nil {
		return 0, newError(err)
	}
	return output, nil
}

func (s *serviceDB) MarkAsPaired(badge1 string, badge2 string) DBError {
	return nil
}

func (s *serviceDB) GetBadgeDataByAccountID(accountID int64) (*BadgeData, DBError) {
	row := s.db.QueryRow("SELECT * FROM badge.data_by_accountid($1)", accountID)

	badge := BadgeData{}
	var pk string
	var displayName string
	var createTime time.Time
	err := row.Scan(&badge.RadioID, &pk, &badge.Flags, &badge.RegKey, &badge.AccountID, &displayName, &createTime)
	if err != nil {
		dbErr := newError(err)
		if dbErr.Code() != "00000" {
			return nil, newError(err)
		}
		// no badge found, this is ok
		return nil, nil
	}

	badge.PrivateKey, err = hex.DecodeString(pk)
	if err != nil {
		return nil, newError(err)
	}

	return &badge, nil
}
