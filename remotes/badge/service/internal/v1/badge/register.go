package badge

import (
	"log"
	"net/http"

	"goji.io"
	"golang.org/x/net/context"

	"github.com/thedarknet/daemon4/daemon/remote"
	"github.com/thedarknet/daemon4/http-problem"
	"github.com/thedarknet/daemon4/remotes/badge/service/internal/data"
)

// Register is called when a player is attempting to register a brand new badge
func Register(db data.Database) goji.HandlerFunc {
	return func(ctx context.Context, w http.ResponseWriter, r *http.Request) {
		req, err := remote.Decode(r.Body)
		if err != nil {
			problem.Write(w, http.StatusBadRequest, "Invalid request body", "Request body does not parse", "ERROR_CLIENT", err)
			return
		}

		// Do logic
		log.Printf("Req: %# v", req)
		res, err := db.Register(req.Code, req.AccountID, req.DisplayName)
		if err != nil {
			problem.Write(w, http.StatusInternalServerError, "DB Error on Register", "Db Error on Register", "ERROR_SERVICE", err)
			return
		}

		// Create response
		resp := &remote.Response{
			Success: res == 1,
			Message: "Register Fail",
			Inc:     1,
		}

		if res == 1 {
			resp.Message = "Register successful"
		}

		err = resp.Encode(w)
		if err != nil {
			problem.Write(w, http.StatusInternalServerError, "Cannot send response", "Cannot send response", "ERROR_SERVICE", err)
			return
		}
	}
}
