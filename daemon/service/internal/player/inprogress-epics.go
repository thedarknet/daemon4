package player

import (
	"log"

	"github.com/thedarknet/daemon4/daemon/service/internal/data"
	"github.com/thedarknet/daemon4/daemon/service/internal/msg"
)

const (
	refreshInProgressEpicsType = "refreshInProgressEpics"
	inProgressEpicsType        = "inProgressEpics"
)

// Register message handlers
func init() {
	msg.MustRegister(refreshInProgressEpicsType, (*Player).RefreshInProgressEpics)
}

type RefreshInProgressEpicsData struct{}

type InProgressEpicsData struct {
	Epics []data.InProgressEpic `json:"epics"`
}

func (p *Player) RefreshInProgressEpics(msgID *string, data *RefreshInProgressEpicsData) error {
	log.Printf("refreshInProgressEpics received from %d", p.ID)
	return p.sendInProgressEpics(msgID)
}

func (p *Player) sendInProgressEpics(msgID *string) error {
	// read from db
	epics, err := p.db.GetInProgressEpics(p.ID)
	if err != nil {
		log.Printf("Unable to get in progress epics for %d (%v)", p.ID, err)
		return p.SendError("Server Error")
	}

	// send response to player
	return p.SendMessage(msgID, inProgressEpicsType, InProgressEpicsData{Epics: epics})
}
