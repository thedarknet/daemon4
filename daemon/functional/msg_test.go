package functional

import (
	"encoding/json"
)

type message struct {
	Type string          `json:"type"`
	ID   *string         `json:"id",omitempty`
	Data json.RawMessage `json:data"`
}

type outMessage struct {
	Type string      `json:"type"`
	ID   *string     `json:"id,omitempty"`
	Data interface{} `json:data"`
}
