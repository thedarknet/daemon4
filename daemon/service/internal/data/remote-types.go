package data

type RemoteRequest struct {
	AccountID   int64           `json:"account_id"`
	DisplayName string          `json:"display_name"`
	Code        string          `json:"code"`
	Lang        string          `json:"lang"`
	Inventory   RemoteInventory `json:"inventory"`
}

type RemoteInventory struct {
	Bags map[string]*RemoteBag `json:"bags"`
}

type RemoteBag struct {
	Items []*RemoteItem `json:"items"`
}

type RemoteItem struct {
	ItemType string            `json:"item_type"`
	Flags    int64             `json:"flags"`
	Count    int64             `json:"count"`
	MaxCount int64             `json:"max_count"`
	Metadata map[string]string `json:"metadata"`
}

type RemoteResponse struct {
	Success  bool              `json:"success"`
	Message  string            `json:"message"`
	Inc      int64             `json:"inc"`
	Metadata map[string]string `json:"metadata"`
}
