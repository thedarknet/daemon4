package data

type Item struct {
	ItemType string            `json:"item_type"`
	Name     string            `json:"name"`
	Desc     string            `json:"desc"`
	Flags    int64             `json:"flags"`
	Count    int64             `json:"count"`
	MaxCount int64             `json:"max_count"`
	Metadata map[string]string `json:"metadata"`
}

type Bag struct {
	Items []*Item `json:"items"`
}

type Inventory struct {
	Bags map[string]*Bag `json:"bags"`
}
