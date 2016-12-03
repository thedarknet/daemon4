package data

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/lib/pq/hstore"
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
	row := s.db.QueryRow("SELECT ping FROM live.ping($1)", triggerError)

	var output int
	err := row.Scan(&output)
	if err != nil {
		return 0, newError(err)
	}
	return output, nil
}

// GetAvailableEpics retrieves any epics that the player is eligible to see and start
func (s *serviceDB) GetAvailableEpics(accountID int64) ([]AvailableEpic, DBError) {
	rows, err := s.db.Query("SELECT * FROM live.get_available_epics($1)", accountID)
	if err != nil {
		return nil, newError(err)
	}

	epics := []AvailableEpic{}

	defer rows.Close()
	for rows.Next() {
		epic := AvailableEpic{}
		err = rows.Scan(&epic.ID, &epic.Name, &epic.Desc, &epic.LongDesc, &epic.EndTime, &epic.RepeatMax, &epic.RepeatCount, &epic.GroupSize, &epic.Flags)
		if err != nil {
			return nil, newError(err)
		}
		epics = append(epics, epic)
	}
	return epics, nil
}

// GetInProgressEpics retrives all data about epics that are currently in progress for the account
func (s *serviceDB) GetInProgressEpics(accountID int64) ([]InProgressEpic, DBError) {
	// read objectives
	rows, err := s.db.Query("SELECT * FROM live.get_inprogress_objectives($1)", accountID)
	if err != nil {
		return nil, newError(err)
	}

	objs := []InProgressObjective{}

	defer rows.Close()
	for rows.Next() {
		obj := InProgressObjective{}
		err = rows.Scan(&obj.questID, &obj.Desc, &obj.CurrentCount, &obj.Count)
		if err != nil {
			return nil, newError(err)
		}
		objs = append(objs, obj)
	}

	// read quests
	rows, err = s.db.Query("SELECT * FROM live.get_inprogress_quests($1)", accountID)
	if err != nil {
		return nil, newError(err)
	}

	quests := []InProgressQuest{}

	defer rows.Close()
	for rows.Next() {
		quest := InProgressQuest{}
		err = rows.Scan(&quest.QuestID, &quest.epicID, &quest.Name, &quest.Summary, &quest.Desc, &quest.Status)
		if err != nil {
			return nil, newError(err)
		}

		// hook up objectives
		for _, obj := range objs {
			if obj.questID == quest.QuestID {
				quest.Objectives = append(quest.Objectives, obj)
			}
		}
		quests = append(quests, quest)
	}

	// read epics
	rows, err = s.db.Query("SELECT * FROM live.get_inprogress_epics($1)", accountID)
	if err != nil {
		return nil, newError(err)
	}

	epics := []InProgressEpic{}

	defer rows.Close()
	for rows.Next() {
		epic := InProgressEpic{}
		err = rows.Scan(&epic.epicID, &epic.Name, &epic.Desc, &epic.LongDesc, &epic.EndTime, &epic.RepeatMax, &epic.RepeatCount, &epic.GroupSize, &epic.Flags)
		if err != nil {
			return nil, newError(err)
		}

		// hook up quests
		for _, quest := range quests {
			if quest.epicID == epic.epicID {
				epic.Quests = append(epic.Quests, quest)
			}
		}

		epics = append(epics, epic)
	}
	return epics, nil
}

// GetCompletedEpics retrieves any epics that the player has completed or failed
func (s *serviceDB) GetCompletedEpics(accountID int64) ([]CompletedEpic, DBError) {
	rows, err := s.db.Query("SELECT * FROM live.get_completed_epics($1)", accountID)
	if err != nil {
		return nil, newError(err)
	}

	epics := []CompletedEpic{}

	defer rows.Close()
	for rows.Next() {
		epic := CompletedEpic{}
		err = rows.Scan(&epic.ID, &epic.Name, &epic.Desc, &epic.LongDesc, &epic.GroupSize, &epic.Flags, &epic.Status, &epic.CompleteTime)
		if err != nil {
			return nil, newError(err)
		}
		epics = append(epics, epic)
	}
	return epics, nil
}

// GetCompletedEpicDetails retrieves quest information from a completed epic
func (s *serviceDB) GetCompletedEpicDetails(accountID int64, liveEpicID int64) ([]CompletedQuest, DBError) {
	rows, err := s.db.Query("SELECT * FROM live.get_completed_epic_details($1, $2)", accountID, liveEpicID)
	if err != nil {
		return nil, newError(err)
	}

	quests := []CompletedQuest{}

	defer rows.Close()
	for rows.Next() {
		q := CompletedQuest{}
		err = rows.Scan(&q.Name, &q.Summary, &q.Desc, &q.Status, &q.Modality, &q.CompleteTime)
		if err != nil {
			return nil, newError(err)
		}
		quests = append(quests, q)
	}
	return quests, nil
}

