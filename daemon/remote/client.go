package remote

import (
	"encoding/json"
	"fmt"
	"io"
)

type Item struct {
	Type     string            `json:"item_type"`
	Flags    int64             `json:"flags"`
	Count    int64             `json:"count"`
	MaxCount int64             `json:"max_count"`
	Metadata map[string]string `json:metadata`
}

type Bag struct {
	Items []Item `json:"items"`
}

type Inventory struct {
	Bags map[string]*Bag `json:"bags"`
}

type Request struct {
	Code        string     `json:"code"`
	AccountID   int64      `json:"account_id"`
	DisplayName string     `json:"display_name"`
	Inv         *Inventory `json:"inventory"`
}

type unsafeRequest struct {
	Code        *string    `json:"code"`
	AccountID   *int64     `json:"account_id"`
	DisplayName *string    `json:"display_name"`
	Inv         *Inventory `json:"inventory"`
}

type Response struct {
	Success  bool              `json:"success"`
	Inc      int64             `json:"inc"`
	Message  string            `json:"message"`
	Metadata map[string]string `json:"metadata"`
}

func Decode(r io.Reader) (*Request, error) {
	var req unsafeRequest
	err := json.NewDecoder(r).Decode(&req)
	if err != nil {
		return nil, err
	}

	if req.Code == nil || req.AccountID == nil || req.DisplayName == nil {
		return nil, fmt.Errorf("Missing required fields. code, account_id, display_name required.")
	}

	return &Request{Code: *req.Code, AccountID: *req.AccountID, DisplayName: *req.DisplayName, Inv: req.Inv}, err
}

func (r *Response) Encode(w io.Writer) error {
	return json.NewEncoder(w).Encode(r)
}
