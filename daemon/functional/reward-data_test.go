package functional

import (
	"database/sql"
)

var testRewards rewardList = rewardList{
	{
		InternalName: "RewardSimple",
		Items: []rewardItem{
			{
				InternalName: "Item1",
				Count:        1,
			},
			{
				InternalName: "Item2",
				Count:        1,
			},
		},
	},
	{
		InternalName: "RewardSimple2",
		Items: []rewardItem{
			{
				InternalName: "Item3",
				Count:        1,
			},
		},
	},
	{
		InternalName: "RewardWithGlobal",
		Items: []rewardItem{
			{
				InternalName: "Item1",
				Count:        1,
			},
			{
				InternalName: "GlobalItem1",
				Count:        1,
			},
		},
	},
	{
		InternalName: "RewardMultiBag",
		Items: []rewardItem{
			{
				InternalName: "Item1",
				Count:        1,
			},
			{
				InternalName: "Currency1",
				Count:        100,
			},
			{
				InternalName: "Skill1",
				Count:        100,
			},
		},
	},
	{
		InternalName: "RewardMultiBagWithGlobal",
		Items: []rewardItem{
			{
				InternalName: "Item1",
				Count:        1,
			},
			{
				InternalName: "Item2",
				Count:        1,
			},
			{
				InternalName: "Currency1",
				Count:        100,
			},
			{
				InternalName: "Skill1",
				Count:        100,
			},
			{
				InternalName: "GlobalItem1",
				Count:        300,
			},
			{
				InternalName: "GlobalSkill1",
				Count:        100,
			},
			{
				InternalName: "XP",
				Count:        5000,
			},
		},
	},
	{
		InternalName: "RewardOverflow",
		Items: []rewardItem{
			{
				InternalName: "Item1",
				Count:        500,
			},
		},
	},
}

type rewardItem struct {
	InternalName string
	Count        int64
}

type reward struct {
	ID           int64
	InternalName string
	Items        []rewardItem
}

type rewardList []reward

func (rl rewardList) getByName(name string) *reward {
	for _, r := range rl {
		if r.InternalName == name {
			return &r
		}
	}
	return nil
}

func (rl rewardList) getID(name string) int64 {
	r := rl.getByName(name)
	if r == nil {
		return 0
	}
	return r.ID
}

func upsertReward(db *sql.DB, items itemList, r *reward) error {
	row := db.QueryRow("select * from static.reward_upsert($1)",
		r.InternalName)

	err := row.Scan(&r.ID)
	if err != nil {
		return err
	}

	// add all items
	_, err = db.Exec("select * from static.reward_item_detail_delete_by_reward($1)",
		r.ID)

	if err != nil {
		return err
	}

	for _, item := range r.Items {
		id := items.getID(item.InternalName)
		_, err = db.Exec("select * from static.reward_item_detail_upsert($1, $2, $3)",
			r.ID,
			id,
			item.Count)
		if err != nil {
			return err
		}
	}

	return nil
}
