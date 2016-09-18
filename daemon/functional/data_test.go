package functional

import (
	"database/sql"
	"testing"
	"time"

	"github.com/lib/pq/hstore"
)

type epicQuestMapEntry struct {
	LogicGroup  int64
	DisplayID   int64
	QuestName   string
	SuccessEpic *string
	FailedEpic  *string
	Terminator  *string
	Flags       int64
	Modality    string
}

type epic struct {
	ID                int64
	InternalName      string
	InternalDesc      string
	Author            string
	AuthorSite        string
	AuthorEmail       string
	AuthorPublic      bool
	AuthorSitePublic  bool
	AuthorEmailPublic bool
	StartDate         time.Time
	EndDate           time.Time
	GroupSize         int32
	Visibility        string
	Name              string
	StartText         string
	SuccessText       string
	FailText          string
	Desc              string
	InProgressDesc    string
	CompleteDesc      string
	LongDesc          string
	RepeatCount       int32
	Language          string
	Flags             int32
	ActivationRegex   *string
	QuestMap          []epicQuestMapEntry
}

type epicList []epic

type objective struct {
	ID              int64
	Type            string
	Index           int64
	Description     string
	Count           int64
	ActivationRegex *string
	FailRegex       *string
	Reward          *string
	RemoteEndpoint  *string
}

type quest struct {
	ID           int64
	InternalName string
	Name         string
	StartText    string
	SuccessText  string
	FailText     string
	SummaryText  string
	Reward       *string
	Language     string
	Objectives   []objective
}

type questList []quest

type reqEpic struct {
	InternalName      string
	RequiredEpicNames []string
}

type account struct {
	ID            int64
	ExternalID    string
	RemoteService string
	RemoteName    string
	Lang          string
	DisplayName   string
}

type accountList []account

type questStatus struct {
	Status          string
	ObjectiveCounts []int64
}

type item struct {
	ID           int64
	InternalName string
	InternalDesc string
	Type         string
	Name         string
	Desc         string
	MaxCount     int64
	Metadata     map[string]string
	Flags        int64
	Language     string
}

type itemList []item

func strPtr(s string) *string {
	return &s
}

func intPtr(i int64) *int64 {
	return &i
}

func (el epicList) getByName(name string) *epic {
	for _, e := range el {
		if e.InternalName == name {
			return &e
		}
	}
	return nil
}

// getID returns an epid ID given an internal name
func (el epicList) getID(name string) int64 {
	e := el.getByName(name)
	if e == nil {
		return 0
	}
	return e.ID
}

// getIDPtr returns a pointer to an epic id given a name
func (el epicList) getIDPtr(name string) *int64 {
	id := el.getID(name)
	if id == 0 {
		return nil
	}
	return &id
}

// getAvailable converts a list of test epics to availableEpics
func (el epicList) getAvailable(names ...string) []availableEpic {
	ret := make([]availableEpic, len(names))
	for i, name := range names {
		for _, e := range el {
			if e.InternalName == name {
				ret[i].ID = e.ID
				ret[i].Name = e.Name
				ret[i].Desc = e.Desc
				ret[i].LongDesc = e.LongDesc
				if e.EndDate != PositiveInfinityTS {
					ret[i].EndTime = &e.EndDate
				}
				ret[i].RepeatMax = e.RepeatCount
				ret[i].RepeatCount = 0
				ret[i].GroupSize = e.GroupSize
				ret[i].Flags = e.Flags
			}
		}
	}
	return ret
}

func (el epicList) getInProgress(name string, repeatCount int32, logicGroup int64, quests questList, questInfo map[string]questStatus) inProgressEpic {
	ret := inProgressEpic{}

	epic := el.getByName(name)
	if epic == nil {
		return ret
	}

	ret.Name = epic.Name
	ret.Desc = epic.InProgressDesc
	ret.LongDesc = epic.LongDesc
	if epic.EndDate != PositiveInfinityTS {
		ret.EndTime = &epic.EndDate
	}
	ret.RepeatMax = epic.RepeatCount
	ret.RepeatCount = repeatCount
	ret.GroupSize = epic.GroupSize
	ret.Flags = epic.Flags

	for _, qm := range epic.QuestMap {
		q := quests.getByName(qm.QuestName)
		iq := inProgressQuest{}

		iq.Name = q.Name
		iq.Summary = q.SummaryText
		iq.Desc = q.StartText
		iq.Status = "IN_PROGRESS"
		for _, o := range q.Objectives {
			io := inProgressObjective{}
			io.Count = o.Count
			io.Desc = o.Description
			iq.Objectives = append(iq.Objectives, io)
		}

		// modify quest and objectives based on status
		if qs, ok := questInfo[qm.QuestName]; ok {
			iq.Status = qs.Status
			switch qs.Status {
			case "SUCCESS":
				iq.Desc = q.SuccessText
			case "FAILED":
				iq.Desc = q.FailText
			}

			for i, v := range qs.ObjectiveCounts {
				iq.Objectives[i].CurrentCount = v
			}
		}

		ret.Quests = append(ret.Quests, iq)
	}

	return ret
}

func (ql questList) getByName(name string) *quest {
	for _, q := range ql {
		if q.InternalName == name {
			return &q
		}
	}
	return nil
}

func (ql questList) getID(name string) int64 {
	q := ql.getByName(name)
	if q == nil {
		return 0
	}
	return q.ID
}

