package player

import (
	"log"

	"github.com/thedarknet/daemon4/daemon/service/internal/data"
	"github.com/thedarknet/daemon4/daemon/service/internal/msg"
)

const (
	refreshCompletedEpicsType = "refreshCompletedEpics"
	completedEpicsType        = "completedEpics"

	requestCompletedEpicDetailsType = "requestCompletedEpicDetails"
	completedEpicDetailsType        = "completedEpicDetails"
)

// Register message handlers
func init() {
	msg.MustRegister(refreshCompletedEpicsType, (*Player).RefreshCompletedEpics)
	msg.MustRegister(requestCompletedEpicDetailsType, (*Player).RequestCompletedEpicDetails)
}

type RefreshCompletedEpicsData struct{}

type CompletedEpicsData struct {
	Epics []data.CompletedEpic `json:"epics"`
}

func (p *Player) RefreshCompletedEpics(msgID *string, data *RefreshCompletedEpicsData) error {
	log.Printf("refreshCompletedEpics received from %d", p.ID)
	return p.sendCompletedEpics(msgID)
}

func (p *Player) sendCompletedEpics(msgID *string) error {
	// read from db
	epics, err := p.db.GetCompletedEpics(p.ID)
	if err != nil {
		log.Printf("Unable to get completed epics for %d (%v)", p.ID, err)
		return p.SendError("Server Error")
	}

	// send response to player
	return p.SendMessage(msgID, completedEpicsType, CompletedEpicsData{Epics: epics})
}

type RequestCompletedEpicDetailsData struct {
	ID int64 `json:"id"`
}

type CompletedEpicDetailsData struct {
	Quests []data.CompletedQuest `json:"quests"`
}

func (p *Player) RequestCompletedEpicDetails(msgID *string, data *RequestCompletedEpicDetailsData) error {
	log.Printf("requestCompletedEpicDetails received from %d", p.ID)
	// read from db
	quests, err := p.db.GetCompletedEpicDetails(p.ID, data.ID)
	if err != nil {
		log.Printf("Unable to get completed epic details for %d:%d (%v)", p.ID, data.ID, err)
		return p.SendError("Server Error")
	}

	// send response to player
	return p.SendMessage(msgID, completedEpicDetailsType, CompletedEpicDetailsData{Quests: quests})
}
