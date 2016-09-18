# Websocket Protocol

The client site communicates with the daemon via a persistent websocket connection.

All messages are plain json in the following format:

```json
{
  "type": "xxxx",
  "id": "yyyyy",
  "data": {
    ....
  }
}
```

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| type | string | The message type dictates the contents of the data |
| id | string | Correlation id for the message (optional). Used to correlate requests with their corresponding response |
| data | dictionary | Message data that varies depending on the message type. See the message definition for details |

## Events
At any time, the server may send an event message to indicate that an epic or quest has been started, completed, or failed.  Events are also sent when inventory has been modified.

**type**: event

### Data

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| type | string | Type of object that has changed. EPIC, QUEST, ITEM |
| action | string | How the object has changed. START, SUCCESS, FAIL for epics and quests or RECEIVE, USE for items |
| desc | string | Description to display for this event, i.e. the start_text from the epic/quest or item desc |
| count | int | Number of times this action occured |


## Refresh Unstarted Epics

Update the list and status of all eligible (but unstarted) epics. This is generally not required as the daemon will push updates on a regular basis. The daemon will respond with a [availableEpics](#available-epics) message.

**type**: refreshAvailableEpics

### Data
None

## Available Epics Update

Information on all public epics that a player has not yet started. This may include epics that the player is not yet eligible for if they are set to public. The epic list will NOT include any of the following:
* Epics set to private (need a secret activation code)
* Epics that have not passed their start time
* Epics from events that are not yet or no longer active
* Epics that have other epics that must be completed first

**type**: availableEpics

### Data

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| epics | array of epic | Information on all public epics that the player has not started |

#### Epic

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| id | int | ID of epic. Used when activating or starting the epic |
| name | string | Localized name of epic |
| desc | string | Localized description of epic |
| long_desc | string | Localized long description of epic, generally displayed when the player asks for more information |
| end_time | string | Time this epic expires in RFC3339 format, may be null if epic never expires |
| repeat_max | int | How many times this epic can be repeated |
| repeat_count | int | How many times this player has completed this epic |
| group_size | int | Recommended group size for epic |
| flags | int | Flags set by static data/quest editor. Flags are considered opaque to the daemon are just saved and returned as-is |

## Start Epic
Activate a specific epic by id or by secret code. If the epic is publically visible the id can be found in the publicEpics message. If the epic is started successfully updated publicEpics and inprogressEpics messages will be sent. If the epic cannot be started, a startEpicFailed message will be sent instead.

**type**: startEpic

### Data

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| id | int | Epic id to activate (optional) |
| code | string | Code to activate a secret epic (optional)

## Start Epic Failed
Sent by the daemon when an epic cannot be started.

**type**: startEpicFailed

### Data

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| reason | string | Reason the epic could not be activated to be shown on the UI |

## Refresh In-progress Epics
Sent from the client to request an updated list of all epics that the player is currently working on. This includes all epics with incomplete quests.

**type**: refreshInProgressEpics

###Data
None

## In-progress Epics Update
Information about all epics that a player is currently on. This includes any epic with an open or in progress quest.

**type**: inprogressEpics

### Data
| Name | Data Type | Description |
|:----:|:---------:|-------------|
| epics | array of epic | Information on all public epics that the player has not started |

#### Epic

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| id | int | ID of epic. Used when activating or starting the epic |
| name | string | Localized name of epic |
| desc | string | Localized in-progress description of epic |
| long_desc | string | Localized long description of epic, generally displayed when the player asks for more information |
| end_time | string | Time this epic expires in RFC3339 format, may be null if epic never expires |
| repeat_max | int | How many times this epic can be repeated |
| repeat_count | int | How many times this player has completed this epic |
| group_size | int | Recommended group size for epic |
| flags | int | Flags set by static data/quest editor. Flags are considered opaque to the daemon are just saved and returned as-is |
| quests | array of quest | Information on all quests that are completed or in progress in this epic |

#### Quest
| Name | Data Type | Description |
|:----:|:---------:|-------------|
| id | int64 | Live quest id, unique per player  per quest |
| name | string | Localized name of quest |
| summary | string | Localized summary of quest (summary text) |
| desc | string | Localized description of quest. Could be start, complete, or fail text depending on status |
| status | string | Status of quest, one of IN_PROGRESS, SUCCESS, FAILED |
| objectives | array of objective | All objectives for this quest |
| rewards | array of rewards | Reward for completing this quest |

#### Objective

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| desc | string | Localized description of objective |
| current_count | int | Number of times objective has been activated |
| count | int | Number of times objective must be activated to complete |
| rewards | array of rewards | Reward for completing objective |

#### Reward

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| name | string | Localized item name |
| count | int | Number of items granted by the reward |

## Advance Objective
Attempts to advance an objective. When an objective is advanced enough that it meets the required count, it will be automatically completed. Quests will be automatically completed once all objectives are completed, and epics will complete once the appropriate quests are completed.

**type**: incObj

### Data

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| code | string | "Answer" for the objective.  This is generally a player-entered string providing a solution or answer to the question in the objective. This string may be a simple key or it may be sent to an external service for validation |


## Advance Objective Failed
Unable to advance the objective. Use for feedback to the player.

**type**: incObjError

### Data

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| type | string | Reason for failure. SERVER_ERROR (unknown error, server failed), INVALID_CODE (code did not match any objectives)

## Objective Advanced
Objective has been advanced. Use to update the player UI.

**type**: incObjSuccess

### Data

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| current_count | int | Current progress on the objective |
| count | int | Max count for the objective |
| desc | string | Description of the objective |

## Refresh Completed Epics
Sent from the client to request an updated list of all epics that the player has completed.

**type**: refreshCompletedEpics

###Data
None

## Completed Epics Update
Returns basic information on all the epics the player has completed or failed. Only epic level data is returnedm use completedEpicDetails to drill down and get quest data for an epic.

**type**: completedEpics

### Data
| Name | Data Type | Description |
|:----:|:---------:|-------------|
| epics | array of epic | Information on all epics that a player has completed or failed |

#### Epic

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| id | int | ID of epic. Used when fetching the epic details. |
| name | string | Localized name of epic |
| desc | string | Localized summary text of the epic |
| long_desc | string | Localized long description of epic, generally displayed when the player asks for more information |
| group_size | int | Recommended group size for epic |
| flags | int | Flags set by static data/quest editor. Flags are considered opaque to the daemon are just saved and returned as-is |
| status |string | How the epic was completed. 'SUCCESS' or 'FAIL' |
| complete_time | string | RFC3339 timestamp with the time the epic entered a completed state |

## Request Completed Epic Details
Sent from the client to request the details for a specific completed epic.

**type** requestCompletedEpicDetails

###Data

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| id | int | Specifies which epic instance ID to return details for. This id is included in the completed epics update message. |

## Completed Epic Details
Sends down addition information about a completed epic (drilldown).

**type** completedEpicDetails

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| quests | array of quests | All quests and their status. | 

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| name | string | Localized name of quest |
| summary | string | Localized summary of quest |
| desc | string | Description of quest. Will be the start/complte/fail text depending on status |
| status | string | Completion status (SUCCESS, FAIL, INCOMPLETE) |
| modality | string | Modality of quest (MANDATORY, OPTIONAL) |
| complete_time | string | RFC3339 timestamp of completion time (may be null if quest was never completed) |

## Refresh Inventory
Sent from the client to request an upated view of the player's inventory.

**type**: refreshInventory

### Data
None

## Inventory
Sent from the server to refresh the view of the player's inventory

**type**: inventory



### Data

| Name | Data Type | Description |
|:----:|:---------:|-------------|
| inventory | dictionary | Inventory object | 

#### Inventory
| Name | Data Type | Description |
|:----:|:---------:|-------------|
| bags | dictionary | Map of bag type to bag data |

#### Bag
| Name | Data Type | Description |
|:----:|:---------:|-------------|
| items | array | List of items in the bag |

#### Item
| Name | Data Type | Description |
|:----:|:---------:|-------------|
| item_type | string | Internal name of item (for icon lookup / sorting) |
| name | string | Item display name |
| desc | string | Item description |
| flags | int | Item flags |
| count | int | Number of items of this type the player currently owns |
| max_count | int | Maximum number of this item a player can own |
| metadata | dictionary | Name-value pairs that hold extra item data |

### Example Data
```
{

	"inventory": {
		"bags": {
			"ITEM": {
				"items": [{
					"item_type": "Item1",
					"name": "Item 1",
					"desc": "Item 1 Desc",
					"flags": 0,
					"count": 1,
					"max_count": 100,
					"metadata": null
				}, {
					"item_type": "Item2",
					"name": "Item 2",
					"desc": "Item 2 Desc",
					"flags": 0,
					"count": 1,
					"max_count": 100,
					"metadata": null
				}]
			}
		}
	}

}
```