// account accessors
func (al accountList) getByName(name string) *account {
	for _, a := range al {
		if a.DisplayName == name {
			return &a
		}
	}
	return nil
}

func (al accountList) getID(name string) int64 {
	a := al.getByName(name)
	if a == nil {
		return 0
	}
	return a.ID
}

// item accessors
func (il itemList) getByName(name string) *item {
	for _, i := range il {
		if i.InternalName == name {
			return &i
		}
	}
	return nil
}

func (il itemList) getID(name string) int64 {
	i := il.getByName(name)
	if i == nil {
		return 0
	}
	return i.ID
}

func upsertAccount(db *sql.DB, a *account) error {
	r := db.QueryRow("select * from live.upsert_account($1, $2, $3, $4, $5)",
		a.ExternalID,
		a.RemoteService,
		a.RemoteName,
		a.DisplayName,
		a.Lang)

	err := r.Scan(&a.ID)
	return err
}

func upsertEpic(db *sql.DB, e *epic) error {
	r := db.QueryRow("select * from static.epic_upsert($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24)",
		e.InternalName,
		e.InternalDesc,
		e.Author,
		e.AuthorSite,
		e.AuthorEmail,
		e.AuthorPublic,
		e.AuthorSitePublic,
		e.AuthorEmailPublic,
		e.StartDate,
		e.EndDate,
		e.GroupSize,
		e.Visibility,
		e.Name,
		e.StartText,
		e.SuccessText,
		e.FailText,
		e.Desc,
		e.InProgressDesc,
		e.CompleteDesc,
		e.LongDesc,
		e.RepeatCount,
		e.Language,
		e.Flags,
		e.ActivationRegex)

	err := r.Scan(&e.ID)
	return err
}

func upsertQuest(db *sql.DB, q *quest, rewards rewardList) error {
	var rewardID *int64
	if q.Reward != nil {
		rewardID = intPtr(rewards.getID(*q.Reward))
	}

	r := db.QueryRow("select * from static.quest_upsert($1, $2, $3, $4, $5, $6, $7, $8)",
		q.InternalName,
		q.Name,
		q.StartText,
		q.SuccessText,
		q.FailText,
		q.SummaryText,
		rewardID,
		q.Language)

	err := r.Scan(&q.ID)
	if err != nil {
		return err
	}

	for i := range q.Objectives {
		err = upsertObjective(db, &q.Objectives[i], rewards, q.ID, q.Language)
		if err != nil {
			return err
		}
	}
	return err
}

func upsertObjective(db *sql.DB, o *objective, rewards rewardList, questID int64, lang string) error {
	var rewardID *int64
	if o.Reward != nil {
		rewardID = intPtr(rewards.getID(*o.Reward))
	}
	var endpoint *string = o.RemoteEndpoint
	if endpoint != nil {
		endpoint = strPtr(TestRemoteServer.URL + *endpoint)
	}

	r := db.QueryRow("select * from static.objective_upsert($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
		questID,
		o.Index,
		o.Description,
		o.Count,
		o.ActivationRegex,
		o.FailRegex,
		rewardID,
		o.Type,
		endpoint,
		lang)

	err := r.Scan(&o.ID)
	return err
}

func setupQuestMap(db *sql.DB, e *epic) error {
	_, err := db.Exec("select static.epic_quest_map_sequence_delete($1)", e.ID)
	if err != nil {
		return err
	}

	for _, qm := range e.QuestMap {
		var successEpicID *int64
		if qm.SuccessEpic != nil {
			successEpicID = testEpics.getIDPtr(*qm.SuccessEpic)
		}
		var failedEpicID *int64
		if qm.FailedEpic != nil {
			failedEpicID = testEpics.getIDPtr(*qm.FailedEpic)
		}

		_, err = db.Exec("select static.epic_quest_map_create($1, $2, $3, $4, $5, $6, $7, $8)",
			qm.DisplayID,
			qm.LogicGroup,
			e.ID,
			testQuests.getID(qm.QuestName),
			successEpicID,
			failedEpicID,
			qm.Flags,
			qm.Modality)
		if err != nil {
			return err
		}
	}
	return nil
}

func setRequiredEpic(db *sql.DB, target int64, required int64) error {
	_, err := db.Exec("select static.epic_required_epics_create($1, $2)", target, required)
	return err
}

func resetAccount(db *sql.DB, accountID int64) error {
	_, err := db.Exec("select live.reset_account($1)", accountID)
	return err
}

func resetTestAccount(t *testing.T, accountID int64) {
	db, err := getDB()
	if err != nil {
		t.Fatalf("Unable to reset account: %v", err)
	}
	err = resetAccount(db, accountID)
	if err != nil {
		t.Fatalf("Unable to reset account: %v", err)
	}
}

func upsertItem(db *sql.DB, i *item) error {
	// create hstore
	hs := hstore.Hstore{Map: make(map[string]sql.NullString, len(i.Metadata))}
	for k, v := range i.Metadata {
		hs.Map[k] = sql.NullString{String: v, Valid: true}
	}

	r := db.QueryRow("select * from static.item_upsert($1, $2, $3, $4, $5, $6, $7, $8, $9)",
		i.InternalName,
		i.InternalDesc,
		i.Type,
		i.Name,
		i.Desc,
		i.MaxCount,
		hs,
		i.Flags,
		i.Language)

	err := r.Scan(&i.ID)
	return err
}
