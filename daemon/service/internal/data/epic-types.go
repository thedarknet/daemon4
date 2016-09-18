package data

import (
	"time"
)

type AvailableEpic struct {
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

type InProgressObjective struct {
	questID      int64
	Desc         string `json:"desc"`
	CurrentCount int64  `json:"current_count"`
	Count        int64  `json:"count"`
}

type InProgressQuest struct {
	epicID     int64
	QuestID    int64                 `json:"id"`
	Name       string                `json:"name"`
	Summary    string                `json:"summary"`
	Desc       string                `json:"desc"`
	Status     string                `json:"status"`
	Objectives []InProgressObjective `json:"objectives"`
}

type InProgressEpic struct {
	epicID      int64
	Name        string            `json:"name"`
	Desc        string            `json:"desc"`
	LongDesc    string            `json:"long_desc"`
	EndTime     *time.Time        `json:"end_time,omitempty"`
	RepeatMax   int32             `json:"repeat_max"`
	RepeatCount int32             `json:"repeat_count"`
	GroupSize   int32             `json:"group_size"`
	Flags       int32             `json:"flags"`
	Quests      []InProgressQuest `json:quests"`
}

type CompletedEpic struct {
	ID           int64     `json:"id"`
	Name         string    `json:"name"`
	Desc         string    `json:"desc"`
	LongDesc     string    `json:"long_desc"`
	GroupSize    int64     `json:"group_size"`
	Flags        int64     `json:"flags"`
	Status       string    `json:"status"`
	CompleteTime time.Time `json:"complete_time"`
}

type CompletedQuest struct {
	Name         string     `json:"name"`
	Summary      string     `json:"summary"`
	Desc         string     `json:"desc"`
	Status       string     `json:"status"`
	Modality     string     `json:"modality"`
	CompleteTime *time.Time `json:"complete_time"`
}

type IncObjResult struct {
	CurrentCount int64  `json:"current_count"`
	Count        int64  `json:"count"`
	Desc         string `json:"desc"`
}

type Event struct {
	Type   string `json:"type"`
	Action string `json:"action"`
	Desc   string `json:"desc"`
	Count  int64  `json:"count"`
}
