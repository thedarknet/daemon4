package functional

var testQuests questList = questList{
	{
		InternalName: "TestQuest1",
		Name:         "Test Quest 1",
		StartText:    "Start Test Quest 1",
		SuccessText:  "Complete Test Quest 1",
		FailText:     "Fail Test Quest 1",
		SummaryText:  "Test Quest 1 Summary",
		Language:     "en",
		Objectives: []objective{
			{
				Type:            "TEXT",
				Index:           1,
				Count:           1,
				Description:     "1-1-Text",
				ActivationRegex: strPtr("1-1-Success"),
				FailRegex:       strPtr("1-1-Fail"),
				Reward:          strPtr("RewardSimple"),
			},
		},
	},
	{
		InternalName: "TestQuest2_Remote",
		Name:         "Test Quest 2 Remote",
		StartText:    "Start Test Quest 2 Remote",
		SuccessText:  "Complete Test Quest 2 Remote",
		FailText:     "Fail Test Quest 2 Remote",
		SummaryText:  "Test Quest 2 Summary Remote",
		Language:     "en",
		Objectives: []objective{
			{
				Type:            "REMOTE",
				Index:           1,
				Count:           2,
				Description:     "Remote Text",
				ActivationRegex: strPtr("2-1-Success"),
				Reward:          strPtr("RewardSimple2"),
				RemoteEndpoint:  strPtr("/ok"),
			},
		},
	},
	{
		InternalName: "TestQuest3",
		Name:         "Test Quest 3",
		StartText:    "Start Test Quest 3",
		SuccessText:  "Complete Test Quest 3",
		FailText:     "Fail Test Quest 3",
		SummaryText:  "Test Quest 3 Summary",
		Language:     "en",
		Objectives: []objective{
			{
				Type:            "TEXT",
				Index:           1,
				Count:           1,
				Description:     "3-1-Text",
				ActivationRegex: strPtr("3-1-Success"),
				FailRegex:       strPtr("3-1-Fail"),
			},
			{
				Type:            "TEXT",
				Index:           2,
				Count:           2,
				Description:     "3-2-Text",
				ActivationRegex: strPtr("3-2-Success"),
				FailRegex:       strPtr("3-2-Fail"),
			},
		},
	},
	{
		InternalName: "TestQuest4",
		Name:         "Test Quest 4",
		StartText:    "Start Test Quest 4",
		SuccessText:  "Complete Test Quest 4",
		FailText:     "Fail Test Quest 4",
		SummaryText:  "Test Quest 4 Summary",
		Language:     "en",
		Objectives: []objective{
			{
				Type:            "TEXT",
				Index:           1,
				Count:           1,
				Description:     "4-1-Text",
				ActivationRegex: strPtr("4-1-Success"),
				FailRegex:       strPtr("4-1-Fail"),
			},
			{
				Type:            "TEXT",
				Index:           2,
				Count:           2,
				Description:     "4-2-Text",
				ActivationRegex: strPtr("4-2-Success"),
				FailRegex:       strPtr("4-2-Fail"),
			},
			{
				Type:            "TEXT",
				Index:           2,
				Count:           3,
				Description:     "4-2-Text",
				ActivationRegex: strPtr("4-3-Success"),
				FailRegex:       strPtr("4-3-Fail"),
			},
		},
	},
	{
		InternalName: "TestQuest5",
		Name:         "Test Quest 5",
		StartText:    "Start Test Quest 5",
		SuccessText:  "Complete Test Quest 5",
		FailText:     "Fail Test Quest 5",
		SummaryText:  "Test Quest 5 Summary",
		Language:     "en",
	},
	{
		InternalName: "TestQuest6",
		Name:         "Test Quest 6",
		StartText:    "Start Test Quest 6",
		SuccessText:  "Complete Test Quest 6",
		FailText:     "Fail Test Quest 6",
		SummaryText:  "Test Quest 6 Summary",
		Language:     "en",
	},
	{
		InternalName: "TestQuest7",
		Name:         "Test Quest 7",
		StartText:    "Start Test Quest 7",
		SuccessText:  "Complete Test Quest 7",
		FailText:     "Fail Test Quest 7",
		SummaryText:  "Test Quest 7 Summary",
		Language:     "en",
	},
	{
		InternalName: "TestQuest8",
		Name:         "Test Quest 8",
		StartText:    "Start Test Quest 8",
		SuccessText:  "Complete Test Quest 8",
		FailText:     "Fail Test Quest 8",
		SummaryText:  "Test Quest 8 Summary",
		Language:     "en",
	},
}