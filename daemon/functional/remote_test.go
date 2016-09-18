package functional

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

var TestRemoteServer *httptest.Server

type remoteRequest struct {
	AccountID   int64           `json:"account_id"`
	DisplayName string          `json:"display_name"`
	Code        string          `json:"code"`
	Lang        string          `json:"lang"`
	Inventory   remoteInventory `json:"inventory"`
}

type remoteInventory struct {
	Bags map[string]remoteBag `json:"bags"`
}

type remoteBag struct {
	Items []remoteItem `json:"items"`
}

type remoteItem struct {
	ItemType string            `json:"item_type"`
	Flags    int64             `json:"flags"`
	Count    int64             `json:"count"`
	MaxCount int64             `json:"max_count"`
	Metadata map[string]string `json:"metadata"`
}

type remoteResponse struct {
	Success  bool              `json:"success"`
	Message  string            `json:"message"`
	Inc      int64             `json:"inc"`
	Metadata map[string]string `json:"metadata"`
}

func startTestServer() {
	TestRemoteServer = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		var rr remoteRequest
		err := json.NewDecoder(req.Body).Decode(&rr)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			return
		}

		inv_count := 0
		for _, b := range rr.Inventory.Bags {
			inv_count = inv_count + len(b.Items)
		}

		p := strings.Trim(req.URL.Path, "/")
		resp := remoteResponse{
			Inc:      1,
			Metadata: map[string]string{"test_remote": p},
			Message:  fmt.Sprintf("display_name: %s, account_id: %d, code: %s, inv_item_count: %d", rr.DisplayName, rr.AccountID, rr.Code, inv_count),
		}

		switch p {
		case "ok":
			resp.Success = true
		case "fail":
			resp.Success = false
		case "noinc":
			resp.Success = true
			resp.Inc = 0
		}

		json.NewEncoder(w).Encode(&resp)
		w.WriteHeader(http.StatusOK)
	}))
}

func TestFunctional_RemoteService(t *testing.T) {
	tests := []struct {
		endpoint     string
		req          remoteRequest
		expectedResp remoteResponse
	}{
		{
			endpoint:     TestRemoteServer.URL + "/ok",
			req:          remoteRequest{AccountID: testAccounts.getID("Account1"), DisplayName: "Account1", Code: "testcode"},
			expectedResp: remoteResponse{Success: true, Message: "display_name: Account1, account_id: 1, code: testcode, inv_item_count: 0", Inc: 1, Metadata: map[string]string{"test_remote": "ok"}},
		},
		{
			endpoint:     TestRemoteServer.URL + "/fail",
			req:          remoteRequest{AccountID: testAccounts.getID("Account1"), DisplayName: "Account1", Code: "testcode"},
			expectedResp: remoteResponse{Success: false, Message: "display_name: Account1, account_id: 1, code: testcode, inv_item_count: 0", Inc: 1, Metadata: map[string]string{"test_remote": "fail"}},
		},
		{
			endpoint:     TestRemoteServer.URL + "/noinc",
			req:          remoteRequest{AccountID: testAccounts.getID("Account1"), DisplayName: "Account1", Code: "testcode"},
			expectedResp: remoteResponse{Success: true, Message: "display_name: Account1, account_id: 1, code: testcode, inv_item_count: 0", Inc: 0, Metadata: map[string]string{"test_remote": "noinc"}},
		},
	}

	for idx, tt := range tests {
		t.Logf("Starting tests %d/%d", idx+1, len(tests))

		body, _ := json.Marshal(&tt.req)

		c := http.Client{Timeout: 5 * time.Second}
		resp, err := c.Post(tt.endpoint, "application/json", bytes.NewReader(body))
		assert.Nil(t, err)

		var actualResp remoteResponse
		err = json.NewDecoder(resp.Body).Decode(&actualResp)
		assert.Nil(t, err)

		assert.Equal(t, tt.expectedResp, actualResp)

	}
}

func TestFunctional_RemoteObjective(t *testing.T) {

	tests := []accountTest{
		// Start epic w/ remote obj
		{
			RequestType: startEpicType,
			RequestData: startEpic{Code: strPtr("11remote")},
			Response: []responseTest{
				{
					Type: eventType,
					Data: epicEvent{Type: "EPIC", Action: "START", Desc: testEpics.getByName("TestIntName11_Remote").StartText, Count: 1},
				},
				{
					Type: eventType,
					Data: epicEvent{Type: "QUEST", Action: "START", Desc: testQuests.getByName("TestQuest2_Remote").StartText, Count: 1},
				},
				{
					Type: availableEpicsType,
					Data: availableEpics{Epics: testEpics.getAvailable("TestIntName1", "TestIntName2")},
				},
			},
		},
		{
			RequestType: incObjType,
			RequestData: incObj{Code: "2-1-Success"},
			Response: []responseTest{
				{
					Type: incObjSuccessType,
					Data: incObjSuccess{CurrentCount: 1, Count: 2, Desc: "Remote Text"},
				},
			},
		},
		{
			RequestType: incObjType,
			RequestData: incObj{Code: "2-1-Success"},
			Response: []responseTest{
				{
					Type: incObjSuccessType,
					Data: incObjSuccess{CurrentCount: 2, Count: 2, Desc: "Remote Text"},
				},
			},
		},
	}

	RunTestFlow(t, tests)
}
