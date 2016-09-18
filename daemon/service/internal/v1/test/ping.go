package test

import (
	"fmt"
	"net/http"

	"goji.io"
	"golang.org/x/net/context"

	"github.com/thedarknet/daemon4/daemon/service/internal/data"
	"github.com/thedarknet/daemon4/http-problem"
)

// Ping checks that the service and database are up
// An optional err parameter can be passed to intentionally generate errors
// err=db  will generate an exception from the database
// err=svc will generate an error inside the service handler
func Ping(db data.Database) goji.HandlerFunc {
	return func(ctx context.Context, w http.ResponseWriter, r *http.Request) {
		errorType := r.URL.Query().Get("err")

		// Throw an error from the service
		if errorType == "svc" {
			problem.Write(w, http.StatusInternalServerError, "Intentional Error", "Setting err=svc triggers this error message", "ERROR_SERVICE", nil)
			return
		}

		// Handle db check
		res, err := db.Ping(errorType == "db")
		if err != nil {
			if err.Code() == data.ErrorPing {
				problem.Write(w, http.StatusInternalServerError, "Intentional DB Error", "Setting err=db triggers this error message", "ERROR_SERVICE_DB", nil)
			} else {
				problem.Write(w, http.StatusServiceUnavailable, "Unexpected Database Error", "Database is unavailable", "ERROR_DB_DOWN", err)
			}
			return
		}

		// everything is fine
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"Pong": %d}`, res)
	}
}
