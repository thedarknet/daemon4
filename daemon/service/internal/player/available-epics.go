package player

import (
	"log"

	"github.com/thedarknet/daemon4/daemon/service/internal/data"
	"github.com/thedarknet/daemon4/daemon/service/internal/msg"
)

const (
	refreshAvailableEpicsType = "refreshAvailableEpics"
	availableEpicsType        = "availableEpics"
)

// Register message handlers
func init() {
	msg.MustRegister(refreshAvailableEpicsType, (*Player).RefreshAvailableEpics)
}

type RefreshAvailableEpicsData struct{}

type AvailableEpicsData struct {
	Epics []data.AvailableEpic `json:"epics"`
}

func (p *Player) RefreshAvailableEpics(msgID *string, data *RefreshAvailableEpicsData) error {
	log.Printf("refreshAvailableEpics received from %d", p.ID)
	return p.sendAvailableEpics(msgID)
}

func (p *Player) sendAvailableEpics(msgID *string) error {
	// read from db
	epics, err := p.db.GetAvailableEpics(p.ID)
	if err != nil {
		log.Printf("Unable to get epics for %d (%v)", p.ID, err)
		return p.SendError("Server Error")
	}

	// send response to player
	return p.SendMessage(msgID, availableEpicsType, AvailableEpicsData{Epics: epics})
}
