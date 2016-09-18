package player

import (
	"log"

	"github.com/thedarknet/daemon4/daemon/service/internal/data"
	"github.com/thedarknet/daemon4/daemon/service/internal/msg"
)

const (
	refreshInventoryType = "refreshInventory"
	inventoryType        = "inventory"
)

// Register message handlers
func init() {
	msg.MustRegister(refreshInventoryType, (*Player).RefreshInventory)
}

type RefreshInventoryData struct{}

type InventoryData struct {
	Inventory *data.Inventory `json:"inventory"`
}

func (p *Player) RefreshInventory(msgID *string, data *RefreshInventoryData) error {
	log.Printf("%s received from %d", refreshInventoryType, p.ID)

	inv, err := p.db.GetInventory(p.ID)
	if err != nil {
		log.Printf("Unable to retrieve inventory for %d (%v)", p.ID, err)
		return p.SendError("Unable to retrieve inventory")
	}
	return p.SendMessage(msgID, inventoryType, &InventoryData{Inventory: inv})
}
