package badge

import (
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"strings"

	"goji.io"
	"golang.org/x/net/context"

	"github.com/thedarknet/daemon4/daemon/remote"
	"github.com/thedarknet/daemon4/http-problem"
	"github.com/thedarknet/daemon4/remotes/badge/service/internal/data"
)

// Enigma returns the handler that validates the crypto challenges
func Enigma(db data.Database) goji.HandlerFunc {
	return func(ctx context.Context, w http.ResponseWriter, r *http.Request) {
		req, err := remote.Decode(r.Body)
		if err != nil {
			problem.Write(w, http.StatusBadRequest, "Invalid request body", "Request body does not parse", "ERROR_CLIENT", err)
			return
		}

		key := []byte(r.URL.Query().Get("key"))
		badge, err := db.GetBadgeDataByAccountID(req.AccountID)
		if err != nil {
			problem.Write(w, http.StatusInternalServerError, "Cannot load badge", "Cannot load badge data", "ERROR_SERVICE", err)
			return
		}

		resp := &remote.Response{
			Success: true,
		}

		if badge == nil {
			resp.Message = "Your account does not have a badge registered"
		} else {
			// Check that the hash is valid
			h := sha256.New()
			h.Write(badge.PrivateKey)
			h.Write(key)

			answer := hex.EncodeToString(h.Sum(nil))
			if strings.HasPrefix(answer, req.Code) {
				resp.Message = "Problem solved"
				resp.Inc = 1
			} else {
				resp.Message = "Incorrect solution"
			}
		}

		err = resp.Encode(w)
		if err != nil {
			problem.Write(w, http.StatusInternalServerError, "Cannot send response", "Cannot send response", "ERROR_SERVICE", err)
			return
		}
	}
}
