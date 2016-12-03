package player

import (
	"log"

	"github.com/thedarknet/daemon4/daemon/service/internal/msg"
)

const (
	incObjType        = "incObj"
	incObjErrorType   = "incObjError"
	incObjSuccessType = "incObjSuccess"
)

// Register message handlers
func init() {
	msg.MustRegister(incObjType, (*Player).IncObj)
}

type IncObjData struct {
	Code      string `json:"code"`
	LiveEpic  string `json:"lepic"`
	LiveQuest string `json:"lquest"`
	LiveObj   string `json:"lobj"`
}

type IncObjErrorData struct {
	Type string `json:"type"`
}

type IncObjSuccessData struct {
	CurrentCount int64  `json:"current_count"`
	Count        int64  `json:"count"`
	Desc         string `json:"desc"`
}

func (p *Player) IncObj(msgID *string, d *IncObjData) error {
	log.Printf("incObj received from %d", p.ID)
	events, results, err := p.db.IncObj(p.ID, d.Code, d.LiveEpic, d.LiveQuest, d.LiveObj)
	if err != nil {
		log.Printf("Unable to increment objectives for %d with %s (%v)", p.ID, d.Code, err)
		return p.SendMessage(msgID, incObjErrorType, IncObjErrorData{Type: "SERVER_ERROR"})
	}

	if len(results) == 0 {
		return p.SendMessage(msgID, incObjErrorType, IncObjErrorData{Type: "INVALID_CODE"})
	}

	for _, res := range results {
		err = p.SendMessage(msgID, incObjSuccessType, IncObjSuccessData{CurrentCount: res.CurrentCount, Count: res.Count, Desc: res.Desc})
		if err != nil {
			return err
		}
	}

	var refreshEpics bool
	var refreshInventory bool

	for _, evt := range events {
		err = p.SendEvent(msgID, &evt)
		if err != nil {
			return err
		}

		// Refresh available epics if epics have changed
		if evt.Type == "EPIC" {
			refreshEpics = true
		}

		// refresh inventory
		if evt.Type == "ITEM" {
			refreshInventory = true
		}
	}

	if refreshEpics {
		err = p.RefreshAvailableEpics(msgID, nil)
		if err != nil {
			return err
		}
		err = p.RefreshCompletedEpics(msgID, nil)
		if err != nil {
			return err
		}
	}

	if refreshInventory {
		err = p.RefreshInventory(msgID, nil)
		if err != nil {
			return err
		}
	}

	// Always refresh in progress
	err = p.RefreshInProgressEpics(msgID, nil)
	if err != nil {
		return err
	}

	return nil
}