// StartEpic attempt to begin a new epic. An error is returned if the epic is unavailable or already started.
func (s *serviceDB) StartEpic(accountID int64, epicID *int64, code *string) ([]Event, []AvailableEpic, []InProgressEpic, DBError) {
	rows, err := s.db.Query("SELECT * FROM live.start_epic($1, $2, $3)", accountID, epicID, code)
	if err != nil {
		return nil, nil, nil, newError(err)
	}

	events := make([]Event, 0)

	for rows.Next() {
		evt := Event{}
		err = rows.Scan(&evt.Type, &evt.Action, &evt.Desc, &evt.Count)
		if err != nil {
			return nil, nil, nil, newError(err)
		}
		events = append(events, evt)
	}

	available, err := s.GetAvailableEpics(accountID)
	if err != nil {
		return nil, nil, nil, newError(err)
	}

	inprogress, err := s.GetInProgressEpics(accountID)
	if err != nil {
		return nil, nil, nil, newError(err)
	}

	return events, available, inprogress, nil
}

// IncObj attempts to increment objectives based on a code
func (s *serviceDB) IncObj(accountID int64, code string, lepicId string, lquestId string, lobjId string) ([]Event, []IncObjResult, error) {
	log.Printf("Calling inc_obj_for_code with %d, %s.", accountID, code)
	rows, err := s.db.Query("SELECT * FROM live.inc_obj_by_code($1, $2, $3, $4, $5)", accountID, code, lepicId, lquestId, lobjId)
	if err != nil {
		return nil, nil, newError(err)
	}
	log.Printf("Nice!  Good job, dude.")

	events := make([]Event, 0)
	results := make([]IncObjResult, 0)

	// txn has already been closed
	// so calling remote endpoints will not block the db
	defer rows.Close()
	for rows.Next() {
		var objID *int64
		var remoteEndpoint *string
		var currentCount *int64
		var count *int64
		var objectType *string
		var actionType *string
		var actionText *string
		var actionCount *int64

		err = rows.Scan(&objID, &remoteEndpoint, &currentCount, &count, &objectType, &actionType, &actionText, &actionCount)
		if err != nil {
			return nil, nil, newError(err)
		}

		// remote endpoint
		if objID != nil && remoteEndpoint != nil {
			remoteEvents, remoteResults, err := s.handleRemoteEndpoint(accountID, code, *objID, *remoteEndpoint)
			if err != nil {
				// ignore remote errors
				log.Printf("Remote error calling %s for %d (%v). Skipping remote objective.", remoteEndpoint, accountID, err)
			}

			for _, e := range remoteEvents {
				events = append(events, e)
			}
			for _, r := range remoteResults {
				results = append(results, r)
			}
		}

		// events
		if objectType != nil && actionType != nil && actionText != nil && actionCount != nil {
			evt := Event{
				Type:   *objectType,
				Action: *actionType,
				Desc:   *actionText,
				Count:  *actionCount,
			}
			events = append(events, evt)
		}

		// result
		if currentCount != nil && count != nil && actionText != nil {
			res := IncObjResult{
				CurrentCount: *currentCount,
				Count:        *count,
				Desc:         *actionText,
			}
			results = append(results, res)
		}
	}
	return events, results, nil
}

func (s *serviceDB) incObjRemote(objID int64, count int64, metadata map[string]string) ([]Event, []IncObjResult, error) {
	// create hstore
	hs := hstore.Hstore{Map: make(map[string]sql.NullString, len(metadata))}
	for k, v := range metadata {
		hs.Map[k] = sql.NullString{String: v, Valid: true}
	}

	rows, err := s.db.Query("SELECT * FROM live.inc_obj_for_remote($1, $2, $3)", objID, count, hs)
	if err != nil {
		return nil, nil, newError(err)
	}

	events := make([]Event, 0)
	results := make([]IncObjResult, 0)

	// txn has already been closed
	// so calling remote endpoints will not block the db
	defer rows.Close()
	for rows.Next() {
		var currentCount *int64
		var count *int64
		var objectType *string
		var actionType *string
		var actionText *string
		var actionCount *int64

		err = rows.Scan(&currentCount, &count, &objectType, &actionType, &actionText, &actionCount)
		if err != nil {
			return nil, nil, newError(err)
		}

		// events
		if objectType != nil && actionType != nil && actionText != nil && actionCount != nil {
			evt := Event{
				Type:   *objectType,
				Action: *actionType,
				Desc:   *actionText,
				Count:  *actionCount,
			}
			events = append(events, evt)
		}

		// result
		if currentCount != nil && count != nil && actionText != nil {
			res := IncObjResult{
				CurrentCount: *currentCount,
				Count:        *count,
				Desc:         *actionText,
			}
			results = append(results, res)
		}
	}
	return events, results, nil
}

