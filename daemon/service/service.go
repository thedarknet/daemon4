package service

import (
	"net/http"
	"os"

	"github.com/thedarknet/daemon4/daemon/service/internal/data"
	"github.com/thedarknet/daemon4/daemon/service/internal/v1/content"
	"github.com/thedarknet/daemon4/daemon/service/internal/v1/player"
	"github.com/thedarknet/daemon4/daemon/service/internal/v1/test"
	"goji.io"
	"goji.io/pat"
)

func ListenAndServe(dbConn string) error {

	db, err := data.NewServiceDB(dbConn)
	if err != nil {
		return err
	}

	enforceAuth := os.Getenv("DAEMON_ENFORCE_AUTH")
	hmacKey := os.Getenv("DAEMON_HMAC_KEY")

	mux := goji.NewMux()
	mux.HandleFuncC(pat.Get("/v1/content/echo"), content.Echo())
	mux.HandleFuncC(pat.Get("/v1/player/:id"), player.Play(db, enforceAuth != "false", hmacKey))
	mux.HandleFuncC(pat.Get("/v1/test/ping"), test.Ping(db))

	return http.ListenAndServe(":8080", mux)
}
