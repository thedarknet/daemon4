package msg

import (
	"encoding/json"
	"fmt"
	"log"
	"reflect"
	"sync"
)

var (
	// mapping of message type to handler
	handlers map[string]handler = make(map[string]handler)
	// ensure handlers map only gets created once
	handlerCreator sync.Once

	// list of online players
	onlinePlayers map[int64]internalPlayer = make(map[int64]internalPlayer)
	// mutex to guard access to onlinePlayers
	onlinePlayersMux sync.RWMutex
)

// Register installs a handler for a specific message type. The handlerFunc
// should be a pointer to a function of the signature func(*string, *T) error.
// The first arg (ptr) will be the receiver object. The second (string) will be the
// msg id set by the sender. The third, T, is hen type the message data should
// be decoded into.
//
// All functions must be registered before Process is called
func Register(msgType string, handlerFunc interface{}) error {
	// validate the handlerFunc
	ft := reflect.TypeOf(handlerFunc)

	// Ensure it is a function
	if ft.Kind() != reflect.Func {
		return fmt.Errorf("Expected handlerFunc to be (*T).func(string,*T) error. Got (%T)", handlerFunc)
	}

	if ft.NumIn() != 3 || ft.NumOut() != 1 {
		return fmt.Errorf("Expected function with three inputs and one output. Got %d inputs %d outputs", ft.NumIn(), ft.NumOut())
	}

	if ft.In(0).Kind() != reflect.Ptr || ft.In(1).Kind() != reflect.Ptr || ft.In(2).Kind() != reflect.Ptr {
		return fmt.Errorf("Inputs must be type ptr, ptr, ptr. Got %v, %v, %v", ft.In(0).Kind(), ft.In(1).Kind(), ft.In(2).Kind())
	}

	if ft.Out(0).Kind() != reflect.Interface || ft.Out(0).Name() != "error" {
		return fmt.Errorf("Output must be type interface,error. Got %v,%s", ft.Out(0).Kind(), ft.Out(0).Name)
	}

	// save the type of the 3rd arg so it can be created and unmarshaled into
	handlers[msgType] = handler{reflect.ValueOf(handlerFunc), ft.In(2).Elem()}
	return nil
}

// MustRegister calls Register and panics on error. Use for registering handlers in init functions
func MustRegister(msgType string, handlerFunc interface{}) {
	err := Register(msgType, handlerFunc)
	if err != nil {
		panic(err)
	}
}

// Process is a blocking call that reads and dispatches
// messages until the connection returns EOF or the cancel channel is triggered.
func Process(playerObject Player, conn PlayerConnection, cancel chan bool) error {
	err := addOnlinePlayer(playerObject, conn, cancel)
	if err != nil {
		if err == ErrPlayerOnline {
			// try to replace player
			onlinePlayer, err := getOnlinePlayer(playerObject.GetID())
			if err == nil && onlinePlayer.playerObject != nil {
				removeOnlinePlayer(onlinePlayer.playerObject)
			}
			err = addOnlinePlayer(playerObject, conn, cancel)
			if err != nil {
				return err
			}
		}
	}
	defer removeOnlinePlayer(playerObject)

	m := message{}
	// process messages until cancelled
	for {
		select {
		case <-cancel:
			log.Printf("Processing cancelled for %d", playerObject.GetID())
			return ErrCancelled
		default:
			// read the message off the connection
			err = conn.ReadJSON(&m)
			if err != nil {
				return err
			}
			// dispatch message to handlers, bubble up any errors
			err = dispatchMessage(playerObject, &m)
			if err != nil {
				return err
			}
		}
	}
}

// SendMessage sends a message to a specific online player
func SendMessage(playerID int64, msgID *string, msgType string, data interface{}) error {
	p, err := getOnlinePlayer(playerID)
	if err != nil {
		return err
	}

	// Set up outgoing message
	m := outMessage{Type: msgType, ID: msgID, Data: data}

	// Lock connection and send message
	p.sendMux.Lock()
	defer p.sendMux.Unlock()
	return p.connection.WriteJSON(m)
}

// SendError sends an error message and closes the connection
func SendError(playerID int64, message string) error {
	p, err := getOnlinePlayer(playerID)
	if err == nil {
		err = SendMessage(playerID, nil, "error", ErrorData{Message: message})
		close(p.cancel)
	}
	return err
}

// BroadcastMessage sends a message to all online players
func BroadcastMessage(msgType string, data interface{}) {
	plist := getOnlinePlayerList()

	for _, playerID := range plist {
		SendMessage(playerID, nil, msgType, data)
	}
}

// dispatchMessage decodes and dispatches messages to the appropriate
// handlers registered for each message type
func dispatchMessage(playerObject Player, m *message) error {
	handler, ok := handlers[m.Type]
	// don't consider no handler an error
	if !ok {
		log.Printf("No handler for %s (%d)", m.Type, playerObject.GetID())
		return nil
	}

	// Create a value to deserialize into
	data := reflect.New(handler.DataType).Interface()
	err := json.Unmarshal(m.Data, data)
	if err != nil {
		return err
	}

	// call handler and extract error
	res := handler.HandlerFunc.Call([]reflect.Value{reflect.ValueOf(playerObject), reflect.ValueOf(m.ID), reflect.ValueOf(data)})
	if res[0].Interface() != nil {
		return res[0].Interface().(error)
	}
	return nil
}

// Maintain online players list
func addOnlinePlayer(playerObject Player, conn PlayerConnection, cancel chan bool) error {
	onlinePlayersMux.Lock()
	defer onlinePlayersMux.Unlock()
	// ensure player is not already being processed
	if _, ok := onlinePlayers[playerObject.GetID()]; ok {
		return ErrPlayerOnline
	}
	onlinePlayers[playerObject.GetID()] = internalPlayer{connection: conn, playerObject: playerObject, cancel: cancel}
	err := playerObject.Init()
	if err != nil {
		log.Printf("Error initing player %d (%v)", playerObject.GetID(), err)
		return err
	}
	log.Printf("Player %d is now online", playerObject.GetID())
	return nil
}

func removeOnlinePlayer(playerObject Player) {
	onlinePlayersMux.Lock()
	defer onlinePlayersMux.Unlock()

	// only disconnect if it is for the active session to allow replacing the player with a new connection
	if p, ok := onlinePlayers[playerObject.GetID()]; ok {
		if p.playerObject.GetSessionID() == playerObject.GetSessionID() {
			playerObject.Shutdown()
			p.connection.Close()
			delete(onlinePlayers, playerObject.GetID())
			log.Printf("Player %d is now offline", playerObject.GetID())
		}
	}
}

func getOnlinePlayer(playerID int64) (internalPlayer, error) {
	onlinePlayersMux.RLock()
	defer onlinePlayersMux.RUnlock()

	if p, ok := onlinePlayers[playerID]; ok {
		return p, nil
	}
	return internalPlayer{}, ErrPlayerOffline
}

func getOnlinePlayerList() []int64 {
	onlinePlayersMux.RLock()
	defer onlinePlayersMux.RUnlock()

	// create list of players to send to
	plist := make([]int64, 0, len(onlinePlayers))
	for id := range onlinePlayers {
		plist = append(plist, id)
	}
	return plist
}
