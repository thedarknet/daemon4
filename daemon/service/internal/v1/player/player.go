package player

import (
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/websocket"
	"goji.io"
	"goji.io/pat"
	"golang.org/x/net/context"

	"github.com/thedarknet/daemon4/daemon/service/internal/data"
	"github.com/thedarknet/daemon4/daemon/service/internal/msg"
	"github.com/thedarknet/daemon4/daemon/service/internal/player"
	"github.com/thedarknet/daemon4/http-problem"
)

func Play(db data.Database, enforceAuth bool, hmacKey string) goji.HandlerFunc {
	upgrader := websocket.Upgrader{CheckOrigin: func(r *http.Request) bool { return true }}
	log.Printf("Auth enforcement: %t", enforceAuth)

	return func(ctx context.Context, w http.ResponseWriter, r *http.Request) {
		playerID := pat.Param(ctx, "id")
		pid, err := strconv.ParseInt(playerID, 10, 64)
		if err != nil {
			log.Printf("Invalid player id %s (%v)", playerID, err)
			problem.Write(w, http.StatusBadRequest, "Invalid account id", "Account id must be a number", "ERROR_CLIENT", nil)
			return
		}

		authToken := r.URL.Query().Get("auth_token")
		if err := validateAuthToken(authToken, pid, hmacKey); err != nil {
			log.Printf("Invalid auth token for %d (%v)", pid, err)
			if enforceAuth {
				problem.Write(w, http.StatusForbidden, "Forbidden", "Forbidden", "ERROR_CLIENT", nil)
				return
			}
		}

		c, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Println("Unable to upgrade connection ", err)
			return
		}
		defer c.Close()

		err = msg.Process(player.New(db, pid), c, make(chan bool))
		if err != nil {
			log.Printf("Error processing %s (%v)", playerID, err)
		}
	}
}
