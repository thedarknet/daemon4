package functional

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/url"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"github.com/pborman/uuid"
)

type testAccount struct {
	conn *websocket.Conn
}

type responseTest struct {
	Type string
	Data interface{}
}

type accountTest struct {
	RequestType string
	RequestData interface{}
	Response    []responseTest
}

func connectForAccount(t *testing.T, accountID int64) *testAccount {
	u, err := url.Parse(fmt.Sprintf("ws://127.0.0.1:8080/v1/player/%d", accountID))
	if err != nil {
		t.Fatalf("Unable to parse url: %v", err)
	}

	rawConn, err := net.Dial("tcp", u.Host)
	if err != nil {
		t.Fatalf("Unable to connect: %v", err)
	}

	wsHeaders := http.Header{
		"Origin": {"http://127.0.0.1:8080"},
	}

	wsConn, _, err := websocket.NewClient(rawConn, u, wsHeaders, 1024, 1024)
	if err != nil {
		t.Fatalf("Unable to create client: %v", err)
	}
	return &testAccount{conn: wsConn}
}

// Sends a message to the daemon and waits for the expected response. Discards any unknown messages in the meantime to avoid false negatives due to
// broadcasting
func (p *testAccount) VerifyRequestResponse(requestType string, requestData interface{}, responseType string, responseData interface{}) error {
	return p.VerifyRequestMultiResponse(requestType, requestData, responseTest{responseType, responseData})
}

// Sends a message to the daemon and waits for multiple responses. Discards any unknown messages in the meantime to avoid false negatives due to
// broadcasting
func (p *testAccount) VerifyRequestMultiResponse(requestType string, requestData interface{}, responses ...responseTest) error {
	id := uuid.New()

	// wait for response (up to 5s)
	deadline := time.Now().Add(5 * time.Second)
	// read the message off the connection
	p.conn.SetReadDeadline(deadline)
	p.conn.SetWriteDeadline(deadline)

	// send request
	m := outMessage{Type: requestType, ID: &id, Data: requestData}
	err := p.conn.WriteJSON(&m)
	if err != nil {
		return fmt.Errorf("Error writing data: %v", err)
	}

	encodedResponse := make([][]byte, len(responses))
	for i, r := range responses {
		// marshal responsedata for comparison
		encodedResponse[i], err = json.Marshal(r.Data)
		if err != nil {
			return fmt.Errorf("Unable to encode response data: %v", err)
		}
	}

	curResp := 0
	for {
		m2 := message{}
		err = p.conn.ReadJSON(&m2)
		if err != nil {
			return fmt.Errorf("Unable to read message: %v", err)
		}
		if m2.ID == nil || *m2.ID != id {
			log.Printf("Discarding %s message w/ id: %v", m2.Type, m2.ID)
			continue
		}
		if m2.Type != responses[curResp].Type {
			return fmt.Errorf("Unexpected response type. Expected %s got %s", responses[curResp].Type, m2.Type)
		}
		if string(encodedResponse[curResp]) != string(m2.Data) {
			return fmt.Errorf("Expected: %s.  Got: %s", string(encodedResponse[curResp]), string(m2.Data))
		}
		log.Printf("Found response %d/%d", curResp+1, len(responses))
		curResp = curResp + 1
		if curResp >= len(responses) {
			return nil
		}
	}
	return nil
}

func (p *testAccount) Disconnect() {
	p.conn.Close()
}

// RunTestFlow runs a test on all test accounts at the same time
func RunTestFlow(t *testing.T, tests []accountTest) {
	c := make(chan error)
	for _, ta := range testAccounts {
		resetTestAccount(t, ta.ID)
		a := connectForAccount(t, ta.ID)
		go func(acct *testAccount, id int64) {
			var err error
			for i, test := range tests {
				t.Logf("Test %d for %d", i, id)
				err = acct.VerifyRequestMultiResponse(test.RequestType, test.RequestData, test.Response...)
				if err != nil {
					err = fmt.Errorf("Error in test %d for account %d: (%v)", i, id, err)
					break
				}
			}
			c <- err
		}(a, ta.ID)
	}

	for range testAccounts {
		select {
		case err := <-c:
			if err != nil {
				t.Error(err)
			}
		case <-time.After(5 * time.Second):
			t.Fatalf("Test timed out after 5s")
		}
	}
}
