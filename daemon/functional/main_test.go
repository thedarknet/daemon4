package functional

import (
	"database/sql"
	"fmt"
	"log"
	"math"
	"os"
	"testing"
	"time"

	"github.com/thedarknet/daemon4/daemon/service"
)

/*
Test Data Setup

Quest1 -> 1 Text Objective
Quest2 -> 1 Text Objective w/ same success and fail as Quest1
Quest3 -> 2 Text Objective
Quest4 -> 3 Text Objective
Quest5 -> 1 Text + 1 Key Objective
Quest6 -> 1 Text + 1 Dynamic Key Objective
Quest7 -> 1 Text Objective - no Reward
Quest8 -> 1 Text Objective + 1 Remote Objective

Epic1 -> Simple Epic containing only Quest1

*/

var NegativeInfinityTS = time.Date(math.MinInt32, time.January, 1, 0, 0, 0, 0, time.UTC)
var PositiveInfinityTS = time.Date(math.MaxInt32, time.December, 31, 23, 59, 59, 1e9-1, time.UTC)

func getPostgresqlConnection() string {
	return fmt.Sprintf("postgres://%s:%s@%s/%s?sslmode=disable", os.Getenv("POSTGRESQL_SERVICE_USER"), os.Getenv("POSTGRESQL_SERVICE_PASSWORD"), os.Getenv("POSTGRESQL_SERVICE_HOST"), os.Getenv("POSTGRESQL_SERVICE_DB"))
}

func getDB() (*sql.DB, error) {
	return sql.Open("postgres", getPostgresqlConnection())
}

func installTestData() {

	db, err := getDB()
	if err != nil {
		log.Fatalf("Unable to open db: %v", err)
	}

	// create test accounts
	for i := range testAccounts {
		err := upsertAccount(db, &testAccounts[i])
		if err != nil {
			log.Fatalf("Unable to create account %d (%v)", i, err)
		}
		err = resetAccount(db, testAccounts[i].ID)
		if err != nil {
			log.Fatalf("Unable to reset account %d (%v)", i, err)
		}
	}

	// create test items
	for i := range testItems {
		err := upsertItem(db, &testItems[i])
		if err != nil {
			log.Fatalf("Unable to install item %d (%v)", i, err)
		}
	}

	// create rewards
	for i := range testRewards {
		err := upsertReward(db, testItems, &testRewards[i])
		if err != nil {
			log.Fatalf("Unable to install reward %d (%v)", i, err)
		}
	}

	// create test epics
	for i := range testEpics {
		err := upsertEpic(db, &testEpics[i])
		if err != nil {
			log.Fatalf("Unable to install epic %d (%v)", i, err)
		}
	}

	// set up required epics
	for _, re := range testRequiredEpics {
		// find id of main epic
		var epicID int64
		for _, e := range testEpics {
			if e.InternalName == re.InternalName {
				epicID = e.ID
			}
		}
		// find all requires
		for _, req := range re.RequiredEpicNames {
			for _, e := range testEpics {
				if e.InternalName == req {
					err := setRequiredEpic(db, epicID, e.ID)
					if err != nil {
						log.Fatalf("Unable to set required epic %d,%d (%v)", epicID, e.ID, err)
					}
				}
			}
		}
	}

	// create quests
	for i := range testQuests {
		err := upsertQuest(db, &testQuests[i], testRewards)
		if err != nil {
			log.Fatalf("Unable to install quest %d (%v)", i, err)
		}
	}

	// setup quest map
	for i := range testEpics {
		err := setupQuestMap(db, &testEpics[i])
		if err != nil {
			log.Fatalf("Unable to install quest map %d (%v)", i, err)
		}
	}

	// clean up data
	/*	for i := range testAccounts {
		err := resetAccount(db, testAccounts[i].ID)
		if err != nil {
			log.Fatalf("Unable to reset account %d (%v)", i, err)
		}
	} */
}

func TestMain(m *testing.M) {
	startTestServer()
	defer TestRemoteServer.Close()
	installTestData()

	go service.ListenAndServe(getPostgresqlConnection())
	time.Sleep(1 * time.Second)
	os.Exit(m.Run())
}
