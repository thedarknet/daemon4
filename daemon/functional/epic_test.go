package functional

import (
	"testing"
	"time"
)

const (
	refreshAvailablEpicsType   = "refreshAvailableEpics"
	availableEpicsType         = "availableEpics"
	startEpicType              = "startEpic"
	startEpicFailedType        = "startEpicFailed"
	refreshInProgressEpicsType = "refreshInProgressEpics"
	inProgressEpicsType        = "inProgressEpics"
	incObjType                 = "incObj"
	incObjSuccessType          = "incObjSuccess"
	eventType                  = "event"
)

type availableEpic struct {
	ID          int64      `json:"id"`
	Name        string     `json:"name"`
	Desc        string     `json:"desc"`
	LongDesc    string     `json:"long_desc"`
	EndTime     *time.Time `json:"end_time,omitempty"`
	RepeatMax   int32      `json:"repeat_max"`
	RepeatCount int32      `json:"repeat_count"`
	GroupSize   int32      `json:"group_size"`
	Flags       int32      `json:"flags"`
}

type availableEpics struct {
	Epics []availableEpic `json:"epics"`
}

type startEpic struct {
	EpicID *int64  `json:"epic_id,omitempty"`
	Code   *string `json:"code,omitempty"`
}

type startEpicFailed struct {
	Reason string `json:"reason"`
}

type inProgressObjective struct {
	Desc         string `json:"desc"`
	CurrentCount int64  `json:"current_count"`
	Count        int64  `json:"count"`
}

type inProgressQuest struct {
	Name       string                `json:"name"`
	Summary    string                `json:"summary"`
	Desc       string                `json:"desc"`
	Status     string                `json:"status"`
	Objectives []inProgressObjective `json:"objectives"`
}

type inProgressEpic struct {
	Name        string            `json:"name"`
	Desc        string            `json:"desc"`
	LongDesc    string            `json:"long_desc"`
	EndTime     *time.Time        `json:"end_time,omitempty"`
	RepeatMax   int32             `json:"repeat_max"`
	RepeatCount int32             `json:"repeat_count"`
	GroupSize   int32             `json:"group_size"`
	Flags       int32             `json:"flags"`
	Quests      []inProgressQuest `json:quests"`
}

type inProgressEpics struct {
	Epics []inProgressEpic `json:"epics"`
}

type epicEvent struct {
	Type   string `json:"type"`
	Action string `json:"action"`
	Desc   string `json:"desc"`
	Count  int64  `json:"count"`
}

type incObj struct {
	Code string `json:"code"`
}

type incObjSuccess struct {
	CurrentCount int64  `json:"current_count"`
	Count        int64  `json:"count"`
	Desc         string `json:"desc"`
}

func TestFunctional_EpicInitial(t *testing.T) {
	tests := []accountTest{
		{
			RequestType: refreshAvailablEpicsType,
			Response: []responseTest{
				{
					Type: availableEpicsType,
					Data: availableEpics{Epics: testEpics.getAvailable("TestIntName1", "TestIntName2")},
				},
			},
		},
	}

	RunTestFlow(t, tests)
}

func TestFunctional_StartEpic(t *testing.T) {

	tests := []accountTest{
		// epic w/ deps
		{
			RequestType: startEpicType,
			RequestData: startEpic{EpicID: testEpics.getIDPtr("TestIntName3")},
			Response:    []responseTest{{startEpicFailedType, startEpicFailed{Reason: "NOT_AVAILABLE"}}},
		},
		// non-existent
		{
			RequestType: startEpicType,
			RequestData: startEpic{EpicID: intPtr(9999999999)},
			Response:    []responseTest{{startEpicFailedType, startEpicFailed{Reason: "NOT_AVAILABLE"}}},
		},
		// test1
		{
			RequestType: startEpicType,
			RequestData: startEpic{EpicID: testEpics.getIDPtr("TestIntName1")},
			Response: []responseTest{
				{
					Type: eventType,
					Data: epicEvent{Type: "EPIC", Action: "START", Desc: testEpics.getByName("TestIntName1").StartText, Count: 1},
				},
				{
					Type: eventType,
					Data: epicEvent{Type: "QUEST", Action: "START", Desc: testQuests.getByName("TestQuest1").StartText, Count: 1},
				},
				{
					Type: availableEpicsType,
					Data: availableEpics{Epics: testEpics.getAvailable("TestIntName2")},
				},
			},
		},
		// test1 in progress
		{
			RequestType: startEpicType,
			RequestData: startEpic{EpicID: testEpics.getIDPtr("TestIntName1")},
			Response:    []responseTest{{startEpicFailedType, startEpicFailed{Reason: "IN_PROGRESS"}}},
		},
		// activate with code
		{
			RequestType: startEpicType,
			RequestData: startEpic{Code: strPtr("testActivate")},
			Response: []responseTest{
				{
					Type: eventType,
					Data: epicEvent{Type: "EPIC", Action: "START", Desc: testEpics.getByName("TestIntName5").StartText, Count: 1},
				},
				{
					Type: eventType,
					Data: epicEvent{Type: "EPIC", Action: "START", Desc: testEpics.getByName("TestIntName9").StartText, Count: 1},
				},
				{
					Type: availableEpicsType,
					Data: availableEpics{Epics: testEpics.getAvailable("TestIntName2")},
				},
			},
		},
		// activate with code again
		{
			RequestType: startEpicType,
			RequestData: startEpic{Code: strPtr("testActivate")},
			Response:    []responseTest{{startEpicFailedType, startEpicFailed{Reason: "NOT_AVAILABLE"}}},
		},
		// activate with invalid code
		{
			RequestType: startEpicType,
			RequestData: startEpic{Code: strPtr("foobar")},
			Response:    []responseTest{{startEpicFailedType, startEpicFailed{Reason: "NOT_AVAILABLE"}}},
		},
	}

	RunTestFlow(t, tests)
}

func TestFunctional_CompleteSimpleEpic(t *testing.T) {
	tests := []accountTest{
		{
			RequestType: startEpicType,
			RequestData: startEpic{EpicID: testEpics.getIDPtr("TestIntName1")},
			Response: []responseTest{
				{
					Type: eventType,
					Data: epicEvent{Type: "EPIC", Action: "START", Desc: testEpics.getByName("TestIntName1").StartText, Count: 1},
				},
				{
					Type: eventType,
					Data: epicEvent{Type: "QUEST", Action: "START", Desc: testQuests.getByName("TestQuest1").StartText, Count: 1},
				},
				{
					Type: availableEpicsType,
					Data: availableEpics{Epics: testEpics.getAvailable("TestIntName2")},
				},
				{
					Type: inProgressEpicsType,
					Data: inProgressEpics{Epics: []inProgressEpic{testEpics.getInProgress("TestIntName1", 0, 0, testQuests, nil)}},
				},
			},
		},
	}

	RunTestFlow(t, tests)
}
