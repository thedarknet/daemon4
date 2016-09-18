package data

type DBError interface {
	Error() string
	Code() string
	Message() string
}

type BadgeData struct {
	RadioID int64
	PrivateKey []byte
	Flags int64
	RegKey string
	AccountID int64
}

type Database interface {
	Ping(triggerError bool) (int, DBError)
	Register(registrationCode string, accountID int64, displayName string) (int, DBError)
	MarkAsPaired(badge1 string, badge2 string) DBError
	GetBadgeDataByAccountID(accountID int64) (*BadgeData, DBError)
}
