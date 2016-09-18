package player

import (
	"log"

	"github.com/thedarknet/daemon4/daemon/service/internal/msg"
)

// Register message handlers
func init() {
	msg.MustRegister("ping", (*Player).Ping)
}

type PingData struct {
	Token string `json:"token"`
}

func (p *Player) Ping(msgID *string, data *PingData) error {
	log.Printf("Ping %s received from %s", data.Token, p.ID)
	return p.SendMessage(msgID, "pong", data)
}
