package data

type DBError interface {
	Error() string
	Code() string
	Message() string
}

type Database interface {
	Ping(triggerError bool) (int, DBError)
	GetAvailableEpics(accountID int64) ([]AvailableEpic, DBError)
	GetInProgressEpics(accountID int64) ([]InProgressEpic, DBError)
	GetCompletedEpics(accountID int64) ([]CompletedEpic, DBError)
	GetCompletedEpicDetails(accountID int64, liveEpicID int64) ([]CompletedQuest, DBError)
	StartEpic(accountID int64, epicID *int64, code *string) ([]Event, []AvailableEpic, []InProgressEpic, DBError)
	IncObj(accountID int64, code string) ([]Event, []IncObjResult, error)
	GetInventory(accountID int64) (*Inventory, error)
}
