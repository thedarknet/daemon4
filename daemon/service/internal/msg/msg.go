package msg

import (
	"encoding/json"
	"reflect"
	"sync"
)

// incoming message
type message struct {
	Type string          `json:"type"`
	ID   *string         `json:"id,omitempty"`
	Data json.RawMessage `json:data"`
}

// outgoing message
type outMessage struct {
	Type string      `json:"type"`
	ID   *string     `json:"id,omitempty"`
	Data interface{} `json:"data"`
}

type handler struct {
	HandlerFunc reflect.Value
	DataType    reflect.Type
}

type internalPlayer struct {
	connection   PlayerConnection
	playerObject Player
	sendMux      sync.Mutex
	cancel       chan bool
}

type PlayerConnection interface {
	ReadJSON(v interface{}) error
	WriteJSON(v interface{}) error
	Close() error
}

type Player interface {
	GetID() int64
	GetSessionID() string
	Init() error
	Shutdown()
}

type ErrorData struct {
	Message string `json:"message"`
}
