package service

import (
	"net/http"

	"github.com/thedarknet/daemon4/remotes/badge/service/internal/data"
	"github.com/thedarknet/daemon4/remotes/badge/service/internal/v1/badge"
	"github.com/thedarknet/daemon4/remotes/badge/service/internal/v1/test"
	"goji.io"
	"goji.io/pat"
)

func ListenAndServe(dbConn string) error {

	db, err := data.NewServiceDB(dbConn)
	if err != nil {
		return err
	}

	mux := goji.NewMux()
	mux.HandleFuncC(pat.Get("/v1/test/ping"), test.Ping(db))
	mux.HandleFuncC(pat.Post("/v1/badge/register"), badge.Register(db))
	mux.HandleFuncC(pat.Post("/v1/badge/pair"), badge.Pair(db))
	mux.HandleFuncC(pat.Post("/v1/badge/enigma"), badge.Enigma(db))
	return http.ListenAndServe(":8080", mux)
}
