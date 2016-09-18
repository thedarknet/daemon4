package player

import (
	"github.com/thedarknet/daemon4/daemon/service/internal/data"
)

const (
	eventType = "event"
)

func (p *Player) SendEvent(msgID *string, evt *data.Event) error {
	return p.SendMessage(msgID, eventType, evt)
}
