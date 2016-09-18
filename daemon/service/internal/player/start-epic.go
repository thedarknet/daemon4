package player

import (
	"log"

	"github.com/thedarknet/daemon4/daemon/service/internal/data"
	"github.com/thedarknet/daemon4/daemon/service/internal/msg"
)

const (
	startEpicType       = "startEpic"
	startEpicFailedType = "startEpicFailed"

	startEpicFailInProgress   = "IN_PROGRESS"
	startEpicFailNotAvailable = "NOT_AVAILABLE"
	startEpicFailError        = "ERROR"
)

// Register message handlers
func init() {
	msg.MustRegister(startEpicType, (*Player).StartEpic)
}

type StartEpicData struct {
	ID   *int64  `json:"epic_id,omitempty"`
	Code *string `json:"code,omitempty"`
}

type StartEpicFailedData struct {
	Reason string `json:"reason"`
}

func (p *Player) StartEpic(msgID *string, d *StartEpicData) error {
	log.Printf("startEpic received from %d", p.ID)
	events, available, inprogress, dberr := p.db.StartEpic(p.ID, d.ID, d.Code)
	if dberr != nil {
		reason := startEpicFailError
		switch dberr.Code() {
		case data.ErrorEpicNotAvailable:
			reason = startEpicFailNotAvailable
		case data.ErrorEpicInProgress:
			reason = startEpicFailInProgress
		}
		log.Printf("Unable to start epic for %d (%v)", p.ID, dberr)
		return p.SendMessage(msgID, startEpicFailedType, &StartEpicFailedData{Reason: reason})
	}

	for _, evt := range events {
		err := p.SendEvent(msgID, &evt)
		if err != nil {
			return err
		}
	}

	err := p.SendMessage(msgID, availableEpicsType, AvailableEpicsData{Epics: available})
	if err != nil {
		return err
	}
	err = p.SendMessage(msgID, inProgressEpicsType, InProgressEpicsData{Epics: inprogress})
	if err != nil {
		return err
	}
	return nil
}
