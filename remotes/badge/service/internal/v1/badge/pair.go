package badge

import (
	"log"
	"net/http"
	"strings"
	// /	"crypto/ecdsa"

	"goji.io"
	"golang.org/x/net/context"

	"github.com/thedarknet/daemon4/daemon/remote"
	"github.com/thedarknet/daemon4/http-problem"
	"github.com/thedarknet/daemon4/remotes/badge/service/internal/data"
)

// Pair is called when a player pairs a badge with another
func Pair(db data.Database) goji.HandlerFunc {
	return func(ctx context.Context, w http.ResponseWriter, r *http.Request) {
		req, err := remote.Decode(r.Body)
		if err != nil {
			problem.Write(w, http.StatusBadRequest, "Invalid request body", "Request body does not parse", "ERROR_CLIENT", err)
			return
		}

		// Create response
		resp := &remote.Response{
			Success: true,
			Message: "Pair",
			Inc:     0,
		}

		// Do logic
		log.Printf("Req: %# v", req)
		result := strings.Split(req.Code, " ")
		if len(result) == 2 {

		}
		//this should contain an ID and a signature
		//look up privatekey of radio ID, generate public key
		//do 256 hash of ID and public key,
		//verify signature with my privateKey

		err = resp.Encode(w)
		if err != nil {
			problem.Write(w, http.StatusInternalServerError, "Cannot send response", "Cannot send response", "ERROR_SERVICE", err)
			return
		}
	}
}
