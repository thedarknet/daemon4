package content

import (
	"fmt"
	"log"
	"net/http"

	"goji.io"
	"golang.org/x/net/context"
)

func Echo() goji.HandlerFunc {
	return func(ctx context.Context, w http.ResponseWriter, r *http.Request) {
		data := r.URL.Query()["data"]
		fmt.Fprintf(w, "ECHO: %s", data)
		log.Printf("Received content data: %s\n", data)
	}
}
