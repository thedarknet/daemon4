package player

import (
	"time"

	"github.com/pborman/uuid"

	"github.com/thedarknet/daemon4/daemon/service/internal/data"
	"github.com/thedarknet/daemon4/daemon/service/internal/msg"
)

const (
	DefaultRefreshTime = 5 * time.Minute
)

type Player struct {
	ID           int64
	db           data.Database
	shutdownChan chan<- bool
	sessionID    string
}

// New sets up a new player when a connection is made
func New(db data.Database, id int64) *Player {
	return &Player{db: db, ID: id, sessionID: uuid.New()}
}

// GetID returns the player id
func (p *Player) GetID() int64 {
	return p.ID
}

// GetSessionID returns a unique session ID for this player in this session
func (p *Player) GetSessionID() string {
	return p.sessionID
}

// Init is called when the player comes online
func (p *Player) Init() error {
	p.startRefreshTimer()
	return nil
}

// Shutdown is called when the player goes offline
func (p *Player) Shutdown() {
	p.stopRefreshTimer()
}

// Refresh is called on a timer to syncronize state to the client
func (p *Player) Refresh() {
	p.sendAvailableEpics(nil)
}

// SendMessage sends a json message to the current player's connection
// if they are online
func (p *Player) SendMessage(msgID *string, msgType string, data interface{}) error {
	return msg.SendMessage(p.ID, msgID, msgType, data)
}

// SendError sends an error to the player and disconnects their session
func (p *Player) SendError(message string) error {
	return msg.SendError(p.GetID(), message)
}

// startRefreshTimer sets up a periodic timer to push an update to syncronize a player's state
func (p *Player) startRefreshTimer() {
	c := make(chan bool)
	go func() {

		select {
		case <-c:
			return
		case <-time.Tick(DefaultRefreshTime):
			p.Refresh()
		}
	}()
	p.shutdownChan = c
}

// stopRefreshTimer cancels the periodic state refresh
func (p *Player) stopRefreshTimer() {
	close(p.shutdownChan)
}