func (s *serviceDB) GetInventory(accountID int64) (*Inventory, error) {
	rows, err := s.db.Query("SELECT * FROM live.inventory_get($1)", accountID)
	if err != nil {
		return nil, newError(err)
	}

	inv := &Inventory{Bags: make(map[string]*Bag)}

	// txn has already been closed
	// so calling remote endpoints will not block the db
	defer rows.Close()
	for rows.Next() {
		var bagType string
		var metadata hstore.Hstore
		var item Item
		err = rows.Scan(&bagType, &item.ItemType, &item.Name, &item.Desc, &item.Flags, &item.Count, &item.MaxCount, &metadata)
		if err != nil {
			return nil, err
		}

		for k, v := range metadata.Map {
			if v.Valid {
				if item.Metadata == nil {
					item.Metadata = make(map[string]string)
				}
				item.Metadata[k] = v.String
			}
		}

		if _, ok := inv.Bags[bagType]; !ok {
			inv.Bags[bagType] = &Bag{}
		}

		inv.Bags[bagType].Items = append(inv.Bags[bagType].Items, &item)
	}
	return inv, nil
}

// handle remote objectives
func (s *serviceDB) handleRemoteEndpoint(accountID int64, code string, objID int64, remoteEndpoint string) ([]Event, []IncObjResult, error) {
	rows, err := s.db.Query("SELECT * FROM live.account_get_remote_data($1)", accountID)
	if err != nil {
		return nil, nil, newError(err)
	}

	req := RemoteRequest{
		Code:      code,
		AccountID: accountID,
		Inventory: RemoteInventory{
			Bags: make(map[string]*RemoteBag),
		},
	}

	defer rows.Close()
	for rows.Next() {
		var bagType *string
		var itemType *string
		var flags *int64
		var count *int64
		var maxCount *int64
		var metadata *hstore.Hstore
		err := rows.Scan(&req.DisplayName, &req.Lang, &bagType, &itemType, &flags, &count, &maxCount, &metadata)
		if err != nil {
			return nil, nil, err
		}
		if bagType != nil && itemType != nil && flags != nil && count != nil && maxCount != nil {
			bag, ok := req.Inventory.Bags[*bagType]
			if !ok {
				bag = &RemoteBag{}
				req.Inventory.Bags[*bagType] = bag
			}

			item := &RemoteItem{
				ItemType: *itemType,
				Flags:    *flags,
				Count:    *count,
				MaxCount: *maxCount,
			}
			if metadata != nil {
				item.Metadata = make(map[string]string)
				for k, v := range metadata.Map {
					if v.Valid {
						item.Metadata[k] = v.String
					}
				}
			}
			bag.Items = append(bag.Items, item)
		}
	}

	// call endpoint
	body, err := json.Marshal(&req)
	if err != nil {
		return nil, nil, err
	}

	c := http.Client{Timeout: 5 * time.Second}
	resp, err := c.Post(remoteEndpoint, "application/json", bytes.NewReader(body))
	if err != nil {
		return nil, nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, nil, fmt.Errorf("Error calling remote endpoint. Expected 200 got %d", resp.StatusCode)
	}

	var remoteData = RemoteResponse{}
	err = json.NewDecoder(resp.Body).Decode(&remoteData)
	if err != nil {
		return nil, nil, err
	}

	var events []Event
	var res []IncObjResult

	if remoteData.Success {
		if remoteData.Inc > 0 {
			events, res, err = s.incObjRemote(objID, remoteData.Inc, remoteData.Metadata)
			if err != nil {
				return nil, nil, err
			}
		}
	} else {
		// TODO: handle success=false
	}

	if len(remoteData.Message) > 0 {
		evt := Event{
			Type:   "OBJ",
			Action: "STATUS",
			Desc:   remoteData.Message,
			Count:  1,
		}
		events = append(events, evt)
	}

	return events, res, nil
}
